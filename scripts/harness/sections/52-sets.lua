-- Gear sets: the plan, and nothing that draws
--
-- What is under test is Sets/Wear.lua's planner, which is the one part of this
-- feature that can be wrong in a way nobody sees until a raid night. It is
-- asserted here rather than in the game because it was written to be: the plan
-- calls nothing that changes anything and is handed the world as an argument,
-- so every scene below is a table rather than a client with gear in it.
--
-- That is worth spelling out because it is the whole reason this section can
-- exist. A planner that read the bags as it went would need a stub that could
-- hold two rings on two fingers, a two hander in a bag, a full bag and an empty
-- one, and it would be asserting the stub as much as the addon. Here the scene
-- is four lines and the assertion is the operation list.
--
-- **The five cases are the five ways it goes wrong, not five examples.**
--
-- A set you are already wearing costs zero moves. A per slot loop that equipped
-- everything unconditionally passes every other test in this file and spends
-- nineteen server round trips on a swap you did not need.
--
-- Two rings trading places needs three cursor operations and no free bag slot.
-- This is the case a naive loop fights itself on: it takes the ring off one
-- finger, puts it in the bags, takes the other off, and needs room it may not
-- have. The client hands the displaced piece straight back onto the cursor, so
-- there is a path through it that touches no bag at all, and the assertion is
-- that the planner takes it.
--
-- A two hander takes the off hand off with it. The client does that whether or
-- not the set has an opinion about slot 17, so a plan that did not count it is
-- a plan that says it needs no room and then stalls with a weapon on the cursor
-- and a shield nowhere to go.
--
-- A piece that is nowhere reachable leaves its slot alone and is named. The
-- failure it guards is silence: a set that came out four pieces short and said
-- nothing.
--
-- Unset and deliberately empty are different states. They are one state in
-- every naive model of this, and the difference is whether a resist set that
-- names five pieces takes your rings off.
--
-- **A fight takes operations out of the plan rather than refusing the run.**
-- Slots 16, 17 and 18 are the three the client allows mid pull, so a set
-- pressed in a fight puts the weapons on and leaves the armour where it is. It
-- is asserted on the plan and not on the run, because Room and Touched are both
-- counted off plan.ops: a plan still carrying the armour would ask for the bag
-- room to stow armour it was never going to lift.
--
-- **The queue is driven, at the foot, against the client.** It was not for a
-- while, and that is how a run which did nothing at all shipped green: the plan
-- is a table and the queue is four cursor operations, and where the pieces end
-- up is the whole of what the queue is answerable for. The last block stands a
-- character up in real gear and presses a set at them.
--
-- Every fixture this section adds is taken out again at the foot. The item
-- lookup in client/04-hands.lua walks ITEMS by id and refuses two fixtures
-- carrying one number, so a scene left standing here is a crash in whichever
-- section next writes an id.

local H = ...
local ns, check = H.ns, H.check
local ITEMS, itemLink, worn = H.ITEMS, H.itemLink, H.worn

local Sets = ns.Sets

-- Seven pieces, chosen so that every branch of the planner has something to
-- work with: a pair of rings that are not each other, a two hander and the one
-- hander and shield it displaces, a cloak to take off, and a trinket that is
-- deliberately never put anywhere so it can be the piece nobody is carrying.
local FIXTURES = {
	["Band of the Left"]   = { id = 9301, equip = "INVTYPE_FINGER" },
	["Band of the Right"]  = { id = 9302, equip = "INVTYPE_FINGER" },
	["Gorehowl"]           = { id = 9303, equip = "INVTYPE_2HWEAPON" },
	["Quel'Serrar"]        = { id = 9304, equip = "INVTYPE_WEAPON" },
	["Aegis of the Sun"]   = { id = 9305, equip = "INVTYPE_SHIELD" },
	["Shroud of Dominion"] = { id = 9306, equip = "INVTYPE_CLOAK" },
	["Dragonspine Trophy"] = { id = 9307, equip = "INVTYPE_TRINKET" },
}

