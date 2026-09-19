local ADDON, ns = ...

-- Where the addon sits in the client's own menu.
--
-- Everything in here answers one complaint: a slash command is a thing you have
-- to be told about. Escape is a thing everyone already presses. So the addon
-- puts one button in that menu, it says WarriorKit, and it opens the same panel
-- /wk opens. No setting guards it, because a checkbox that hides the way into
-- the settings is a checkbox nobody can find their way back to.
--
-- The button goes in the menu's own column, under Options, and Blizzard's
-- layout puts it there. That is the third attempt and the first that is the
-- client's mechanism rather than one of ours.
--
-- The first read the menu's anchor chain and re-anchored its foot to our
-- button. The client relays that column on every show, so the placement came
-- undone in front of you and on every other press of Escape the button was
-- gone. The second gave up on the column, hung the button off the frame's
-- bottom edge and grew the frame by its height. That one held, and it put the
-- way into the addon under Return to Game, where nothing that is not closing
-- the menu belongs.
--
-- Both clients build this menu from MainMenuFrameTemplate, which is a
-- VerticalLayoutFrame (Blizzard_SharedXML/Classic/Frame/MainMenuFrameTemplates.xml
-- on the classic_anniversary and classic_era branches of Gethe/wow-ui-source).
-- Its Layout takes every shown child carrying a layoutIndex, sorts them by it
-- and stacks them; Blizzard's own buttons get 1, 2, 3 from AddButton on every
-- show. So ours carries the index of Options plus a half. No anchor of ours,
-- no height of ours, nothing of Blizzard's touched: the client's own pass puts
-- the button in the column and sizes the frame round it, and it does that on
-- the frame after InitButtons, which is after the OnShow hook below.
--
-- The one thing still read off the menu is a button to copy a size from, and
-- that is cosmetic: a size we cannot measure leaves the kit's own.
--
-- The paint is Core/MenuSkin.lua and it is a second subject rather than a
-- second half of this one. That file draws the whole menu in the kit's look,
-- on a switch, and sets the column's padding; this file owns the button and
-- where it goes in the column, and neither goes looking through the other.

local Menu = {}
ns.GameMenu = Menu

local LABEL = "WarriorKit"
local BUTTON = "WarriorKitGameMenuButton"

-- How far past the button it follows ours sorts. Blizzard numbers its column in
-- whole steps, so a half never collides with one of theirs, and LayoutFrame
-- raises on a duplicate index.
local AFTER = 0.5

-- How far apart the buttons a part adds with Menu.Add sort, after ours and
-- still short of Blizzard's next whole step, so they sit together under it.
-- Four fit: a fifth would reach the next whole number and collide.
local STEP = 0.1
local MOST = 4

-- Above whatever the menu draws inside itself. Ours is a child of the menu and
-- the menu may hold a container with its own level, and a button behind the
-- frame it sits on is a button you cannot click. Ten is past anything one of
-- these frames stacks inside itself.
local LIFT = 10

-- How many regions `/wk menu` lists before it stops. A menu with more than this
-- in it is a menu somebody else has already filled, which is worth knowing and
-- is not worth thirty lines of chat.
local PROBE_LIST = 16

-- The button, and why there is not one. Exactly one of the two is set.
local button, refusal

-- The ways in a part adds under ours, as it asked for them and then as built.
-- `mine` is every button of ours in the column, the first included, which is
-- what the size copy and the paint both have to step over.
local asked, extra, mine = {}, {}, {}

-- What the last attach found to copy a size from. Carried for `/wk status`,
-- because a button at the kit's own size in a menu whose buttons are a
-- different size is a thing you can see and would want explained.
local copied

-- One anchor off a frame the addon does not own.
--
-- ns.Measure is the house call for this and takes no arguments and returns one
-- value, and an anchor is an index in and five values out. Same contract
-- though: a restricted frame raises rather than answering, and the answer to
-- that is nil, not a screenful of errors.
local function Anchor(frame)
	if not frame or type(frame.GetPoint) ~= "function" then
		return nil
	end
	local ok, point, relative, relativePoint, x, y = pcall(frame.GetPoint, frame, 1)
	if not ok then
		return nil
	end
	return point, relative, relativePoint, x or 0, y or 0
end

-- Any one of the menu's own buttons, for its size and nothing else.
--
-- One level down as well as the menu itself, because a menu that keeps its
-- column in a container of its own is a shape this has already met. One level
-- rather than the whole tree: the whole tree of somebody else's frame is a walk
-- with no bottom to it, and the prize here is a width.
local function Sibling(menu)
	for _, child in ipairs({ menu:GetChildren() }) do
		if not mine[child] and ns.Measure(child, "GetObjectType") == "Button"
			and ns.Measure(child, "IsShown") then
			return child
		end
		for _, inner in ipairs({ child:GetChildren() }) do
			if not mine[inner] and ns.Measure(inner, "GetObjectType") == "Button"
				and ns.Measure(inner, "IsShown") then
				return inner
			end
		end
	end
	return nil
