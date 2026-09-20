local ADDON, ns = ...

local UI = ns.UI
local C = UI.Color
local Themes = ns.Themes

local ThemeEdit = {}
ns.ThemeEdit = ThemeEdit

--------------------------------------------------------------------------
-- Making a theme by pointing at the screen
--
-- Theme/Custom.lua holds the list and Theme/Theme.lua draws whichever theme is
-- chosen. This is the page you make one on, and it is two halves that answer
-- the same question from opposite ends.
--
-- The page half is the one every other setting in this addon uses: a strip of
-- your themes across the top, a dropdown of the twenty-three elements, and
-- three dials under it. That half is complete on its own. You could sit in the
-- options window and build a whole theme from the dropdown without ever
-- looking at the game.
--
-- Nobody would. "the quest tracker" and "the standing row" are words for
-- rectangles, and which rectangle each one is, is a thing you know by looking.
-- So the other half puts a rim and a name round every element on the screen at
-- once, the way unlocking the frames does before you drag them, and a click on
-- one is the same choice the dropdown makes. Point at the thing you want
-- dimmer; the dials underneath are about that thing.
--
-- Two rules hold the pair together.
--
-- **Everything is up while you are picking.** An element the theme hides is an
-- element you cannot point at, so the rims go up over a screen where nothing
-- is hidden and nothing is faint. That is ns.Theme.Showcase, and it is the
-- state /wui unlock already puts the frames in for dragging.
--
-- **The theme is on the screen while you edit it.** ns.Theme.Try draws the
-- record being edited over the drawn theme for as long as the page holds it,
-- so the button that takes the rims away is not a preview in a separate
-- window: it is the screen, now, with your theme on it. Closing the page puts
-- back what was there before.
--
-- The one thing the page cannot do is a fight. Showing an element the theme
-- had hidden is a protected write, so the client refuses it mid pull, and a
-- creator that opened anyway would draw rims round half a screen.
--------------------------------------------------------------------------

-- Over the elements and under the options window, which is on DIALOG. A rim
-- has to sit above whatever the element draws inside itself, and below the
-- window holding the dials it is about.
local MARK_STRATA = "HIGH"
local MARK_LEVEL = 200

-- The name above a rim, in units of the frame it hangs off, which is the gap
-- UI/Placeable.lua leaves above a frame being dragged.
local TITLE_GAP = 2

-- How solid the wash over an element is: the one you have chosen, and the rest.
local PICKED_WASH = 0.22
local WASH = 0.06

--------------------------------------------------------------------------
-- What the page is looking at
--------------------------------------------------------------------------

-- The theme whose tab is up, the element chosen, whether the rims are on the
-- screen, and every rim made so far, one per worn frame.
local shown, picked, editing = 1, nil, false
local marks, order = {}, {}

local function Current()
	return Themes.Own()[shown]
end

local function Label(key)
	for _, element in ipairs(Themes.ELEMENTS) do
		if element.key == key then
			return element.label
		end
	end
	return key
end

-- The element the dials are about. The first on the list until somebody picks
-- one, so the page never has a dial with nothing behind it.
local function Chosen()
	if not picked then
		picked = Themes.ELEMENTS[1].key
	end
	return picked
end

-- The cell the dials read and write, or nil when there is no theme of your own
-- to write into. Every getter below answers something harmless for the nil and
-- every setter does nothing, so the page draws the same whether or not you
-- have made a theme yet.
local function Cell()
	local theme = Current()
	return theme and theme.elements[Chosen()] or nil
end

local function Percent(fraction)
	return math.floor(fraction * 100 + 0.5)
end

--------------------------------------------------------------------------
-- The rims
--------------------------------------------------------------------------

local function Paint(mark)
	local on = mark.wuiElement == picked
	mark.wash:SetAlpha(on and PICKED_WASH or WASH)
	ns.Recolor(mark.edges, on and C.accent or C.edge)
	local text = on and C.heading or C.dim
	mark.text:SetTextColor(text[1], text[2], text[3])
end

local function Repaint()
	for index = 1, #order do
		Paint(order[index])
	end
end

local function Picked(mark)
	ThemeEdit.Pick(mark.wuiElement)
end

