local ADDON, ns = ...

local Sets = ns.Sets

-- Character/Worn.lua: what is on you, and the one call that changes it.
local Worn = ns.Worn

--------------------------------------------------------------------------
-- Putting a set on: a plan, then a queue
--
-- Separating the two is the engineering argument for the whole feature, and it
-- is worth stating once here because nothing in the code says it.
--
-- **The plan runs in one frame and calls nothing that changes anything.** It
-- marks every slot whose worn piece already matches and reserves that piece, so
-- a set you are already wearing costs zero moves. It then finds an unreserved
-- source for each remaining slot, in the bags or in another worn slot. Then it
-- orders the moves. It is handed the world rather than asking the client for
-- it, which is the half that makes it testable: a plan that read the world as
-- it went would be a plan whose answer depended on when each line ran, and
-- there would be no way to drive two rings trading places without a client.
--
-- **The queue then runs the plan one move per event.** Every move is a server
-- round trip and a second pickup while the first is in flight fails silently,
-- so the run is one cursor operation per ITEM_LOCK_CHANGED or BAG_UPDATE, and
-- before each one it reads the source again.
--
-- **Equipping goes through the cursor.** PickupContainerItem then
-- PickupInventoryItem, which is what Worn.Swap does and what Core/Sockets.lua
-- does in the same order. EquipItemByName is the wrong call and Worn.lua's
-- header says why at length: the cursor pair is what FrameXML's own paperdoll
-- button makes, so it is the call the client is written to accept.
--
-- **Nothing here is protected and nothing here needs a secure button.** A set
-- is items, a swap is item moves, and item moves are plain Lua. That is the
-- whole difference between this and the weapon loadouts that came out at
-- e497197, which spent three files and ten secure buttons on a stance in macro
-- text.
--------------------------------------------------------------------------

local MAINHAND = 16
local OFFHAND = 17
local LAST_BAG = 4 -- the backpack is 0, and neither client has a reagent bag

--------------------------------------------------------------------------
-- The world the plan is handed
--------------------------------------------------------------------------

-- Only a bag that takes anything is counted as room. A quiver, an ammo pouch,
-- a soul bag and a herb bag all have free slots and none of them will take the
-- helmet the plan is about to displace, so counting them is how a plan says it
-- has room and then stalls with a piece on the cursor.
local function Roomy(bag)
	return ns.BagFamily(bag) == 0
end

