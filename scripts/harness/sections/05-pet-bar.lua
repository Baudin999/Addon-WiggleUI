-- The pet bar
--
-- Buttons/Pet.lua stands ten squares in for Blizzard's PetActionBar. Six
-- things reading it does not settle.
--
--   That a press reaches the pet. The left half is the secure pet action on
--   the square's own slot, and the right half is Blizzard's button for that
--   slot, which is where autocast is toggled.
--
--   That Blizzard's bar goes into the attic and comes back out with no field
--   written on it. Its own OnEvent calls Show before it lays out ten secure
--   buttons, so a stripped Show is a taint on that path.
--
--   That the client holds the bar's visibility, with one driver after a second
--   apply and none after the off switch.
--
--   That the keys on the pet binding set are drawn on the squares.
--
--   That shift and a drag moves it the way it moves the action bars.
--
--   That a slot draws its art, a token's art, the active ring, a countdown and
--   the autocast mark.

local H = ...
local ns, check = H.ns, H.check

local ART = "Interface\\Icons\\Ability_Hunter_Pet_Assist"
local ATTACK = "Interface\\Icons\\Ability_GhoulFrenzy"
local FRAME = 0.15 -- past the tenth of a second the pet tick asks for

do
	local Pet = ns.PetBar
	local theirs = _G.PetActionBar
	local was = ns.db.actionBars

	ns.db.actionBars = true
	check(Pet.Apply(), "the pet bar reported combat deferring it with no combat running")

	local bar, squares = Pet.Frame(), Pet.Squares()
	check(bar ~= nil and #squares == 10,
		("the pet bar has %d squares and Blizzard's has ten"):format(#squares))

	for index = 1, #squares do
		local w = squares[index]
		check(w:GetAttribute("type") == "pet" and w:GetAttribute("action") == index,
			("pet square %d does not cast pet slot %d"):format(index, index))
		check(w:GetAttribute("type2") == "click"
			and w:GetAttribute("clickbutton2") == _G["PetActionButton" .. index],
			("a right press on pet square %d does not reach Blizzard's button for it"):format(index))
	end

	-- The keys, read off the pet binding set Blizzard's own button reads, and
	-- drawn in the corner the action bars draw theirs in.
	local bindings = _G.WarriorKitBindings
	bindings.BONUSACTIONBUTTON4 = { "G" }
	bindings.BONUSACTIONBUTTON6 = { "SHIFT-R" }
	_G.WarriorKitRebuildBindings()
	check(squares[4].key:GetText() == "G",
		("pet square 4 draws %q for the key G"):format(tostring(squares[4].key:GetText())))
	check(squares[6].key:GetText() == "sR",
		("pet square 6 draws %q for the key SHIFT-R"):format(tostring(squares[6].key:GetText())))
	check(squares[5].key:GetText() == "", "pet square 5 draws a key with none bound")

	check(theirs:GetParent() == ns.Attic.Frame(),
		"Blizzard's pet bar is not in the attic with the clone on")
	check(rawget(theirs, "wkStripped") == nil,
		"Blizzard's pet bar had its Show written, which taints its own OnEvent")

	check(_G.WarriorKitDriver(bar, "visibility") == "[pet] show; hide",
		"the client is not holding the pet bar's visibility")
	Pet.Apply()
	check(_G.WarriorKitDrivers(bar, "visibility") == 1,
		"a second apply left two visibility drivers on the pet bar")

	--------------------------------------------------------------------------
	-- Placing it
	--
	-- Shift and a drag, the way the action bars move: the handle
	-- Buttons/Placing.lua lays over them comes up over this bar too, a drop is
	-- written where theirs are, and the bars' reset puts it back where it ships.
	--------------------------------------------------------------------------

	local handle = Pet.Handle()
	local wasLocked, wasBars = ns.db.locked, ns.db.barsLocked
	ns.db.locked, ns.db.barsLocked = true, false
	_G.WarriorKitShift(true)
	H.fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
	check(handle ~= nil and handle:IsShown(), "shift put no drag handle over the pet bar")

	local took, dragging = H.mouse.DragTo(handle, bar, -300.4, 400.6)
	check(took == handle and dragging,
		("a drag on the middle of the pet bar landed on %s, dragging %s")
			:format(took and (took:GetName() or took:GetObjectType()) or "nothing",
				tostring(dragging)))
	local saved = ns.db.barPoints.pet
	check(saved and saved[4] == -300 and saved[5] == 401,
		("a pet bar drag to -300.4, 400.6 recorded %s, %s"):format(
			tostring(saved and saved[4]), tostring(saved and saved[5])))
	local printed = ns.Bars.Where()
	check(printed[#printed]:find("pet: ") and printed[#printed]:find("dragged"),
		"where printed no line for the dragged pet bar: " .. tostring(printed[#printed]))

	_G.WarriorKitShift(false)
	H.fire("MODIFIER_STATE_CHANGED", "LSHIFT", 0)
	check(not handle:IsShown(), "the pet bar's handle stayed up after shift came off")

	check(ns.Bars.ResetPlacing() == 1 and ns.db.barPoints.pet == nil,
		"the bars' reset left the pet bar where it was dragged")
	local _, _, _, x, y = bar:GetPoint()
	check(x == 0 and y == 184,
		("reset put the pet bar at %s, %s rather than where it ships"):format(tostring(x), tostring(y)))
	ns.db.locked, ns.db.barsLocked = wasLocked, wasBars
	ns.Each("lock")

	--------------------------------------------------------------------------
	-- What a pass draws
	--------------------------------------------------------------------------

	local slots = H.petSlots
	_G.PET_ATTACK_TEXTURE = ATTACK
	slots[1] = { texture = ART }
	slots[2] = { texture = "PET_ATTACK_TEXTURE", token = true, active = true }
	slots[3] = { texture = ART, autoAllowed = true, autoOn = true }
	slots[4] = { texture = ART, start = _G.GetTime(), duration = 30 }
	slots[5] = { texture = ART, autoAllowed = true }

	-- The driver stub records the macro and decides nothing, so the pet the
	-- macro asks about is stood in for by showing the bar.
	bar:Show()
	local tick = H.tick("pet")
	tick:Beat(FRAME)

	check(squares[1].shownTexture == ART, "a pet slot with art drew none")
	check(squares[2].shownTexture == ATTACK,
		"a token slot drew the global's name rather than the art it names")
	check(squares[2].shownActive == true, "the pet's attack drew no active ring while it is on")
	check(squares[3].auto:IsShown() and squares[3].shownAuto == 1,
		"an ability that casts itself drew no autocast mark")
	check(squares[5].auto:IsShown() and squares[5].shownAuto < 1,
		"an ability that could cast itself drew the mark at full or not at all")
	check(squares[4].shownTick ~= nil, "a thirty second pet cooldown drew no countdown")
	check(squares[6].shownTexture == nil and not squares[6].auto:IsShown(),
		"an empty pet slot drew art or a mark")

	--------------------------------------------------------------------------
	-- Off and on
	--------------------------------------------------------------------------

	ns.db.actionBars = false
	check(Pet.Apply(), "the pet bar's off switch reported combat with no combat running")
	check(theirs:GetParent() == _G.UIParent, "the off switch did not give Blizzard's pet bar back")
	check(not bar:IsShown(), "the pet bar stayed up with the clone off")
	check(_G.WarriorKitDrivers(bar, "visibility") == 0,
		"the off switch left the client holding the pet bar's visibility")

	for index = 1, 10 do
		slots[index] = nil
	end
	ns.db.actionBars = was
	Pet.Apply()

	bindings.BONUSACTIONBUTTON4, bindings.BONUSACTIONBUTTON6 = nil, nil
	_G.WarriorKitRebuildBindings()

	print("pet    ten squares with their keys, Blizzard's bar caged and handed back, one driver, shift drags it")
end