end

local function Fit(menu)
	local twin = Sibling(menu)
	copied = twin and (ns.Measure(twin, "GetName") or "an unnamed button") or nil
	if not twin then
		return
	end
	local width, height = ns.Measure(twin, "GetWidth"), ns.Measure(twin, "GetHeight")
	if width and height and width > 0 and height > 0 then
		for entry in pairs(mine) do
			entry:SetSize(width, height)
		end
	end
end

-- Where ours sorts in the column: after Options, after Blizzard's first button
-- on a menu without one, and first on a menu with nothing in it yet.
--
-- Options is matched by the client's own string, so the match holds in every
-- locale, and read at the call because GlobalStrings is the client's to fill.
local function Slot(menu)
	local label = _G.GAMEMENU_OPTIONS
	local first, follows
	for entry in menu.buttonPool:EnumerateActive() do
		local index = entry.layoutIndex
		if index then
			first = math.min(first or index, index)
			if label and ns.Measure(entry, "GetText") == label then
				follows = index
			end
		end
	end
	return (follows or first or 0) + AFTER
end

-- Put the button in the column, from whatever state the menu is in.
--
-- Run at login and again on every show, because InitButtons hands the column
-- out afresh on every show and the index ours follows can move with it: the
-- event button above Options comes and goes with the calendar.
function Menu.Attach()
	local menu = _G.GameMenuFrame
	if not button or not menu then
		return false
	end

	-- The paint first, because it takes Blizzard's own art off the buttons the
	-- next line measures, and a button is the same size either way. Its answer
	-- is not tested here: a menu that could not be painted is still a menu our
	-- button goes in, and the refusal it carries is reported on its own line.
	ns.MenuSkin.Apply()

	local pool = menu.buttonPool
	if type(pool) ~= "table" or type(pool.EnumerateActive) ~= "function" then
		refusal = "this client's game menu keeps no column to join"
		for entry in pairs(mine) do
			entry:Hide()
		end
		return false
	end

	Fit(menu)
	local slot = Slot(menu)
	local level = (ns.Measure(menu, "GetFrameLevel") or 0) + LIFT
	button.layoutIndex = slot
	for index, entry in ipairs(extra) do
		entry.layoutIndex = slot + index * STEP
	end
	for entry in pairs(mine) do
		entry:SetFrameLevel(level)
		entry:Show()
	end

	refusal = nil
	return true
end

-- One of our buttons in the column: the kit's look, and a press that closes
-- the menu before it opens what it names.
local function Entry(menu, name, label, tip, open)
	return ns.UI.Button(menu, {
		name = name,
		label = label,
		size = ns.UI.Metric.font,
		tip = tip,
		onClick = function()
			-- Closed the way Escape closes it, so the client takes it off its
			-- own panel stack. Hide alone leaves the stack believing it is
			-- still up.
			if type(HideUIPanel) == "function" then
				HideUIPanel(menu)
			else
				menu:Hide()
			end
			open()
		end,
	})
end