-- One rim over one worn frame. A child of the frame, so it follows it wherever
-- the part that owns it puts it and through every resize, and raised over the
-- frame's own children, so the pointer finds the rim and not a bar square.
local function Rim(key, frame)
	if marks[frame] then
		return
	end
	local mark = CreateFrame("Button", nil, frame)
	mark:SetAllPoints(frame)
	mark:SetFrameStrata(MARK_STRATA)
	mark:SetFrameLevel(MARK_LEVEL)
	mark.wuiElement = key

	mark.wash = ns.Fill(mark, "BACKGROUND", C.accent[1], C.accent[2], C.accent[3], WASH)
	mark.wash:SetAllPoints()
	mark.edges = ns.Outline(mark, C.edge[1], C.edge[2], C.edge[3], 1)
	ns.EdgeSize(mark.edges, ns.Pixel(mark))

	-- At the outline floor and carrying a rim, for UI/Placeable.lua's reason:
	-- this is drawn over the world rather than on a panel, and a stroke that
	-- has to buy an edge out of its own weight closes up its counters.
	mark.text = UI.Label(mark, UI.OutlineFloor(), C.dim, "LEFT", UI.OUTLINE)
	mark.text:SetPoint("BOTTOMLEFT", mark, "TOPLEFT", 0, TITLE_GAP * UI.Unit(mark))
	mark.text:SetText(Label(key))

	UI.Press.Clicks(mark, "up")
	mark:SetScript("OnClick", Picked)
	mark:Hide()

	marks[frame] = mark
	order[#order + 1] = mark
	Paint(mark)
end

-- A rim for every frame worn so far, made once each. Run whenever the page is
-- refreshed as well as when it opens, because a part builds its frame the
-- first time it is needed: the map and the character sheet are not on the
-- screen at login and are worn when they first open.
local function Rims()
	ns.Theme.Worn(Rim)
end

local function ShowRims(on)
	for index = 1, #order do
		order[index]:SetShown(on)
	end
end

--------------------------------------------------------------------------
-- Opening and closing the page
--------------------------------------------------------------------------

-- The theme being edited put back on the screen, which is what a dial moving
-- redraws through. Nothing happens unless the page has a theme open: the dials
-- write into the saved record either way, and that record is drawn at the next
-- reload like any other theme.
function ThemeEdit.Redraw()
	if editing then
		ns.Theme.Try(Current())
	end
end

function ThemeEdit.Editing()
	return editing and Current() or nil
end

-- Take the theme whose tab is up onto the screen, with a rim round every
-- element. Answers false and says why where the client will not have it.
function ThemeEdit.Start()
	local theme = Current()
	if not theme then
		return false
	end
	if InCombatLockdown() then
		ns.Print("not in a fight: the screen cannot put an element back up mid pull.")
		return false
	end
	editing, picked = true, Chosen()
	ns.Theme.Try(theme)
	ns.Theme.Showcase(true)
	Rims()
	ShowRims(true)
	return true
end

-- Put the screen back. Called by the button, by the tab strip before it opens
-- another theme, and by the options window closing, which is the way out
-- nobody presses a button for.
function ThemeEdit.Stop()
	if not editing then
		return
	end
	editing = false
	ShowRims(false)
	ns.Theme.Showcase(false)
	ns.Theme.Try(nil)
end

-- The rims away and the theme drawn as it will be drawn, or back to picking.
-- The same theme either way: this is not a preview window, it is the screen
-- with the rims lifted off it.
function ThemeEdit.Showcase(on)
	if not editing then
		return
	end
	ShowRims(on)
	ns.Theme.Showcase(on)
end

function ThemeEdit.Pick(key)
	picked = key
	Repaint()
	ns.Options.Refresh()
end

--------------------------------------------------------------------------
-- Making, renaming and dropping one
--------------------------------------------------------------------------

local function Made(name)
	local index, why = Themes.Make(name, ns.db.theme)
	if not index then
		ns.Print(why)
		return
	end
	ThemeEdit.Stop()
	shown = index
	ns.Options.Refresh()
end

function ThemeEdit.Add()
	if #Themes.Own() >= Themes.MAX_OWN then
		ns.Print(("%d themes of your own is the limit."):format(Themes.MAX_OWN))
		return
	end
	UI.Name({
		title = "A theme of your own",
		note = "Name it for when you would wear it: raid nights, questing, the screen you want while you fish.",
		accept = "make it",
		onAccept = Made,
	})
end

local function Dropped()
	local theme = Current()
	if not theme then
		return
	end
	ThemeEdit.Stop()
	Themes.Drop(shown)
	if shown > #Themes.Own() then
		shown = math.max(#Themes.Own(), 1)
	end
	ns.Options.Refresh()
end

function ThemeEdit.Remove()
	local theme = Current()
	if not theme then
		return
	end
	UI.Ask({
		title = "Delete this theme",
		question = ("%s and everything you set on it. The three the addon ships with are not touched."):format(theme.name),
		accept = "delete it",
		onAccept = Dropped,
	})
end

local function Choose(index)
	if index == shown then
		return
	end
	local was = editing
	ThemeEdit.Stop()
	shown = index
	if was then
		ThemeEdit.Start()
	end
end

--------------------------------------------------------------------------
-- The page
--------------------------------------------------------------------------

local function Names()
	local names = {}
	for index, theme in ipairs(Themes.Own()) do
		names[index] = theme.name
	end
	return names
end

local function Elements()
	local options = {}
	for index, element in ipairs(Themes.ELEMENTS) do
		options[index] = { value = element.key, text = element.label }
	end
	return options
end

-- One dial: read it off the cell, write it back, and redraw the screen if the
-- theme is on it. Every control below is one of these, which is why none of
-- them says anything about drawing.
local function Wrote()
	Rims()
	ThemeEdit.Redraw()
end

local function Alpha()
	local cell = Cell()
	return cell and Percent(cell.alpha) or 100
end

local function SetAlpha(value)
	local cell = Cell()
	if cell then
		cell.alpha = value / 100
		Wrote()
	end
end

local function Hover()
	local cell = Cell()
	return cell and cell.hover or false
end

local function SetHover(value)
	local cell = Cell()
	if cell then
		cell.hover = value and true or false
		Wrote()
	end
end

local function Fights()
	local cell = Cell()
	return cell ~= nil and cell.combat ~= nil
end

-- Turning it on starts the fight at whatever the element is drawn at out of
-- one, so the tick box alone changes nothing on the screen and the dial under
-- it is what says what a fight does. Turning it off takes the field away
-- rather than setting it equal, because equal is a cell that redresses every
-- pull for no reason.
local function SetFights(value)
	local cell = Cell()
	if cell then
		cell.combat = value and cell.alpha or nil
		Wrote()
	end
end

local function CombatAlpha()
	local cell = Cell()
	return cell and Percent(cell.combat or cell.alpha) or 100
end

local function SetCombatAlpha(value)
	local cell = Cell()
	if cell then
		cell.combat = value / 100
		Wrote()
	end
end

local function Has()
	return Current() ~= nil
end

local function Renamed(value)
	if not Current() then
		return
	end
	local ok, why = Themes.Rename(shown, value)
	if not ok and why then
		ns.Print(why)
	end
end

function ThemeEdit.Panel(ui)
	ui.Section("A theme of your own", "On and off")
	ui.Lede("The same elements, with the answers written by you. Press edit and every one of them wears a rim: click the one you mean and set it here.")

	ui.Tabs(Names, function() return shown end, Choose, { onAdd = ThemeEdit.Add })

	ui.TextField("name", function()
		local theme = Current()
		return theme and theme.name or ""
	end, Renamed)

	ui.ActionPair(
		function() return editing and "stop editing" or "edit it on the screen" end,
		function()
			if editing then
				ThemeEdit.Stop()
			else
				ThemeEdit.Start()
			end
		end,
		Has,
		function() return "delete it" end,
		ThemeEdit.Remove,
		Has)
	ui.Hint("Editing draws your theme on the screen as you build it, with everything held up so you can point at it. The window closing stops it.")

	ui.Action(function()
		return ns.Theme.Showcasing() and "take the rims off and look at it" or "back to picking"
	end, function()
		ThemeEdit.Showcase(not ns.Theme.Showcasing())
	end, function() return editing end)

	ui.Picker("element", Chosen, ThemeEdit.Pick, Elements)
	ui.Opacity("drawn at", Alpha, SetAlpha)
	ui.Hint("Nought takes it off the screen, the way the immersive theme does. Anything above that draws it faintly, and it still answers the mouse.")

	ui.Check("full under the pointer", Hover, SetHover)
	ui.Hint("The element rests at the fraction above and comes to full while the pointer is on it, the way exploration keeps the chat window.")

	ui.Check("different while you are fighting", Fights, SetFights)
	ui.Opacity("drawn at, in a fight", CombatAlpha, SetCombatAlpha)
	ui.Hint("An element that differs in a fight is dimmed rather than taken away: the client will not put a protected frame back up mid pull. At nought it is invisible and still takes the mouse.")

	ui.Gap()
	ui.Heading("What this theme does")
	for _, element in ipairs(Themes.ELEMENTS) do
		ui.Reading(element.label, function()
			local theme = Current()
			if not theme then
				return "no theme of your own yet"
			end
			return ns.Theme.Describe(theme.elements, element.key)
		end)
	end
end
