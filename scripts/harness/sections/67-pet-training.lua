-- A hunter's pet, on the talent window's last tab
--
-- The anniversary client has no pet talent tree. It has Beast Training, a craft
-- session the hunter opens by casting a spell, and the page is what this
-- section drives: the tab, the secure square that casts the spell, the session
-- arriving and taking the page over from CraftFrame, what the pet knows off
-- its own book, the rims, the secure button that teaches through Blizzard's
-- CraftCreateButton, and the session ending with the window.
--
-- **Every class runs it.** A class with no pet to train must draw no tab and
-- must leave a beast training window it did not open to the client. The rest
-- is a hunter's, and check.sh runs the harness as one.
--
-- What this cannot prove is that the client agrees. GetCraftInfo's cost and
-- level are read where Blizzard_CraftUI/TBC reads them and client
-- /20-tradeskill.lua answers in those slots, and a slot that moved is a test
-- that passes and a page that prices nothing.

local H = ...
local ns, check, fire = H.ns, H.check, H.fire
local shop = H.professions

local Window, Training, Pet = ns.TalentWindow, ns.TalentTraining, ns.TalentPet
local Blizz = ns.TrainingBlizzard
local C = ns.UI.Color

local function same(color, r, g, b)
	return math.abs(color[1] - r) < 1e-6 and math.abs(color[2] - g) < 1e-6
		and math.abs(color[3] - b) < 1e-6
end

local function Rim(row)
	return row.square.edges.r, row.square.edges.g, row.square.edges.b
end

