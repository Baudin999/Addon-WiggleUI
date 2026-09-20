local ADDON, ns = ...

local UI = ns.UI
local C, M = UI.Color, UI.Metric
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
-- **Picking unlocks the frames.** It does not do something that looks like
-- unlocking them; it is the same state, set the same way, `ns.db.locked` false
-- and `ns.Each("lock")`. That matters because unlocking is not only the theme
-- letting go: it is what makes six parts draw themselves when they have
-- nothing to draw. The cast bar invents a cast, the buff nag shows a preview,
-- the swing bars come up empty, because a rectangle you cannot see is a
-- rectangle you cannot drag, which is the same sentence with "point at" in it.
--
-- The first cut of this page had a held-up state of its own, and the result
-- was a screen where the cast bar was missing from a page that claimed to show
-- you every element. Two states that mean the same thing are one state and a
-- bug waiting for whichever of them somebody forgets.
--
-- **The theme is on the screen while you edit it.** ns.Theme.Try draws the
-- record being edited over the drawn theme for as long as the page holds it,
-- so the button that takes the rims away is not a preview in a separate
-- window: it is the screen, now, with your theme on it. Closing the page puts
-- back what was there before.
--
-- Four elements are still not there once the frames are unlocked, and that is
-- the third piece. The drops and the messages sliding in are pooled rows that
-- exist while one is sliding and not otherwise; the loadout ring is up while
-- its key is held; the floating numbers are the same. None of those four reads
-- the lock, so none of them previews itself, and a rim can only sit on a frame
-- that is drawn. They are chips in a tray at the top of the screen instead,
-- one per element with nothing drawn, clicked the same way a rim is. The tray
-- is the page saying which elements it cannot show you rather than saying
-- nothing, and it empties itself as each of those four learns to preview.
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

-- The tray of elements that are not on the screen to be pointed at. Under the
-- top edge rather than over the middle, because the middle is where the
-- elements you can point at are.
local TRAY_TOP = -120
local TRAY_WIDTH = 560
local CHIP_PAD = 6

--------------------------------------------------------------------------
-- What the page is looking at
--------------------------------------------------------------------------

-- The theme whose tab is up, the element chosen, whether the rims are on the
-- screen, and every rim made so far, one per worn frame.
local shown, picked, editing = 1, nil, false

-- Whether the rims are up, and whether the frames were locked before the page
-- unlocked them. Put back on the way out: somebody who was already dragging
-- frames when they opened this is not relocked by closing it.
local picking, wasLocked = false, true
local marks, order = {}, {}

-- The tray and its chips, and the set of elements that have a frame on the
-- screen this moment, filled by NoteDrawn below and read by the tray's layout.
local tray, chips, drawn = nil, {}, {}

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

-- The half a rim and a chip paint the same way: the edge and the name say
-- which one you have chosen. They differ only in their surface, because a rim
-- lies over something you are looking at and a chip stands for something you
-- cannot see.
local function Marked(target)
	local on = target.wuiElement == picked
	ns.Recolor(target.edges, on and C.accent or C.edge)
	local text = on and C.heading or C.dim
	target.text:SetTextColor(text[1], text[2], text[3])
	return on
end

local function Paint(mark)
	mark.wash:SetAlpha(Marked(mark) and PICKED_WASH or WASH)
end

local function PaintChip(chip)
	UI.Tint(chip.wash, Marked(chip) and C.selected or C.chrome)
end

local function Repaint()
	for index = 1, #order do
		Paint(order[index])
	end
	for index = 1, #chips do
		if chips[index]:IsShown() then
			PaintChip(chips[index])
		end
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

--------------------------------------------------------------------------
-- The tray
--------------------------------------------------------------------------

