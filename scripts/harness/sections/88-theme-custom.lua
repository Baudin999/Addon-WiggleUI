-- A theme of your own
--
-- Three things that can go wrong here without a word being said on the screen.
--
-- The list is saved variables, which is the one input the addon cannot check
-- at the compiler. A theme that arrived with a missing element, a cell that is
-- a string, or two themes under one name has to come back out of the load as a
-- theme that names every element once, because the dresser reads it without
-- asking.
--
-- The cell is three dials where the shipped themes are one word, and the two
-- have to mean the same things. A word taken apart into dials and put back
-- together is the round trip that holds a theme copied from exploration equal
-- to exploration.
--
-- And a fight is the one moment a theme changes on its own. The client refuses
-- to show or hide a protected frame mid pull, so an element with a fight
-- fraction is never hidden and the swap is alpha on a veil that is already
-- there: it has to land on the event, not at the end of the pull.

local H = ...
local ns, check = H.ns, H.check
local UI = ns.UI
local Themes, Theme = ns.Themes, ns.Theme

local FAINT, DIM = 0.4, 0.1

--------------------------------------------------------------------------
-- Making one
--------------------------------------------------------------------------

check(#Themes.Own() == 0, "the harness came up with a theme of its own already saved")

local index = Themes.Make("Raid nights", "exploration")
check(index == 1, "the first theme of your own did not come back as the first")

local mine = Themes.Own()[index]
check(mine and mine.name == "Raid nights", "the theme did not keep the name it was given")

-- Copied from exploration, so it has to do what exploration does, cell for
-- cell, through the reading every part uses.
for _, element in ipairs(Themes.ELEMENTS) do
	local was = Theme.Describe(Themes.exploration, element.key)
	local now = Theme.Describe(mine.elements, element.key)
	check(was == now,
		("a copy of exploration says %s for %s and exploration says %s")
			:format(now, element.key, was))
end

check(Themes.Named("Raid nights") == mine.elements,
	"a theme of yours is not found by the name it was made under")
check(Themes.Named("raid nights") == mine.elements,
	"a theme of yours is not found when the name is typed in lower case")
check(select(1, Themes.Find("RAID NIGHTS")) == 1, "Find compares names with case")

local names = Themes.Names()
check(#names == 4 and names[4] == "Raid nights",
	"the name list does not put yours after the three that ship")

-- The names nobody may take.
check(Themes.Make("immersive") == nil, "a theme took one of the addon's own names")
check(Themes.Make("none") == nil, "a theme took the wiggle's word for no target")
check(Themes.Make("  ") == nil, "a theme was made with nothing but spaces for a name")
check(Themes.Make("Raid Nights") == nil, "two themes were made under one name")
check(#Themes.Own() == 1, "a refused name left a theme behind anyway")

--------------------------------------------------------------------------
-- The cell
--------------------------------------------------------------------------

mine.elements.chat = { alpha = FAINT, hover = true, combat = DIM }
local alpha, hover, hidden, combat = Themes.Cell(mine.elements, "chat")
check(alpha == FAINT and hover and not hidden and combat == DIM,
	"a cell of three dials does not read back as the three dials it was written with")

mine.elements.feeds = { alpha = 0, hover = false }
local _, _, feedsHidden = Themes.Cell(mine.elements, "feeds")
check(feedsHidden, "an element drawn at nothing with no pointer to bring it back is not hidden")

-- The one rule the cell enforces against what it was told: an element with a
-- fight fraction is dimmed rather than taken away, because the client will not
-- put a protected frame back on the screen in the middle of a pull.
mine.elements.buffs = { alpha = 0, hover = false, combat = 1 }
local _, _, buffsHidden = Themes.Cell(mine.elements, "buffs")
check(not buffsHidden, "an element that differs in a fight was taken off the screen anyway")

check(Themes.Fights(mine.elements), "a theme with a fight fraction says it does not fight")
check(not Themes.Fights(Themes.exploration), "a shipped theme claims a fight fraction")

--------------------------------------------------------------------------
-- On the screen
--------------------------------------------------------------------------

local function Worn(key)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(40, 40)
	frame:SetPoint("CENTER")
	Theme.Wear(key, frame)
	return frame
end

local chat, feeds, buffs, player = Worn("chat"), Worn("feeds"), Worn("buffs"), Worn("player")

Theme.Try(mine)
check(Theme.Showing() == "Raid nights", "the theme being edited is not the one showing")
check(UI.Veiled(chat):GetAlpha() == FAINT and chat.wuiReveal and chat.wuiReveal:IsShown(),
	"a cell at a fraction with the pointer on does not rest at that fraction")
check(not UI.Veiled(feeds):IsShown(), "a cell drawn at nothing left its element on the screen")
check(UI.Veiled(buffs):IsShown() and UI.Veiled(buffs):GetAlpha() == 0,
	"a cell that differs in a fight is not drawn at nothing while there is no fight")

-- Everything up, so the creator's rims have something to sit on. Not a state
-- of the theme's own: the frames unlocked, which is what also makes the cast
-- bar and the buff nag preview themselves.
ns.db.locked = false
ns.Each("lock")
check(UI.Veiled(feeds):IsShown() and UI.Veiled(feeds):GetAlpha() == 1,
	"unlocking left a hidden element off the screen, so it cannot be pointed at")
check(not chat.wuiReveal:IsShown(),
	"unlocking left a catcher over an element, so a click on it lands on the catcher")
ns.db.locked = true
ns.Each("lock")
check(not UI.Veiled(feeds):IsShown(), "locking again left a hidden element up")

--------------------------------------------------------------------------
-- The fight
--------------------------------------------------------------------------

local realLockdown = _G.InCombatLockdown
_G.InCombatLockdown = function() return true end
H.fire("PLAYER_REGEN_DISABLED")
check(UI.Veiled(buffs):GetAlpha() == 1,
	"the pull did not bring up the element that is only drawn in a fight")
check(UI.Veiled(chat):GetAlpha() == DIM,
	"the pull did not take the chat window down to its fight fraction")
check(chat.wuiReveal:IsShown(),
	"the pull took the pointer catcher off an element that still comes up under the pointer")

_G.InCombatLockdown = realLockdown
H.fire("PLAYER_REGEN_ENABLED")
check(UI.Veiled(buffs):GetAlpha() == 0, "the fight ending left the buff nag up")
check(UI.Veiled(chat):GetAlpha() == FAINT, "the fight ending left the chat window at its fight fraction")

-- An element the theme leaves as drawn is still never touched, whoever wrote
-- the theme: no veil, no reparent, nothing.
check(UI.Veiled(player) == nil, "a cell that is as drawn in every theme took a veil anyway")

Theme.Try(nil)
check(Theme.Showing() == "informational", "the theme being put down did not put the drawn one back")
check(UI.Veiled(chat):GetAlpha() == 1 and UI.Veiled(feeds):IsShown(),
	"the theme being put down left an element dressed for it")

--------------------------------------------------------------------------
-- The rail, and the elements that cannot be pointed at
--
-- The experience rail is the one element with a second question after how
-- visible it is, because minimal is a different drawing rather than a fainter
-- one. A theme of yours answers it on its record; the shipped three answer it
-- in Themes.RAIL.
--
-- And four elements are only drawn for a moment at a time, so a rim cannot sit
-- on them. Those are chips in the tray, and a chip is the only way to choose
-- one by pointing.
--------------------------------------------------------------------------

check(Themes.RailOf("exploration") == "minimal", "exploration stopped drawing the minimal rail")
check(Themes.RailOf("informational") == nil, "informational decides the rail and should not")
check(Themes.RailOf("Raid nights") == nil, "a theme of yours decides the rail before it was asked to")

local style = ns.ProgressRails.Describe()
mine.rail = "minimal"
Theme.Try(mine)
check(Theme.RailStyle() == "minimal", "a theme of yours cannot ask for the minimal rail")
check(ns.ProgressRails.Describe():find("minimal", 1, true),
	"a theme of yours asking for the minimal rail did not draw it")

-- An element nothing is drawing wears no rim, because a rim is a child of the
-- frame it sits on. The tray stands a chip in for each of those, and for none
-- of the elements that can be pointed at: a tray carrying every element would
-- be a second copy of the dropdown.
ns.ThemeEdit.Start()
check(ns.db.locked == false, "the creator did not unlock the frames, so nothing previews itself")

local visible = {}
Theme.Worn(function(key, frame)
	if frame:IsVisible() then
		visible[key] = true
	end
end)

local chipped = {}
for _, element in ipairs(Themes.ELEMENTS) do
	local chip = ns.ThemeEdit.Chip(element.key)
	if chip then
		chipped[#chipped + 1] = element.key
	end
	check((chip ~= nil) ~= (visible[element.key] == true),
		("%s %s a chip and it %s on the screen to be pointed at")
			:format(element.label, chip and "has" or "has no",
				visible[element.key] and "is" or "is not"))
end
check(#chipped > 0, "every element was on the screen, so the tray was never tested")

local spare
for _, element in ipairs(Themes.ELEMENTS) do
	if not spare and ns.ThemeEdit.Chip(element.key) then
		spare = element.key
	end
end
ns.ThemeEdit.Pick("chat")
H.mouse.Deliver(ns.ThemeEdit.Chip(spare), "OnClick")
check(ns.ThemeEdit.Picked() == spare, "clicking a chip did not choose the element it stands for")

ns.ThemeEdit.Stop()
check(ns.ThemeEdit.Chip(spare) == nil, "the page closing left the tray on the screen")
check(ns.db.locked == true, "the page closing left the frames unlocked")
mine.rail = nil
Theme.Try(nil)
check(ns.ProgressRails.Describe() == style, "putting the theme down did not put the rail's style back")

--------------------------------------------------------------------------
-- Renaming and dropping
--------------------------------------------------------------------------

ns.db.theme = "Raid nights"
ns.db.wiggleInformational = "Raid nights"
check(Themes.Rename(1, "Raid"), "a theme could not be renamed to a free name")
check(ns.db.theme == "Raid", "the chosen theme still names the old spelling after a rename")
check(ns.db.wiggleInformational == "Raid", "a wiggle target still names the old spelling after a rename")

-- A theme of yours keeps its own wiggle target, because a setting named after
-- something you can rename is a key left behind holding an answer nothing reads.
mine.wiggle = "immersive"
check(Themes.Rename(1, "immersive") == false, "a theme was renamed onto one of the addon's own names")
check(mine.name == "Raid", "a refused rename wrote the name anyway")

Themes.Drop(1)
check(#Themes.Own() == 0, "the theme was not dropped")
check(ns.db.theme == "informational", "the chosen theme was left naming a theme that is gone")
check(ns.db.wiggleInformational == "none", "a wiggle target was left naming a theme that is gone")

--------------------------------------------------------------------------
-- What the load makes of a file it did not write
--------------------------------------------------------------------------

ns.db.themes = {
	{ name = "Bad cells", rail = "sideways",
	  elements = { chat = "hover", nosuch = { alpha = 0.5 } } },
	{ name = "Bad cells" },
	{ name = "   " },
	"not a theme at all",
}
Themes.Load()
check(#Themes.Own() == 2,
	("the load kept %d of four themes and two of them were not themes"):format(#Themes.Own()))

local repaired = Themes.Own()[1]
check(repaired.elements.nosuch == nil, "the load kept a cell for something that is not an element")
for _, element in ipairs(Themes.ELEMENTS) do
	local cell = repaired.elements[element.key]
	check(type(cell) == "table" and type(cell.alpha) == "number",
		("the load left %s without a cell of its own"):format(element.key))
end
check(repaired.elements.chat.alpha == 1 and not repaired.elements.chat.hover,
	"a cell written as a word came back as something other than as drawn")
check(repaired.rail == nil, "the load kept a rail style that is not one of the two")
check(Themes.Own()[2].name ~= repaired.name,
	"two themes came out of the load under one name, so one of them cannot be reached")

ns.db.themes = {}
ns.db.theme = "informational"
chat:Hide()
feeds:Hide()
buffs:Hide()
player:Hide()

-- The list is named rather than counted, because it is a work list: an element
-- on it is one no part draws while the frames are unlocked, and each one that
-- learns to preview itself comes off this line.
print(("themes  one of your own copied from exploration cell for cell, its fight"
	.. " fraction on the pull and off at the end, a saved file of four themes"
	.. " loaded as two that name every element, and %d of %d elements reached"
	.. " by a chip rather than a rim: %s")
	:format(#chipped, #Themes.ELEMENTS, table.concat(chipped, ", ")))