function Sets.World()
	local world = { worn = {}, bags = {}, free = 0 }
	local slots = Sets.Slots()
	for index = 1, #slots do
		world.worn[slots[index]] = Worn.Link(slots[index])
	end
	for bag = 0, LAST_BAG do
		local roomy = Roomy(bag)
		for index = 1, ns.ContainerSlots(bag) do
			local link = ns.ContainerItemLink(bag, index)
			if link then
				world.bags[#world.bags + 1] = { bag = bag, index = index, link = link }
			elseif roomy then
				world.free = world.free + 1
			end
		end
	end
	return world
end

--------------------------------------------------------------------------
-- The plan
--------------------------------------------------------------------------

-- Pass one: the slots that are already right.
--
-- `done` is the reservation, and it means both halves of being right: the slot
-- needs no move, and the piece in it may not be taken to fill another slot.
-- That second half is the mistake a naive per slot loop makes with a pair of
-- identical rings: it matches one finger, then sees the same key on the other
-- finger and moves the ring it has just finished matching.
local function Standing(record, world, done)
	local already, slots = 0, Sets.Slots()
	for index = 1, #slots do
		local slot = slots[index]
		local entry = record.slots[slot]
		local link = world.worn[slot]
		if entry == false then
			if not link then
				already = already + 1
			end
		elseif entry and link and Sets.Key(link) == entry.key then
			done[slot] = true
			already = already + 1
		end
	end
	return already
end

local function FromBags(world, key, used)
	for index = 1, #world.bags do
		local one = world.bags[index]
		if not used[index] and Sets.Key(one.link) == key then
			used[index] = true
			return { bag = one.bag, index = one.index, key = key }
		end
	end
	return nil
end

-- A worn slot whose piece is wanted somewhere else.
--
-- Two reservations and they are not the same one. `done` is a slot that is
-- already right, and its piece is not available at any price. `spoken` is a
-- slot whose piece has been promised to some other slot, and that one says
-- nothing about whether this slot may be filled in its turn: a slot handing its
-- ring away and taking another one back is exactly what two fingers trading
-- places is, and one flag for both is what made that come out as a move and a
-- half rather than as a swap.
local function FromWorn(world, key, done, spoken, want)
	local slots = Sets.Slots()
	for index = 1, #slots do
		local slot = slots[index]
		if slot ~= want and not done[slot] and not spoken[slot]
			and Sets.Key(world.worn[slot]) == key then
			spoken[slot] = true
			return { slot = slot, key = key }
		end
	end
	return nil
end

-- Pass two: where the piece for each remaining slot is coming from.
--
-- The bags first and the other worn slots second. A bag source disturbs nothing
-- else and costs two cursor operations, where a worn source is the one that
-- makes a chain; and where both exist they are the same item, so the cheaper
-- one is the right one. The pair of rings trading places is the case with no
-- bag source at all, which is what the second half is for.
local function Sourced(record, world, done, from, missing)
	local used, spoken, slots = {}, {}, Sets.Slots()
	for index = 1, #slots do
		local slot = slots[index]
		local entry = record.slots[slot]
		if entry and not done[slot] then
			local source = FromBags(world, entry.key, used)
				or FromWorn(world, entry.key, done, spoken, slot)
			if source then
				from[slot] = source
			else
				missing[#missing + 1] = entry.link or entry.key
			end
		end
	end
end

--------------------------------------------------------------------------
-- The moves
--
-- Four cursor operations and no more, because that is all the client gives
-- you: pick up out of a bag, pick up out of a worn slot, put what is on the
-- cursor into a worn slot, and let go.
--
--   grab   the item in a bag slot onto the cursor
--   lift   the item in a worn slot onto the cursor
--   drop   what is on the cursor into a worn slot, and whatever was in that
--          slot comes back onto the cursor
--   stow   let go, and the client puts what is on the cursor in your bags
--
-- The hand-back on a drop is not an extra operation, and it is the whole reason
-- two rings trade places in three of these rather than in four with a bag slot
-- in the middle: lift 11, drop into 12 which hands back the other ring, drop
-- that into 11.
--
-- Operations are grouped into gestures, one per grab or lift, because that is
-- the unit the queue can abandon. Skipping a grab on its own would leave the
-- drop after it to run with an empty cursor, which is not a move that does
-- nothing: it is a pickup, and it would take the piece out of the slot the set
-- was trying to fill.
--------------------------------------------------------------------------

local function Op(plan, op)
	if op.op == "grab" or op.op == "lift" then
		plan.gestures = plan.gestures + 1
	end
	op.gesture = plan.gestures
	plan.ops[#plan.ops + 1] = op
	return op
end

-- Pass three, first: the slots the set says are to be bare.
local function Strip(record, world, plan)
	local slots = Sets.Slots()
	for index = 1, #slots do
		local slot = slots[index]
		if record.slots[slot] == false and world.worn[slot] then
			Op(plan, { op = "lift", slot = slot, key = Sets.Key(world.worn[slot]) })
			Op(plan, { op = "stow" })
		end
	end
end

-- A two hander takes the off hand off with it, and the client is what does it:
-- the shield lands in your bags whether or not the set said anything about slot
-- 17. So the pair is planned rather than left to happen, because a plan that
-- did not count it is a plan that says it needs no room and then stalls on a
-- full bag with the weapon half swapped.
--
-- Not when the set has an opinion about the off hand, and not when the off hand
-- is a source. In the first case the slot is already being emptied above or
-- filled below; in the second the chain empties it. Taking it off again is one
-- wasted round trip and one bag slot the plan did not have.
local function Displaced(record, world, from, plan)
	local wanted = from[MAINHAND] and record.slots[MAINHAND]
	if not wanted or record.slots[OFFHAND] ~= nil or not world.worn[OFFHAND] then
		return
	end
	for _, source in pairs(from) do
		if source.slot == OFFHAND then
			return
		end
	end
	local _, _, equip = ns.ItemInfo(wanted.link)
	if equip ~= "INVTYPE_2HWEAPON" then
		return
	end
	Op(plan, { op = "lift", slot = OFFHAND, key = Sets.Key(world.worn[OFFHAND]) })
	Op(plan, { op = "stow" })
end

-- One chain of worn slots handing pieces along, from the slot it starts at.
--
-- The cursor is loaded once at the head and put down once per link, and it
-- comes back empty at the end of a cycle because the slot the last piece goes
-- into is the one the first piece was lifted out of. An open chain ends on a
-- slot holding something nobody asked for, and that is the one stow in here.
local function Walk(world, goesTo, moved, plan, head)
	Op(plan, { op = "lift", slot = head, key = Sets.Key(world.worn[head]) })
	moved[head] = true

	local at = goesTo[head]
	while at do
		Op(plan, { op = "drop", slot = at })
		if moved[at] or not world.worn[at] then
			-- Nothing came back onto the cursor: the slot was empty, or what
			-- was in it left earlier in this same chain.
			at = nil
		else
			moved[at] = true
			at = goesTo[at]
			if not at then
				Op(plan, { op = "stow" })
			end
		end
	end
end

-- Pass three, second: every worn-to-worn move, ordered so nothing is put down
-- before the slot it came from is free.
--
-- Chains are started at a head, which is a slot nothing else moves into.
-- What is left after the heads have been walked is a cycle: it has no head, it
-- may be started anywhere, and the pair of rings is the cycle this is written
-- for.
local function Chains(world, goesTo, filled, plan)
	local moved, slots = {}, Sets.Slots()
	for index = 1, #slots do
		local slot = slots[index]
		if goesTo[slot] and not filled[slot] then
			Walk(world, goesTo, moved, plan, slot)
		end
	end
	for index = 1, #slots do
		local slot = slots[index]
		if goesTo[slot] and not moved[slot] then
			Walk(world, goesTo, moved, plan, slot)
		end
	end
end

-- Pass three, third: everything coming out of a bag.
--
-- After the chains, so a slot a chain emptied takes its new piece with nothing
-- to hand back. The stow is the piece the drop displaces, and it is skipped
-- exactly when the slot is one a chain has already emptied.
local function Carried(world, from, goesTo, plan)
	local slots = Sets.Slots()
	for index = 1, #slots do
		local slot = slots[index]
		local source = from[slot]
		if source and source.bag then
			Op(plan, { op = "grab", bag = source.bag, index = source.index, key = source.key })
			Op(plan, { op = "drop", slot = slot })
			if world.worn[slot] and not goesTo[slot] then
				Op(plan, { op = "stow" })
			end
		end
	end
end

-- How many free bag slots the run needs at its tightest moment.
--
-- A grab frees one and a stow spends one, so the number to check is not the
-- total but the deepest the running balance goes. Two rings trading places
-- never dips below nought, because there is no grab and no stow in it, and that
-- is the sentence the whole shape of this exists to be able to say.
local function Room(ops)
	local balance, lowest = 0, 0
	for index = 1, #ops do
		local op = ops[index].op
		if op == "grab" then
			balance = balance + 1
		elseif op == "stow" then
			balance = balance - 1
		end
		if balance < lowest then
			lowest = balance
		end
	end
	return -lowest
end

-- How many worn slots the run changes, counted as slots rather than as moves. A
-- slot lifted out of and dropped back into during one chain is one change, and
-- the sentence the player reads is about their gear rather than about the
-- cursor.
local function Touched(ops)
	local seen, count = {}, 0
	for index = 1, #ops do
		local slot = ops[index].slot
		if slot and not seen[slot] then
			seen[slot] = true
			count = count + 1
		end
	end
	return count
end

-- How many of the nineteen the set has an opinion about, counting a deliberate
-- hole as an opinion.
--
-- The one number that tells a set with nothing in it from a set you are already
-- wearing. Both plan nought moves and both would report nought changed and
-- nought already on, and only one of the two is a mistake the player can do
-- something about.
local function Named(record)
	local named, slots = 0, Sets.Slots()
	for index = 1, #slots do
		if record.slots[slots[index]] ~= nil then
			named = named + 1
		end
	end
	return named
end

-- Everything a run would do, and nil for a name nobody saved.
function Sets.Plan(name, world)
	local record = Sets.Get(name)
	if not record then
		return nil, ("there is no set called %q."):format(tostring(name))
	end
	world = world or Sets.World()

	local plan = { name = record.name, ops = {}, gestures = 0, missing = {},
		named = Named(record) }
	local done, from = {}, {}
	plan.already = Standing(record, world, done)
	Sourced(record, world, done, from, plan.missing)

	local goesTo, filled = {}, {}
	for slot, source in pairs(from) do
		if source.slot then
			goesTo[source.slot] = slot
			filled[slot] = source.slot
		end
	end

	Strip(record, world, plan)
	Displaced(record, world, from, plan)
	Chains(world, goesTo, filled, plan)
	Carried(world, from, goesTo, plan)

	plan.room = Room(plan.ops)
	plan.changed = Touched(plan.ops)
	plan.short = plan.room > world.free
	return plan
end

--------------------------------------------------------------------------
-- The queue
--
-- One operation per event, and never two in flight. Every one is a round trip
-- to the server, and a second pickup while the first is still moving fails
-- without saying anything: the call returns, nothing lands, and the only
-- symptom is a set that went on half way.
--
-- Before every gesture the source is read again. The plan was made a few
-- hundred milliseconds ago and the world is allowed to have moved: a bag sort,
-- a piece looted into the slot the plan named, another addon doing its own
-- housekeeping. A source that no longer holds the wanted key has its whole
-- gesture abandoned, which is the difference between a set that comes out short
-- and one that puts a random green in your hand.
--
-- There is no ticker on this and that is deliberate. ns.UI.Ticker puts
-- everything it reaches on the hot path, and the whole of this queue would go
-- with it for the sake of a deadline that fires once a session. The deadline is
-- read at each event instead, which works because the events that drive the run
-- are the events that expire it: a run whose last move the server never
-- answered is left until the next bag event picks it up and says what it could
-- not fill.
--------------------------------------------------------------------------

-- Long enough for a full nineteen slot swap on a bad connection, short enough
-- that a run nobody is watching does not outlive the pull it was started
-- before.
local DEADLINE = 15

local running = nil

local function Ask(name, ...)
	local call = _G[name]
	if type(call) ~= "function" then
		return nil
	end
	local ok, answer = pcall(call, ...)
	return ok and answer or nil
end

local events = CreateFrame("Frame")

-- What the run could not do, in one line. The slots are named rather than
-- numbered, because a player reading "13 and 14" has to count trinkets.
local function Report(run)
	local plan = run.plan
	local line = ("put on %s: %d changed, %d already on")
		:format(plan.name, plan.changed, plan.already)
	if #plan.missing > 0 then
		line = ("%s, %d not in your bags (%s)")
			:format(line, #plan.missing, table.concat(plan.missing, ", "))
	end
	if #run.skipped > 0 then
		line = ("%s, %d left alone because it moved while this ran (%s)")
			:format(line, #run.skipped, table.concat(run.skipped, ", "))
	end
	ns.Print(line .. ".")
end

-- The cursor is cleared on every ending, which Core/Sockets.lua already argues
-- for: a piece left hanging on the cursor is a click the player has to make
-- before they can do anything else, and they were not told it was there.
local function Stop()
	if not running then
		return
	end
	local run = running
	running = nil
	events:UnregisterAllEvents()
	Ask("ClearCursor")
	Report(run)
end

-- Whether the source this gesture was planned against still holds what it held.
-- A drop and a stow carry no source: what they act on is the cursor, and the
-- gesture they belong to has already been checked.
local function Fresh(op)
	if op.op == "grab" then
		return Sets.Key(ns.ContainerItemLink(op.bag, op.index)) == op.key
	end
	if op.op == "lift" then
		return Sets.Key(Worn.Link(op.slot)) == op.key
	end
	return true
end

local function Run(op)
	if op.op == "grab" then
		return ns.PickupContainerItem(op.bag, op.index)
	end
	if op.op == "stow" then
		Ask("ClearCursor")
		return true
	end
	-- A lift and a drop are one client call. PickupInventoryItem puts whatever
	-- is on the cursor into the slot and picks up what was there, so which of
	-- the two it is depends on the cursor rather than on the call, and Worn.Swap
	-- is the one door the addon has onto it.
	return (Worn.Swap(op.slot))
end

local function Skip(run, op)
	local ops = run.plan.ops
	run.skipped[#run.skipped + 1] = op.slot and Sets.Label(op.slot) or "a bag slot"
	while ops[run.at] and ops[run.at].gesture == op.gesture do
		run.at = run.at + 1
	end
end

local function Step()
	if not running then
		return
	end
	local run = running
	local op = run.plan.ops[run.at]
	if not op or GetTime() > run.deadline then
		Stop()
		return
	end

	run.at = run.at + 1
	if not Fresh(op) then
		Skip(run, op)
		return
	end
	if not Run(op) then
		Stop()
	end
end

events:SetScript("OnEvent", Step)

--------------------------------------------------------------------------

-- The three slots a fight allows, said out loud rather than left to the server.
-- Worn.Free holds the rule per slot; a weapon swap mid pull is a thing the game
-- is happy about and everything else is refused silently, which is the worst
-- version of a word you typed.
--
-- Waiting for PLAYER_REGEN_ENABLED is phase 4's and it is deliberately not here.
-- A queue that fired thirty seconds after the word was typed is a queue that
-- puts your tanking set on in the middle of the next pull.
local function Allowed(plan)
	for index = 1, #plan.ops do
		local slot = plan.ops[index].slot
		if slot then
			local free, why = Worn.Free(slot)
			if not free then
				return false, ("%s The main hand, the off hand and the bow are all a fight allows.")
					:format(why)
			end
		end
	end
	return true
end

function Sets.Wear(name)
	local plan, why = Sets.Plan(name)
	if not plan then
		return false, why
	end
	if running then
		return false, ("%s is still going on."):format(running.plan.name)
	end
	-- A set that names nothing at all, refused here rather than reported at the
	-- end. Report below would say "0 changed, 0 already on", which is true and
	-- is the same sentence a set you are already wearing gets: the run did
	-- nothing, and the line does not say whether that is because there was
	-- nothing to do or because there is nothing in the set. So the refusal is
	-- what the player reads, and it names the gesture that fills one.
	if plan.named == 0 then
		return false, ("%s has nothing in it. right click its toggle on the character page to save what you have on into it, or click a circle to put one slot in.")
			:format(plan.name)
	end

	local allowed, refused = Allowed(plan)
	if not allowed then
		return false, refused
	end
	if plan.short then
		return false, ("%s needs %d free bag slot%s to swap into.")
			:format(plan.name, plan.room, plan.room == 1 and "" or "s")
	end

	if #plan.ops == 0 then
		Report({ plan = plan, skipped = {} })
		return true
	end

	running = { plan = plan, at = 1, skipped = {}, deadline = GetTime() + DEADLINE }
	events:RegisterEvent("ITEM_LOCK_CHANGED")
	events:RegisterEvent("BAG_UPDATE")
	Step()
	return true
end

function Sets.Running()
	return running and running.plan.name or nil
end

--------------------------------------------------------------------------
-- The swap
--
-- Talents first, then the set that follows them, and the order is not
-- negotiable. The talent switch is a cast that takes a few seconds and the gear
-- queue is a server round trip per item; running them together is how a set
-- lands half on, with the pieces that answered before the cast finished and
-- none of the ones after it. So the gear waits for the client to say the group
-- actually changed, which is ACTIVE_TALENT_GROUP_CHANGED and not the call
-- returning.
--------------------------------------------------------------------------

local waiting = nil

local swapper = CreateFrame("Frame")
swapper:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

local function Landed()
	local name = waiting
	waiting = nil
	if name then
		local done, why = Sets.Wear(name)
		if not done then
			ns.Print(why)
		end
	end
end

swapper:SetScript("OnEvent", Landed)

local function Following(group)
	for _, record in ipairs(Sets.All()) do
		if record.group == group then
			return record
		end
	end
	return nil
end

function Sets.Swap(group)
	if type(group) ~= "number" then
		return false, "a swap needs a talent group."
	end
	local set = Following(group)
	if not set then
		return false, ("no set follows talent group %d."):format(group)
	end
	-- Already in that group, so there are no talents to wait for and the gear
	-- is the whole of the swap. Worth having rather than refusing: the word is
	-- what a key will press in phase 4, and a key that does nothing when you
	-- are already in the spec is a key people stop trusting.
	if group == Sets.Group() then
		return Sets.Wear(set.name)
	end
	if type(ns.SetActiveSpecGroup) ~= "function" then
		return false, "this client has one talent group."
	end

	waiting = set.name
	ns.SetActiveSpecGroup(group)
	return true
end