local function Build()
	local menu = _G.GameMenuFrame
	if not menu then
		refusal = "this client has no game menu to add to"
		return
	end

	-- The addon's own button, not the client's.
	--
	-- It was built on GameMenuButtonTemplate, and a button wearing Blizzard's
	-- gold-on-parchment art in a menu you open to reach a window painted in
	-- this addon's greys reads as somebody else's. The kit button is the same
	-- one the close box and every stepper in the window is, so the way in looks
	-- like the place it leads to. Fit still copies the column's width so ours
	-- lines up with the buttons above it; only the paint changed.
	button = Entry(menu, BUTTON, LABEL,
		"The addon's own window: what it draws, and every number it draws it with.",
		ns.Options.Show)
	mine[button] = true
	local ours = { button }
	for index, entry in ipairs(asked) do
		extra[index] = Entry(menu, entry.name, entry.label, entry.tip, entry.open)
		mine[extra[index]] = true
		ours[#ours + 1] = extra[index]
	end

	ns.MenuSkin.Watch(menu, ours)
end

-- A second way in, added by the part it leads to, so the base never names a
-- feature. Called at file load, before PLAYER_LOGIN builds the column; the
-- button sorts under ours in the order the parts asked.
--
--   name   the global the button is built under
--   label  its words
--   tip    what the hover says
--   open   called after the menu has closed
function Menu.Add(entry)
	assert(not button, "a game menu button was added after the menu was built")
	assert(#asked < MOST, "the game menu has no room under ours for another button")
	assert(type(entry.open) == "function", "a game menu button was added with nothing to open")
	asked[#asked + 1] = entry
end

function Menu.Describe()
	if refusal then
		return refusal
	end
	if not button then
		return "not built"
	end
	return ("in the game menu's column under Options, %s, %s"):format(
		copied and ("the size of " .. copied) or "at the kit's own size",
		ns.MenuSkin.Describe())
end

-- What the client's menu is actually made of.
--
-- This is the only part of the addon whose success depends on the shape of
-- somebody else's frame, and the shape has changed under it once already. So
-- there is a way to look at it that is not reading this file and guessing. Same
-- job `/wk skin probe` does for the aura buttons and for the same reason.
local function Say(region, indent)
	local _, relative = Anchor(region)
	ns.Print(("%s%s %s%s, %s wide, hangs off %s"):format(
		indent,
		tostring(ns.Measure(region, "GetObjectType")):lower(),
		ns.Measure(region, "GetName") or "unnamed",
		ns.Measure(region, "IsShown") and "" or " (hidden)",
		tostring(ns.Measure(region, "GetWidth")),
		relative and (ns.Measure(relative, "GetName") or "an unnamed frame")
			or "nothing"))
end

function Menu.Probe()
	local menu = _G.GameMenuFrame
	if not menu then
		ns.Print("game menu: this client has no GameMenuFrame at all.")
		return
	end

	ns.Print(("game menu: %s tall, %s"):format(
		tostring(ns.Measure(menu, "GetHeight")), Menu.Describe()))
	ns.Print("  paint: " .. ns.MenuSkin.Describe() .. ".")
	ns.Print(("  our button %s, AddButton %s, Layout %s, HookScript %s"):format(
		button and "built" or "not built",
		type(menu.AddButton) == "function" and "yes" or "no",
		type(menu.Layout) == "function" and "yes" or "no",
		type(menu.HookScript) == "function" and "yes" or "no"))

	local children, lines = 0, 0
	for _, child in ipairs({ menu:GetChildren() }) do
		children = children + 1
		if lines < PROBE_LIST then
			lines = lines + 1
			Say(child, "  ")
		end
		for _, inner in ipairs({ child:GetChildren() }) do
			if lines < PROBE_LIST then
				lines = lines + 1
				Say(inner, "    ")
			end
		end
	end
	ns.Print(("  %d children of the menu, %d regions listed."):format(children, lines))
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	Build()
	if not button then
		return
	end
	Menu.Attach()
	local menu = _G.GameMenuFrame
	if type(menu.HookScript) == "function" then
		menu:HookScript("OnShow", Menu.Attach)
	end
end)

local function Set(value)
	ns.db.menuSkin = value
	ns.MenuSkin.Apply()
end

-- One word that does two things, and the argument is what tells them apart.
-- `menu` on its own is the probe, which is what you type when the button has
-- not turned up. `menu on` and `menu off` are the paint.
--
-- The button itself has no switch and will not get one, for the reason at the
-- head of this file: a checkbox that hides the way into the settings is a
-- checkbox nobody can find their way back to. The paint is a different
-- question. It is a look rather than a way in, somebody will want Blizzard's
-- own back, and it goes back in one call.
ns.Register({
	name = "menu",
	order = 22,

	defaults = {
		-- True means the client's menu is drawn in the addon's look, which is
		-- the point of Core/MenuSkin.lua and so the state it starts in.
		menuSkin = true,
	},

	-- Drawn by the panel, at the top of the page below, like every other part's.
	-- The button in the menu is not on it and never will be: that one is the
	-- way into this window, and a switch that hides the way in is a switch
	-- nobody can find their way back to. This is the paint.
	switch = {
		key = "menuSkin",
		label = "the game menu in the addon's look",
		says = "No button is replaced, so Logout and Exit Game are still Blizzard's own. The paint and the column's spacing change, and both come off in one call.",
		apply = function() ns.MenuSkin.Apply() end,
	},

	words = {
		menu = function(arg)
			if arg == nil then
				Menu.Probe()
				return
			end
			Set(ns.Command.Toggle(arg))
			ns.Print("The game menu is drawn "
				.. (ns.db.menuSkin and "in the addon's look" or "the client's own way")
				.. ", " .. Menu.Describe() .. ".")
		end,
	},

	help = {
		"menu, what the client's own menu is made of and where our button went",
		"menu on|off, the client's menu in the addon's look or in its own",
	},

	status = function()
		return Menu.Describe()
	end,

	reset = function()
		Set(ns.DefaultFor("menuSkin"))
	end,

	panel = function(ui)
		ui.Section("Game menu", "The screen")
		ui.Lede("The menu Escape opens, drawn in this addon's palette rather than the client's parchment.")
		ui.Reading("game menu", ns.MenuSkin.Describe)
	end,
})