local function BoxText()
	local Tooltip = ns.UI.Tooltip
	local out = {}
	for index = 1, Tooltip.Lines() or 0 do
		out[#out + 1] = Tooltip.Text(index) or ""
	end
	return table.concat(out, "\n")
end

if not Training.Offered() then
	Window.Show()
	check(not Window.Tabs():IsShown(3), "a class with no pet to train drew a pet tab")
	check(not Window.ShowPet(), "a class with no pet to train opened the pet's page")
	Window.Hide()

	shop.openCraft("Beast Training")
	check(not Training.Shown() and not Window.Shown(),
		"a beast training window on a class with no pet to train was taken off the client")
	check(not Blizz.Parked(), "a beast training window on a class with no pet to train was parked")
	_G.CloseCraft()
	print(("pet training: %s"):format(Training.Describe()))
	return
end

-- A pet out: a wolf at fifty eight with fifty points left of two hundred.
local guids, names, levels = H.guids, H.unitName, _G.WarriorKitLevels
local had = { guid = guids.pet, name = names.pet, level = levels.pet }
guids.pet, names.pet, levels.pet = "Creature-0-0-0-0-1234-0000000001", "Kibble", 58
fire("UNIT_PET", "player")

----------------------------------------------------------------------
-- The tab, with the session shut
----------------------------------------------------------------------

do
	Window.Show()
	check(Window.Tabs():IsShown(3), "a hunter's talent window has no pet tab")
	check(Window.ShowPet() and Window.OnPet(), "the pet's tab would not open")
	check(not Window.Board(1).frame:IsShown(), "the trees stayed up under the pet's page")
	local page = Pet.Page()
	check(page:IsVisible(), "the pet's page is not on the screen")
	check(Pet.Rows() == 0, ("with no session the page drew %d abilities"):format(Pet.Rows()))
	check(Pet.Summary() == "150 spent, 50 left",
		("the pet's points read %s rather than what is spent and what is left"):format(tostring(Pet.Summary())))

	-- What the pet knows is there without a session, off its own book, and a
	-- command with no rank is not an ability.
	check(Pet.KnownRows() == 2, ("the pet's book gave %d known abilities of two"):format(Pet.KnownRows()))
	local bite = Pet.Known(1)
	check(bite and bite.name == "Bite" and bite.sub:GetText() == "Rank 7" and same(C.heading, Rim(bite)),
		"a known ability is not drawn gold with its rank")

	local square, spot = Pet.Square(), Pet.Spot()
	check(square:IsShown(), "with the session shut the Beast Training square is not up")
	check(square:GetAttribute("type") == "spell" and square:GetAttribute("spell") == Training.SPELL,
		"the Beast Training square does not cast spell 5149")
	check(square:GetAttribute("useOnKeyDown") == false,
		"the Beast Training square does not act on the edge it is registered for")
	check(square:GetParent() == _G.UIParent, "the Beast Training square hangs off the insecure talent window")
	local _, relative, _, x, y = square:GetPoint(1)
	check(relative == _G.UIParent and x == spot:GetLeft() and y == spot:GetTop(),
		("the Beast Training square sits at %s, %s and its spot is at %s, %s")
			:format(tostring(x), tostring(y), tostring(spot:GetLeft()), tostring(spot:GetTop())))
	check(math.abs(square:GetEffectiveScale() - spot:GetEffectiveScale()) < 1e-9,
		"the Beast Training square is not at the page's scale")
	check(_G.WarriorKitDriver(Pet.Driver(), "combat") == "[combat] on; off",
		"nothing hides the secure buttons when a fight starts")
end

----------------------------------------------------------------------
-- The session
----------------------------------------------------------------------

do
	Window.Hide()
	shop.openCraft("Beast Training")
	check(Training.Shown(), "the page did not take the beast training session")
	check(Window.Shown() and Window.OnPet(), "beast training opening did not open the pet's page")
	check(Blizz.Parked(), "CraftFrame was left on the screen under the pet's page")
	local frame = shop.craftFrame
	check(frame:IsShown() and frame:GetAlpha() == 0,
		"CraftFrame was hidden rather than parked, which would close the session")
	check(not Pet.Square():IsShown(), "the Beast Training square stayed up over the list")

	-- Five rows and a header: the one the pet has is on the known list, the
	-- header is not a square, and three are left.
	check(Pet.Rows() == 3, ("the page drew %d abilities to teach of three"):format(Pet.Rows()))
	local teachable, dear, young = Pet.Row(1), Pet.Row(2), Pet.Row(3)
	check(teachable.learnable and same(C.tick, Rim(teachable)), "a rank the pet can be taught does not wear the green rim")
	check(teachable.sub:GetText() == "Rank 8, 17 points",
		("a teachable rank reads %s"):format(tostring(teachable.sub:GetText())))
	check(not dear.learnable and dear.dim and same(C.edge, Rim(dear)), "a rank the points do not reach reads as teachable")
	check(not young.learnable and young.dim and same(C.hairline, Rim(young)), "a rank the pet is too young for reads as teachable")
	check(young.sub:GetText() == "Rank 3, pet level 70", ("a rank for an older pet reads %s"):format(tostring(young.sub:GetText())))
	check(Window.Describe() == "open on the pet", ("the window says it is %s"):format(Window.Describe()))

	-- Nothing to teach gets no secure button, and a press on it reaches nothing.
	local teach = Pet.Teach()
	young:GetScript("OnEnter")(young)
	check(BoxText():find("Needs your pet at level 70", 1, true) ~= nil,
		"an ability for an older pet does not say what level")
	check(not teach:IsShown(), "an ability the pet is too young for got a secure button")
	young:GetScript("OnLeave")(young)
	H.tipSettle()
	local taught = #shop.training.taught
	H.mouse.On(young)
	H.mouse.On(dear)
	check(#shop.training.taught == taught, "a press on an ability the pet cannot learn reached the client")

	-- A teachable one: picked, the secure button laid over it, and the press
	-- goes through Blizzard's own button, because DoCraft is refused an addon.
	H.tooltips.craft[teachable.index] = { { "Bite" }, { "Bite the enemy, causing damage." } }
	local index = teachable.index
	teachable:GetScript("OnEnter")(teachable)
	local text = BoxText()
	check(text:find("Bite the enemy", 1, true) ~= nil, "the client's description is not in an ability's box")
	check(text:find("Click to teach your pet", 1, true) ~= nil, "a teachable ability's box does not say so")
	check(teach:IsShown() and teach.row == teachable, "hovering a teachable ability laid no secure button over it")
	check(teach:GetAttribute("type") == "click" and teach:GetAttribute("clickbutton") == _G.CraftCreateButton,
		"the secure button over an ability does not press CraftCreateButton")
	check(teach:GetParent() == _G.UIParent, "the secure button over an ability hangs off the insecure talent window")
	check(_G.GetCraftSelectionIndex() == index and _G.CraftCreateButton:IsEnabled(),
		"hovering a teachable ability did not pick it in Blizzard's list")
	H.mouse.On(teach)
	check(#shop.training.taught == taught + 1 and shop.training.taught[#shop.training.taught] == index,
		"a press on the secure button did not reach DoCraft through CraftCreateButton")
	check(not teach:IsShown(), "the secure button stayed up over a list the repaint moved")
	check(Pet.Rows() == 2, ("after teaching one the page still drew %d to teach"):format(Pet.Rows()))
	check(Pet.Summary() == "167 spent, 33 left", ("after seventeen points the pet reads %s"):format(tostring(Pet.Summary())))
	ns.Tip.Close()
	H.tipSettle()

	-- The window going takes the session with it and hands the frame back.
	Window.Hide()
	check(not Training.Shown() and not Training.Open(), "closing the talent window left beast training open")
	check(not Blizz.Parked() and frame:GetAlpha() == 1, "CraftFrame stayed parked after the session ended")
end

----------------------------------------------------------------------
-- The switches
----------------------------------------------------------------------

do
	ns.db.talents = false
	shop.openCraft("Beast Training")
	check(not Training.Shown() and not Window.Shown() and not Blizz.Parked(),
		"with the talent window off beast training was taken off the client")
	_G.CloseCraft()
	ns.db.talents = true
end

print(("pet training %s; Blizzard's craft frame %s"):format(Training.Describe(), Blizz.Describe()))

-- The pet and its points as they were, and the rank taught untaught.
shop.training.spent = 150
for _, row in ipairs(shop.CRAFTS["Beast Training"]) do
	if row.name == "Bite" and row.sub == "Rank 8" then
		row.kind = nil
	end
end
guids.pet, names.pet, levels.pet = had.guid, had.name, had.level
fire("UNIT_PET", "player")