for name, item in pairs(FIXTURES) do
	ITEMS[name] = { id = item.id, classId = 4, equip = item.equip, quality = 4,
		icon = "Interface\\Icons\\Gear", price = 100 }
end

-- A scene: what is on, what is in the backpack, and how much room is left in
-- it. The bag is bag zero and the slot numbers do not matter to the planner,
-- which reads the list rather than the geography.
local function scene(on, carried, free)
	local world = { worn = {}, bags = {}, free = free or 0 }
	for slot, name in pairs(on) do
		world.worn[slot] = itemLink(name)
	end
	for index, name in ipairs(carried or {}) do
		world.bags[index] = { bag = 0, index = index, link = itemLink(name) }
	end
	return world
end

-- A set built through the public writers rather than written into the saved
-- variables, so Put's own refusal is exercised on the way in: a fixture that
-- did not fit the slot it is being put in would fail here rather than quietly
-- planning nothing.
local function saved(name, entries)
	Sets.Remove(name)
	check(Sets.New(name) ~= nil, ("%s could not be made"):format(name))
	for slot, what in pairs(entries) do
		if what == false then
			Sets.Empty(name, slot)
		else
			local done, why = Sets.Put(name, slot, itemLink(what))
			check(done, ("%s would not go in slot %d: %s"):format(what, slot, tostring(why)))
		end
	end
	return name
end

-- The operations in one line, which is what a failed assertion has to print:
-- "lift 17, stow, grab, drop 16, stow" says what went wrong and a count does
-- not.
local function reads(plan)
	local out = {}
	for index = 1, #plan.ops do
		local op = plan.ops[index]
		out[index] = op.slot and ("%s %d"):format(op.op, op.slot) or op.op
	end
	return table.concat(out, ", ")
end

----------------------------------------------------------------------
-- How an item is written down
--
-- Everything below rests on two links of the same piece keying alike, so it is
-- measured before anything is planned. The uniqueId is the field that moves as
-- an item moves, and a set keyed on it stops matching itself the first time you
-- take the piece off.
----------------------------------------------------------------------

do
	local id = ITEMS["Band of the Left"].id
	local plain = ("|cffffffff|Hitem:%d:0:0:0:0:0:0:0:70:0|h[%s]|h|r")
		:format(id, "Band of the Left")
	local moved = ("|cffffffff|Hitem:%d:0:0:0:0:0:0:114514:70:0|h[%s]|h|r")
		:format(id, "Band of the Left")
	local blank = ("|cffffffff|Hitem:%d:::::::|h[%s]|h|r"):format(id, "Band of the Left")
	local enchanted = ("|cffffffff|Hitem:%d:2588:0:0:0:0:0:0:70:0|h[%s]|h|r")
		:format(id, "Band of the Left")

	check(Sets.Key(plain) == Sets.Key(moved),
		("the same ring keyed %s in a bag and %s on a finger")
			:format(tostring(Sets.Key(plain)), tostring(Sets.Key(moved))))
	check(Sets.Key(plain) == Sets.Key(blank),
		("a link written with blanks keyed %s against %s written with noughts")
			:format(tostring(Sets.Key(blank)), tostring(Sets.Key(plain))))
	check(Sets.Key(plain) ~= Sets.Key(enchanted),
		"an enchanted ring and a bare one key the same, so a set cannot tell them apart")
	check(Sets.Key("not an item") == nil, "something that is not an item was given a key")
end

----------------------------------------------------------------------
-- A set you are already wearing costs zero moves
----------------------------------------------------------------------