local function Tray()
	if tray then
		return tray
	end
	tray = CreateFrame("Frame", nil, UIParent)
	tray:SetFrameStrata(MARK_STRATA)
	tray:SetFrameLevel(MARK_LEVEL)
	tray:SetPoint("TOP", UIParent, "TOP", 0, TRAY_TOP)
	tray.title = UI.Label(tray, UI.OutlineFloor(), C.quiet, "CENTER", UI.OUTLINE)
	tray.title:SetPoint("BOTTOM", tray, "TOP", 0, TITLE_GAP * UI.Unit(tray))
	tray.title:SetText("not on the screen just now")
	tray:Hide()
	return tray
end

local function Chip(index)
	local chip = chips[index]
	if chip then
		return chip
	end
	chip = CreateFrame("Button", nil, Tray())
	chip.wash = ns.Fill(chip, "BACKGROUND", C.chrome[1], C.chrome[2], C.chrome[3], 1)
	chip.wash:SetAllPoints()
	chip.edges = ns.Outline(chip, C.edge[1], C.edge[2], C.edge[3], 1)
	ns.EdgeSize(chip.edges, ns.Pixel(chip))
	chip.text = UI.Label(chip, UI.OutlineFloor(), C.dim, "CENTER", UI.OUTLINE)
	chip.text:SetPoint("CENTER")
	UI.Wrap(chip.text, false)
	UI.Press.Clicks(chip, "up")
	chip:SetScript("OnClick", Picked)
	chips[index] = chip
	return chip
end

-- Which elements have a frame the pointer could land on. A frame the theme
-- has taken down is visible here, because the tray is only ever read while
-- everything is held up; a frame its own part has not drawn is not, which is
-- exactly the four this tray exists for.
local function NoteDrawn(key, frame)
	if frame:IsVisible() then
		drawn[key] = true
	end
end

-- One chip per element with nothing on the screen, laid left to right and
-- wrapped, and the tray away entirely when every element can be pointed at.
local function LayTray()
	for key in pairs(drawn) do
		drawn[key] = nil
	end
	ns.Theme.Worn(NoteDrawn)

	Tray()
	local at, x, y = 0, 0, 0
	for _, element in ipairs(Themes.ELEMENTS) do
		if not drawn[element.key] then
			at = at + 1
			local chip = Chip(at)
			chip.wuiElement = element.key
			chip.text:SetText(element.label)
			local width = (chip.text:GetStringWidth() or 0) + CHIP_PAD * 2
			if x > 0 and x + width > TRAY_WIDTH then
				x, y = 0, y + M.row + M.rowGap
			end
			chip:SetSize(math.max(width, 1), M.row)
			chip:ClearAllPoints()
			chip:SetPoint("TOPLEFT", tray, "TOPLEFT", x, -y)
			chip:Show()
			PaintChip(chip)
			x = x + width + M.rowGap
		end
	end
	for index = at + 1, #chips do
		chips[index]:Hide()
	end
	tray:SetSize(TRAY_WIDTH, y + M.row)
	tray.wuiFull = at > 0
end

--------------------------------------------------------------------------

-- A rim for every frame worn so far, made once each, and a chip for every
-- element none of them draws. Run whenever the page is refreshed as well as
-- when it opens, because a part builds its frame the first time it is needed:
-- the map and the character sheet are not on the screen at login and are worn
-- when they first open, and a cast bar comes and goes while you are editing.
local function Rims()
	ns.Theme.Worn(Rim)
	LayTray()
end

local function ShowRims(on)
	for index = 1, #order do
		order[index]:SetShown(on)
	end
	if tray then
		tray:SetShown(on and tray.wuiFull or false)
	end
end

--------------------------------------------------------------------------
-- Opening and closing the page
--------------------------------------------------------------------------

-- The frames unlocked, or put back to whatever the player had them at. The
-- same two lines the button in the window's footer runs, because this is the
-- same state and not one that looks like it: every part that previews itself
-- while the frames are unlocked reads ns.db.locked, and ns.Each("lock") is
-- what tells them to look again.
local function Unlock(on)
	local want = not on and wasLocked or false
	if ns.db.locked == want then
		return
	end
	ns.db.locked = want
	ns.Each("lock")
