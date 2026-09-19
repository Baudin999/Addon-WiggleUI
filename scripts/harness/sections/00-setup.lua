-- The setup's four questions
--
-- Straight after login, because login is what put it up: the harness account
-- is a fresh one, and a fresh account is asked. It walks every page, answers,
-- and checks the four answers landed in the saved settings they stand for,
-- then puts every one of them back and shuts the window, so no section below
-- finds a window of this one's standing over the screen or a theme it did not
-- load with.

local H = ...
local ns, check = H.ns, H.check
local Setup, UI = ns.Setup, ns.UI

check(Setup.IsShown(), "a fresh account logged in and was not asked the setup's questions")
check(not ns.db.setupDone, "the setup counts as answered before anybody answered it")

local step, lit = Setup.Where()
check(step == 1 and lit == ns.db.theme,
	("the setup opened on step %s with %s lit, and the saved mode is %s")
		:format(tostring(step), tostring(lit), tostring(ns.db.theme)))

-- Every mode, palette, look and place a card offers is one the setting takes,
-- and every palette has a card: a palette added without one is a colour a new
-- player cannot pick at the start.
local offered = {}
for _, entry in ipairs(Setup.STEPS[2].cards) do
	offered[entry.value] = true
end
for _, name in ipairs(ns.Theme.PALETTES) do
	check(offered[name], ("the setup offers no card for the palette %s"):format(name))
end
for _, entry in ipairs(Setup.STEPS[1].cards) do
	check(ns.Themes[entry.value] ~= nil, ("the setup offers the mode %s and there is no such theme")
		:format(tostring(entry.value)))
end

-- The unit frame card paints your class and your power, and a colour that is
-- not three numbers raises in the client where the stub here takes it.
local health, power = ns.SetupPreviews.Colours()
check(type(health) == "table" and type(health[1]) == "number"
	and type(power) == "table" and type(power[1]) == "number",
	"the unit frame card's class or power colour is not a colour")

-- What was there, so it can be put back at the foot.
local kept = {
	theme = ns.db.theme, palette = ns.db.palette,
	gaugeLook = ns.db.gaugeLook, portraits = ns.db.portraits,
}
local places = {}
for _, each in ipairs(UI.Tooltip.TYPES) do
	places[each.key] = ns.Settings.Place(each.key)
end
local reloads = H.state.reloads

--------------------------------------------------------------------------
-- Walked and answered
--------------------------------------------------------------------------

Setup.Pick("theme", "immersive")
Setup.Forward()
Setup.Pick("palette", "forest")
Setup.Forward()
Setup.Pick("plates", "modern")
Setup.Forward()
check(Setup.Where() == 4, ("three nexts landed on step %s"):format(tostring(Setup.Where())))
check(ns.db.theme == kept.theme, "the setup wrote the mode before its last page")
Setup.Pick("tips", UI.Tooltip.ATTACHED)
Setup.Forward()

check(not Setup.IsShown(), "finishing the setup left its window up")
check(ns.db.setupDone, "finishing the setup did not mark it answered")
check(ns.db.theme == "immersive" and ns.db.palette == "forest",
	("the setup wrote the mode %s and the palette %s"):format(ns.db.theme, ns.db.palette))
check(ns.db.gaugeLook == "modern" and ns.db.portraits == false,
	"modern frames did not take the portraits off")
check(H.state.reloads == reloads + 1, "a new mode and palette were written with no reload to draw them")
for _, each in ipairs(UI.Tooltip.TYPES) do
	check(ns.Settings.Place(each.key) == UI.Tooltip.ATTACHED,
		("the %s tooltip opens %s after the setup said attached"):format(each.key, ns.Settings.Place(each.key)))
end

-- Flat puts the portraits back, and a second run starts lit on the answers
-- the first one wrote.
Setup.Show()
check(select(2, Setup.Where()) == "immersive", "a second run did not start on the saved mode")
Setup.Go(3)
Setup.Pick("plates", "flat")
Setup.Go(4)
Setup.Pick("tips", UI.Tooltip.RIGHT)
Setup.Forward()
check(ns.db.gaugeLook == "flat" and ns.db.portraits == true, "flat frames did not put the portraits back")
check(ns.Settings.Place("bag") == UI.Tooltip.RIGHT, "bottom right did not reach the bag's tooltip")
check(ns.Settings.Place("pin") == UI.Tooltip.ATTACHED,
	("a map pin's tooltip opens %s after bottom right, and a pin is always attached")
		:format(ns.Settings.Place("pin")))

--------------------------------------------------------------------------
-- Closed without answering
--------------------------------------------------------------------------

ns.db.setupDone = false
local before = ns.db.theme
Setup.Show()
Setup.Pick("theme", "informational")
Setup.Hide()
check(ns.db.setupDone, "closing the setup left it to come back at the next login")
check(ns.db.theme == before, "closing the setup wrote an answer nobody finished")

--------------------------------------------------------------------------
-- Put back
--------------------------------------------------------------------------

for key, value in pairs(kept) do
	ns.db[key] = value
end
for sort, place in pairs(places) do
	ns.Settings.SetPlace(sort, place)
end

-- Finishing laid the mode's shipped screen on the profile, zooms and all, and
-- every section below measures pixels at the design size.
H.DesignSize()