do
	local name = saved("raid", {
		[11] = "Band of the Left",
		[12] = "Band of the Right",
		[15] = "Shroud of Dominion",
	})
	local plan = Sets.Plan(name, scene({
		[11] = "Band of the Left",
		[12] = "Band of the Right",
		[15] = "Shroud of Dominion",
	}, {}, 4))

	check(#plan.ops == 0, ("a set already on planned %q"):format(reads(plan)))
	check(plan.already == 3, ("%d of three slots read as already on"):format(plan.already))
	check(plan.changed == 0, ("%d slots would change on a set already on"):format(plan.changed))
	check(#plan.missing == 0, "a set already on named something it could not reach")
	check(plan.room == 0, ("a set already on asked for %d bag slots"):format(plan.room))
end

----------------------------------------------------------------------
-- Two rings trading places, with the bags full
--
-- Three cursor operations and no bag slot. Lift the ring off the first finger,
-- drop it on the second, which hands the other ring back onto the cursor, and
-- drop that on the first.
----------------------------------------------------------------------

do
	local name = saved("swapped", {
		[11] = "Band of the Left",
		[12] = "Band of the Right",
	})
	local plan = Sets.Plan(name, scene({
		[11] = "Band of the Right",
		[12] = "Band of the Left",
	}, {}, 0))

	check(reads(plan) == "lift 11, drop 12, drop 11",
		("two rings trading places planned %q"):format(reads(plan)))
	check(plan.room == 0,
		("the ring swap asked for %d bag slots and there is a path through it that needs none")
			:format(plan.room))
	check(not plan.short, "the ring swap was refused for want of bag room it does not need")
	check(plan.already == 0, ("%d rings read as already on"):format(plan.already))
	check(plan.changed == 2, ("%d slots would change and two fingers are involved"):format(plan.changed))
end

----------------------------------------------------------------------
-- A two hander replacing a main hand and an off hand
--
-- The set says nothing at all about slot 17, and the shield still has to come
-- off, because the client is what takes it off and it needs somewhere to put
-- it. Planned rather than left to happen, so the room it costs is counted.
----------------------------------------------------------------------

do
	local name = saved("cleave", { [16] = "Gorehowl" })
	local world = scene({
		[16] = "Quel'Serrar",
		[17] = "Aegis of the Sun",
	}, { "Gorehowl" }, 1)
	local plan = Sets.Plan(name, world)

	check(reads(plan) == "lift 17, stow, grab, drop 16, stow",
		("the two hander planned %q"):format(reads(plan)))
	check(plan.room == 1,
		("the two hander asked for %d bag slots: the shield needs one, and the one hander it displaces goes in the slot the weapon came out of")
			:format(plan.room))
	check(not plan.short, "the two hander was refused with exactly the room it needs")
	check(Sets.Entry(name, 17) == "unset",
		("the set's off hand reads %q and it was never written"):format(Sets.Entry(name, 17)))

	-- And with the bags full it says so rather than starting and stalling with
	-- a shield on the cursor.
	local tight = Sets.Plan(name, scene({
		[16] = "Quel'Serrar",
		[17] = "Aegis of the Sun",
	}, { "Gorehowl" }, 0))
	check(tight.short, "a two hander swap into full bags said it had room")
end

----------------------------------------------------------------------
-- A piece that is not in your bags
----------------------------------------------------------------------

do
	local name = saved("trinkets", {
		[13] = "Dragonspine Trophy",
		[15] = "Shroud of Dominion",
	})
	local plan = Sets.Plan(name, scene({}, { "Shroud of Dominion" }, 4))

	check(#plan.missing == 1,
		("%d pieces were named as out of reach and one of the two is in the bank")
			:format(#plan.missing))
	check(tostring(plan.missing[1]):find("Dragonspine Trophy", 1, true) ~= nil,
		("the piece it could not reach was named %q"):format(tostring(plan.missing[1])))
	check(reads(plan) == "grab, drop 15",
		("the reachable half of that set planned %q"):format(reads(plan)))
end

----------------------------------------------------------------------
-- Unset against deliberately empty
--
-- The same world twice, and the same slot. The set that says the cloak comes
-- off takes it off; the set that says nothing about the cloak leaves it alone.
-- These are one state in every naive model of a set, and the difference is
-- whether a resist set that names five pieces strips your rings.
----------------------------------------------------------------------

do
	local world = scene({ [15] = "Shroud of Dominion" }, {}, 2)

	local bare = saved("bare", { [15] = false })
	check(Sets.Entry(bare, 15) == "empty",
		("a slot saved as deliberately empty reads %q"):format(Sets.Entry(bare, 15)))
	local off = Sets.Plan(bare, world)
	check(reads(off) == "lift 15, stow",
		("a set that says the cloak comes off planned %q"):format(reads(off)))
	check(off.room == 1, ("taking the cloak off asked for %d bag slots"):format(off.room))

	local quiet = saved("quiet", { [11] = "Band of the Left" })
	check(Sets.Entry(quiet, 15) == "unset",
		("a slot nobody wrote reads %q"):format(Sets.Entry(quiet, 15)))
	local left = Sets.Plan(quiet, scene({
		[11] = "Band of the Left",
		[15] = "Shroud of Dominion",
	}, {}, 2))
	check(#left.ops == 0,
		("a set with nothing to say about the cloak planned %q"):format(reads(left)))
end

----------------------------------------------------------------------
-- The words, and the one step back
----------------------------------------------------------------------

do
	check(Sets.Plan("nothing at all") == nil, "a set nobody saved was planned anyway")

	local before = #Sets.All()
	check(Sets.New("raid") == nil, "a second set was made under a name already taken")
	check(Sets.New("   ") == nil, "a set was made with no name")
	check(Sets.New(("x"):rep(80)) == nil, "a set was made with a name no row can draw")
	check(#Sets.All() == before,
		("%d sets exist and %d did before the three refusals"):format(#Sets.All(), before))

	check(Sets.Rename("quiet", "quieter"), "a set would not be renamed")
	check(Sets.Get("QUIETER") ~= nil, "a set's name is matched with the case still on it")
	check(Sets.Undo(), "the rename would not be undone")
	check(Sets.Get("quiet") ~= nil and Sets.Get("quieter") == nil,
		"undo did not put the old name back")

	-- One level and no more, which is the decision rather than a start on a
	-- stack: a second undo has nothing to go back to and says so.
	check(Sets.Undo() == false, "a second undo went back a second step")
end

----------------------------------------------------------------------
-- A fight takes the armour out of the plan and leaves the hands in
--
-- Pressing a set mid pull used to refuse the whole run, because the first
-- operation on a slot the fight holds shut refused all nineteen. A warrior who
-- presses a weapon swap between two pulls got nothing and a sentence about
-- armour.
--
-- The refused operations come out of the plan and not out of the run, and that
-- is the half worth asserting: Room and Touched are both counted off plan.ops,
-- so a plan that carried the cloak's lift and stow would ask for a free bag
-- slot to put armour in that it was never going to lift, and refuse a weapon
-- swap on a full bag for it.
--
-- Nothing is held for the end of the fight. A set half applied thirty seconds
-- later, when you have moved on, is worse than a set that did the two things
-- you asked for and stopped.
----------------------------------------------------------------------

do
	local name = saved("pull", { [16] = "Gorehowl", [15] = false })
	local world = scene({
		[15] = "Shroud of Dominion",
		[16] = "Quel'Serrar",
	}, { "Gorehowl" }, 1)

	local calm = Sets.Plan(name, world)
	check(reads(calm) == "lift 15, stow, grab, drop 16, stow",
		("out of a fight that set planned %q"):format(reads(calm)))
	check(calm.room == 1,
		("out of a fight it asked for %d bag slots"):format(calm.room))

	local real = _G.InCombatLockdown
	_G.InCombatLockdown = function() return true end

	local plan = Sets.Plan(name, world)
	check(reads(plan) == "grab, drop 16, stow",
		("in a fight that set planned %q"):format(reads(plan)))
	check(plan.changed == 1,
		("%d slots would change in a fight and only the main hand is allowed"):format(plan.changed))
	check(plan.room == 0,
		("in a fight it asked for %d bag slots and the weapon swap needs none")
			:format(plan.room))

	-- And with the bags shut. The cloak's stow is the only thing in that plan
	-- that wanted a bag slot, so a weapon swap mid pull with nowhere to put a
	-- cloak is a weapon swap that runs.
	local tight = Sets.Plan(name, scene({
		[15] = "Shroud of Dominion",
		[16] = "Quel'Serrar",
	}, { "Gorehowl" }, 0))
	check(not tight.short,
		"a weapon swap in a fight was refused for want of the room the armour needed")

	_G.InCombatLockdown = real
end

----------------------------------------------------------------------
-- The two readers that ask the client rather than a scene
--
-- Wearing reads what is on you now, because there is nothing to hand it: the
-- question it answers is about the character. So this block puts a cloak on the
-- stub and takes it off again.
----------------------------------------------------------------------

do
	worn[15] = itemLink("Shroud of Dominion")

	check(not Sets.Wearing("bare"),
		"a set that wants the cloak off reads as worn while the cloak is on")
	check(Sets.Wearing("quiet") == false,
		"a set naming a ring nobody has on reads as worn")

	worn[15] = nil
end

----------------------------------------------------------------------
-- The queue, against the client
--
-- Everything above hands the planner a table. This block hands the queue a
-- character: gear on the doll, a bag with room in it, and the four cursor calls
-- the stub now really makes. What is asserted is where the pieces ended up,
-- because that is the whole of what a queue is for and it is what nothing could
-- assert before -- a run that made every call and moved nothing passed every
-- line above.
--
-- A bag of its own, bag three, put up here and taken down at the foot. The
-- three bags the stub ships with are full and belong to other sections: bag
-- zero is what the charge macro picks a weapon out of, bag one is what the
-- vendor sweep sells and bag two is the quest items. A section that emptied a
-- slot in one of them to make room would be moving what three other sections
-- count.
--
-- Which bag a stow lands in is the client's business and not this section's.
-- ns.Stow offers the backpack and then each bag in turn, so a piece taken off
-- lands wherever there is first a hole; what is asserted is that it is in a bag
-- at all and off the cursor, which is the whole of what the stow owes.
----------------------------------------------------------------------

do
	local CARRIED = H.CARRIED
	local BAG = 3

	-- Six slots, which is two more than the deepest any run below goes. The
	-- count matters: Sets.World counts the free slots in this bag as the room a
	-- plan may spend, so a bag exactly the size of the plan would leave the
	-- arithmetic reading as luck.
	local function bag(...)
		CARRIED[BAG] = { false, false, false, false, false, false }
		for index, name in ipairs({ ... }) do
			CARRIED[BAG][index] = name
		end
	end

	-- Which bag and slot a piece is in, anywhere in the bags.
	local function holding(name)
		for which = 0, 4 do
			local slots = CARRIED[which] or {}
			for index = 1, #slots do
				if slots[index] == name then
					return which, index
				end
			end
		end
		return nil
	end

	local function wearing(slot)
		local link = ns.Worn.Link(slot)
		return link and link:match("%[(.-)%]") or nil
	end

	-- The slots this block moves, read off the client and put back at the foot.
	-- Through Worn.Link and H.wear rather than the worn table, because two of
	-- the five are the hands and the stub answers those out of the swing
	-- timer's table: a two hander written into `worn` would be a weapon nothing
	-- can see.
	local was = {}
	for _, slot in ipairs({ 11, 12, 15, 16, 17 }) do
		was[slot] = ns.Worn.Link(slot)
	end

	------------------------------------------------------------------
	-- A stow puts the piece in a bag, and never back where it came from
	------------------------------------------------------------------

	-- The bug this block was written for. The stow operation ran ClearCursor,
	-- which cancels a pickup and hands the piece back to the slot it was lifted
	-- out of, so every lift and stow pair was a round trip that changed nothing:
	-- the whole of Strip, which is the half of a set that takes a piece off you,
	-- and the whole of Displaced, which is the shield a two hander pushes out.
	do
		bag()
		H.wear(15, itemLink("Shroud of Dominion"))
		local name = saved("strip", { [15] = false })

		local done, why = Sets.Wear(name)
		check(done, ("a set that takes the cloak off was refused with %q")
			:format(tostring(why)))
		check(wearing(15) == nil,
			("the cloak came off and slot 15 still holds %s"):format(tostring(wearing(15))))
		check(holding("Shroud of Dominion") ~= nil,
			"the cloak came off and is in no bag, so the stow put it back on you")
		check(_G.GetCursorInfo() == nil,
			"the run ended with the cloak still on the cursor")
		check(Sets.Running() == nil,
			("%s is still going after the run finished"):format(tostring(Sets.Running())))
	end

	------------------------------------------------------------------
	-- Two rings trading places, with no bag slot between them
	------------------------------------------------------------------

	-- The case the planner is written for, driven end to end. Three cursor
	-- operations and the bags are never touched, because the client hands the
	-- displaced ring straight back onto the cursor: lift 11, drop it on 12 and
	-- take the other back, drop that on 11.
	do
		bag()
		H.wear(11, itemLink("Band of the Left"))
		H.wear(12, itemLink("Band of the Right"))
		local name = saved("fingers", {
			[11] = "Band of the Right",
			[12] = "Band of the Left",
		})

		local done, why = Sets.Wear(name)
		check(done, ("the ring swap was refused with %q"):format(tostring(why)))
		check(wearing(11) == "Band of the Right" and wearing(12) == "Band of the Left",
			("the rings came out %s on 11 and %s on 12")
				:format(tostring(wearing(11)), tostring(wearing(12))))
		check(holding("Band of the Left") == nil and holding("Band of the Right") == nil,
			"a ring went through the bags, and there is a path through that swap with none in it")
	end

	------------------------------------------------------------------
	-- A piece out of a bag, onto a finger, and the one it displaces back
	------------------------------------------------------------------

	do
		bag("Band of the Left")
		H.wear(11, itemLink("Band of the Right"))
		H.wear(12, nil)
		local name = saved("carried", { [11] = "Band of the Left" })

		local done, why = Sets.Wear(name)
		check(done, ("a set carried out of a bag was refused with %q"):format(tostring(why)))
		check(wearing(11) == "Band of the Left",
			("the ring out of the bag came out as %s on the finger")
				:format(tostring(wearing(11))))
		check(holding("Band of the Right") ~= nil,
			"the ring the set displaced is in no bag")
		check(holding("Band of the Left") == nil,
			"the ring that went on is in the bag as well, so it was copied rather than moved")
	end

	------------------------------------------------------------------
	-- A gesture refused mid run leaves the run advancing
	------------------------------------------------------------------

	-- The second half of the bug. Step only ever runs off ITEM_LOCK_CHANGED or
	-- BAG_UPDATE and there is no ticker by design, so a gesture that Fresh
	-- refuses makes no client call and fires no event: the run stopped where it
	-- stood, `running` stayed set for the rest of the session, and every later
	-- set answered "X is still going on" until a reload.
	--
	-- The world is moved under the run from inside the first pickup, which is
	-- what a bag sort, a loot arriving or another addon's housekeeping looks
	-- like from in here. It is the only way to reach the case: a plan is made
	-- and walked inside one word, so nothing outside can move anything between
	-- the two.
	do
		bag("Shroud of Dominion", "Aegis of the Sun")
		H.wear(15, nil)
		H.wear(17, nil)
		local name = saved("twin", {
			[15] = "Shroud of Dominion",
			[17] = "Aegis of the Sun",
		})

		-- Emptied before the call rather than after it, because the call is
		-- what fires the event the queue runs on: under this stub the whole
		-- rest of the plan is walked inside it, so a world moved after it
		-- returns is a world moved after the run is over.
		local real = _G.PickupContainerItem
		local gone = false
		_G.PickupContainerItem = function(which, index)
			if not gone then
				gone = true
				CARRIED[BAG][2] = false
			end
			return real(which, index)
		end

		local said = _G.ChatFrame1.messages or {}
		local quiet = #said
		local done = Sets.Wear(name)
		_G.PickupContainerItem = real

		check(done, "a set whose second piece moved mid run was refused outright")
		check(wearing(15) == "Shroud of Dominion",
			("the piece that was still there came out as %s"):format(tostring(wearing(15))))
		check(wearing(17) == nil,
			("the shield that vanished mid run was equipped anyway, as %s")
				:format(tostring(wearing(17))))
		check(Sets.Running() == nil,
			("%s is still going, so one refused gesture stalled the queue for the session")
				:format(tostring(Sets.Running())))
		check(#said > quiet and tostring(said[#said].text):find("left alone", 1, true) ~= nil,
			("the run's line reads %q and it has to name what it left alone")
				:format(tostring(said[#said] and said[#said].text)))

		-- And the next word runs, which is the symptom the player actually met.
		H.wear(15, nil)
		bag("Shroud of Dominion")
		local again, why = Sets.Wear(name)
		check(again, ("the next set was refused with %q"):format(tostring(why)))
	end

	------------------------------------------------------------------
	-- And in a fight the weapons land and the armour does not
	------------------------------------------------------------------

	do
		bag("Gorehowl")
		H.wear(15, itemLink("Shroud of Dominion"))
		H.wear(16, itemLink("Quel'Serrar"))
		H.wear(17, nil)
		local name = saved("mid", { [16] = "Gorehowl", [15] = false })

		local real = _G.InCombatLockdown
		_G.InCombatLockdown = function() return true end
		local done, why = Sets.Wear(name)
		_G.InCombatLockdown = real

		check(done, ("a weapon swap mid pull was refused with %q"):format(tostring(why)))
		check(wearing(16) == "Gorehowl",
			("the two hander came out as %s in the main hand"):format(tostring(wearing(16))))
		check(wearing(15) == "Shroud of Dominion",
			("the cloak came off in a fight and slot 15 reads %s")
				:format(tostring(wearing(15))))
	end

	------------------------------------------------------------------
	-- Left as it was found
	--
	-- The gear back on the doll, the extra bag gone, and every fixture this
	-- block put in one of the stub's own bags swept out of it. That last is not
	-- housekeeping: the item lookup reads ITEMS by name and the foot of this
	-- section deletes these seven, so a ring left in the vendor bag is a crash
	-- in whichever section next draws that slot.
	------------------------------------------------------------------

	for _, slot in ipairs({ 11, 12, 15, 16, 17 }) do
		H.wear(slot, was[slot])
	end
	CARRIED[BAG] = nil
	for which = 0, 4 do
		local slots = CARRIED[which] or {}
		for index = 1, #slots do
			if FIXTURES[slots[index]] then
				slots[index] = false
			end
		end
	end
	for _, name in ipairs({ "strip", "fingers", "carried", "twin", "mid" }) do
		Sets.Remove(name)
	end
	check(_G.GetCursorInfo() == nil, "the queue block left something on the cursor")
end

----------------------------------------------------------------------
-- Put the scene back
----------------------------------------------------------------------

for _, name in ipairs({ "raid", "swapped", "cleave", "trinkets", "bare", "quiet", "pull" }) do
	Sets.Remove(name)
end
for name in pairs(FIXTURES) do
	ITEMS[name] = nil
end

print(("sets %d saved after the run, a pair of rings trades places in three cursor operations, a fight leaves the armour out of the plan, and the queue is driven against the client: a stow fills a bag, a ring swap touches none, and a gesture refused mid run leaves the queue advancing")
	:format(#Sets.All()))