end

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
	wasLocked = ns.db.locked ~= false
	ns.Theme.Try(theme)
	-- Through the same call the button below runs, rather than a second copy
	-- of its four lines here: one place decides what picking means.
	ThemeEdit.Picking(true)
	return true
end

-- Put the screen back. Called by the button, by the tab strip before it opens
-- another theme, and by the options window closing, which is the way out
-- nobody presses a button for.
function ThemeEdit.Stop()
	if not editing then
		return
	end
	editing, picking = false, false
	ShowRims(false)
	Unlock(false)
	ns.Theme.Try(nil)
end

-- The rims away and the theme drawn as it will be drawn, or back to picking.
-- The same theme either way: this is not a preview window, it is the screen
-- with the rims lifted off it.
function ThemeEdit.Picking(on)
	if not editing then
		return
	end
	picking = on and true or false
	-- The screen first, then the rims, because which elements have nothing on
	-- the screen is read off the screen: laid out before everything came back
	-- up, the tray would carry a chip for every element the theme hides.
	Unlock(picking)
	if picking then
		Rims()
	end
	ShowRims(picking)
end

-- The chip standing in for an element, or nil where the element has a frame on
-- the screen and wears a rim instead. Public for the reason UI.Asking is: the
-- page has to be answerable from outside, and it is the only way a test can
-- see a chip without this file handing out its own tables.
function ThemeEdit.Chip(key)
	for index = 1, #chips do
		local chip = chips[index]
		-- Visible rather than shown: a chip keeps its own flag when the tray
		-- goes, and a chip nobody can see is not standing in for anything.
		if chip:IsVisible() and chip.wuiElement == key then
			return chip
		end
	end
	return nil
end

function ThemeEdit.Pick(key)
	picked = key
	Repaint()
	ns.Options.Refresh()
end

function ThemeEdit.Picked()
	return Chosen()
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
	ThemeEdit.Redraw()
	Rims()
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

--------------------------------------------------------------------------
-- The rail, which is the one element with a second question
--------------------------------------------------------------------------

-- The row for "whatever the setting outside this theme says", which is what a
-- theme that does not decide the rail means. A word rather than nil, because a
-- dropdown row has to carry a value and nil is not one.
local SETTING = "as the setting says"

local function Rails()
	local options = { { value = SETTING, text = SETTING } }
	for _, style in ipairs(Themes.RAILS) do
		options[#options + 1] = { value = style, text = style }
	end
	return options
end

local function Rail()
	local theme = Current()
	return theme and theme.rail or SETTING
end

local function SetRail(value)
	local theme = Current()
	if theme then
		theme.rail = value ~= SETTING and value or nil
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
		return picking and "take the rims off and look at it" or "back to picking"
	end, function()
		ThemeEdit.Picking(not picking)
	end, function() return editing end)

	ui.Picker("element", Chosen, ThemeEdit.Pick, Elements)
	ui.Opacity("drawn at", Alpha, SetAlpha)
	ui.Hint("Nought takes it off the screen, the way the immersive theme does. Anything above that draws it faintly, and it still answers the mouse.")

	ui.Check("full under the pointer", Hover, SetHover)
	ui.Hint("The element rests at the fraction above and comes to full while the pointer is on it, the way exploration keeps the chat window.")

	ui.Check("different while you are fighting", Fights, SetFights)
	ui.Opacity("drawn at, in a fight", CombatAlpha, SetCombatAlpha)
	ui.Hint("An element that differs in a fight is dimmed rather than taken away: the client will not put a protected frame back up mid pull. At nought it is invisible and still takes the mouse.")

	ui.Picker("the experience rail", Rail, SetRail, Rails)
	ui.Hint("The one element with a second question: minimal is a hairline along the bottom edge rather than a fainter version of the placed rail with its reading on it.")

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
