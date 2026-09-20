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
-- **The queue is not driven here.** It is one cursor operation per server
-- event, and a stub for that would be a model of the server rather than of the
-- addon; what the addon owes is the plan the queue walks, and that is what is
-- read. The refusal in a fight is asserted, because that one is a call into
-- Character/Worn.lua rather than a round trip.
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
-- The two readers that ask the client rather than a scene
--
-- Wearing and Wear read what is on you now, because there is nothing to hand
-- them: the question they answer is about the character. So this block puts a
-- cloak on the stub and takes it off again, and it is the only place in this
-- file where the world is the client's.
--
-- The fight is what the block is really for. Character/Worn.lua holds the rule
-- per slot -- the two hands and the bow may be changed mid pull and nothing
-- else may -- and a word that quietly did nothing is the worst version of this,
-- so the sentence is read back rather than the return.
----------------------------------------------------------------------

do
	worn[15] = itemLink("Shroud of Dominion")

	check(not Sets.Wearing("bare"),
		"a set that wants the cloak off reads as worn while the cloak is on")
	check(Sets.Wearing("quiet") == false,
		"a set naming a ring nobody has on reads as worn")

	local real = _G.InCombatLockdown
	_G.InCombatLockdown = function() return true end

	local done, why = Sets.Wear("bare")
	check(done == false, "a cloak was taken off in the middle of a fight")
	check(tostring(why):find("fight", 1, true) ~= nil,
		("wearing a set in a fight was refused with %q"):format(tostring(why)))

	_G.InCombatLockdown = real
	worn[15] = nil
end

----------------------------------------------------------------------
-- Put the scene back
----------------------------------------------------------------------

for _, name in ipairs({ "raid", "swapped", "cleave", "trinkets", "bare", "quiet" }) do
	Sets.Remove(name)
end
for name in pairs(FIXTURES) do
	ITEMS[name] = nil
end

print(("sets %d saved after the run, and a pair of rings trades places in three cursor operations")
	:format(#Sets.All()))
