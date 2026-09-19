-- The client's own menu, and what the addon does to it
--
-- Two files. Core/Menu.lua puts one button in Blizzard's game menu, in the
-- column under Options, by giving it a layoutIndex and letting the client's own
-- layout pass place it. Core/MenuSkin.lua paints the whole frame, every button
-- in it and the heading over them in the addon's palette, and sets the air the
-- layout pass reads so the column sits one pad from every edge.
--
-- The stub in client/08-blizzard.lua is the real template: a pool handed out
-- afresh on every show, the addon's hook after that, and the layout on the next
-- frame, which a section calls itself as menu:Layout().
--
-- The first two versions of this file gated placements that are gone. One
-- walked an anchor chain and re-anchored its foot, and in game drew a button
-- you saw on every other press of Escape. The other hung the button off the
-- frame's bottom edge, under Return to Game. So what is asserted here is where
-- the button lands in the column and that nothing of Blizzard's is anchored by
-- the addon to get it there.

local H = ...
local ns, check = H.ns, H.check

local menu = H.menu
local Menu = ns.GameMenu
local button = _G.WarriorKitGameMenuButton
local setup = _G.WarriorKitGameMenuSetup
local M = ns.UI.Metric

local PAD, GAP = M.pad, M.rowGap
local TOP = M.title + 2 * ns.Pixel(menu) + PAD

check(button ~= nil, "no button was put in the game menu")
check(Menu ~= nil, "Core/Menu.lua left nothing on ns")

-- One press of Escape: the client's show, which runs InitButtons and then our
-- hook, and the frame after it, which is the layout pass.
local function press()
	menu:Hide()
	menu:Show()
	return menu:Layout()
end

-- Blizzard's buttons by their label, ours by identity: the kit button keeps
-- its font string in a field of its own and answers no text.
local function labelled(column, text)
	for index, entry in ipairs(column) do
		if entry ~= button and entry ~= setup and entry:GetText() == text then
			return index, entry
		end
	end
	return nil
end

local function ours(column, which)
	for index, entry in ipairs(column) do
		if entry == (which or button) then
			return index
		end
	end
	return nil
end

local function anchored(frame)
	local point, relative, relativePoint, x, y = frame:GetPoint(1)
	return ("%s|%s|%s|%s|%s"):format(tostring(point), tostring(relative and relative.name),
		tostring(relativePoint), tostring(x), tostring(y))
end

local function offset(frame)
	local _, _, _, x, y = frame:GetPoint(1)
	return x, -y
end

local column = press()

--------------------------------------------------------------------------
-- The place
--------------------------------------------------------------------------

if button then
	check(button.parent == menu, "the button is not a child of the game menu")

	local options = labelled(column, "Options")
	local at = ours(column)
	check(at ~= nil, "the button is not in the menu's column")
	check(options and at == options + 1,
		("the button is %s in the column and Options is %s"):format(tostring(at), tostring(options)))
	check(setup ~= nil and ours(column, setup) == at + 1,
		("the setup's button is %s in the column and ours is %s")
			:format(tostring(setup and ours(column, setup)), tostring(at)))
	check(column[#column]:GetText() == "Return to Game",
		("the foot of the column is %q, not Return to Game"):format(tostring(column[#column]:GetText())))

	local twin = column[options or 1]
	check(button:GetWidth() == twin:GetWidth() and button:GetHeight() == twin:GetHeight(),
		("the button is %g x %g and the menu's own are %g x %g")
			:format(button:GetWidth(), button:GetHeight(), twin:GetWidth(), twin:GetHeight()))

	check(Menu.Describe():find("under Options") ~= nil,
		"the status line does not say where the button went: " .. Menu.Describe())
end

--------------------------------------------------------------------------
-- The air
--
-- One pad from every edge, under the title band on top, and the same pad
-- between sections. Two buttons in one section are one gap apart.
--------------------------------------------------------------------------

do
	local x, y = offset(column[1])
	check(x == PAD, ("the column starts %g in from the left and the pad is %g"):format(x, PAD))
	check(math.abs(y - TOP) < 0.001,
		("the column starts %g down and the title band plus the pad is %g"):format(y, TOP))

	local last = column[#column]
	local _, lastY = offset(last)
	local under = menu:GetHeight() - lastY - last:GetHeight()
	check(math.abs(under - PAD) < 0.001, ("%g under the last button and the pad is %g"):format(under, PAD))
	local right = menu:GetWidth() - x - last:GetWidth()
	check(right == PAD, ("%g to the right of the column and the pad is %g"):format(right, PAD))

	local gaps, sections = 0, 0
	for index = 2, #column do
		local _, above = offset(column[index - 1])
		local _, here = offset(column[index])
		local gap = here - above - column[index - 1]:GetHeight()
		if column[index].topPadding then
			sections = sections + 1
			check(math.abs(gap - PAD) < 0.001,
				("%s starts a section %g under the button above and the pad is %g")
					:format(column[index]:GetText(), gap, PAD))
		else
			gaps = gaps + 1
			check(math.abs(gap - GAP) < 0.001,
				("button %d is %g under the button above and the gap is %g")
					:format(index, gap, GAP))
		end
	end
	check(sections == 3 and gaps > 0,
		("%d section breaks and %d gaps in the column"):format(sections, gaps))
end

--------------------------------------------------------------------------
-- The column changing under it
--
-- InitButtons hands the column out on every show and the index of Options
-- moves with the event button above it. A press with the event on and the shop
-- off has to put ours under Options again, with a released button of Blizzard's
-- still hidden in the pool.
--------------------------------------------------------------------------

if button then
	menu.withEvent, menu.withShop = true, false
	local moved = press()
	local options = labelled(moved, "Options")
	check(options and ours(moved) == options + 1,
		"the button did not follow Options when the event button pushed it down")
	check(moved[1]:GetText() == "Event", "the event button is not at the top of the column")

	-- The same press twice more changes nothing. No layoutIndex drifts and no
	-- size grows, which is the leak the old placement had to be gated against.
	local index, height = button.layoutIndex, menu:GetHeight()
	press()
	press()
	check(button.layoutIndex == index,
		("pressing again moved the button's index from %g to %g"):format(index, button.layoutIndex))
	check(menu:GetHeight() == height,
		("pressing again took the menu from %g to %g tall"):format(height, menu:GetHeight()))

	-- Attach on its own anchors nothing, ours or Blizzard's.
	local placed = {}
	for _, entry in ipairs(moved) do
		placed[entry] = anchored(entry)
	end
	Menu.Attach()
	Menu.Attach()
	local shifted = 0
	for _, entry in ipairs(moved) do
		if anchored(entry) ~= placed[entry] then
			shifted = shifted + 1
		end
	end
	check(shifted == 0, ("%d buttons moved on an attach with no layout pass"):format(shifted))

	menu.withEvent, menu.withShop = false, true
	column = press()
end

-- A client whose string for Options matches no button follows the first
-- button, which with the event on is the event and not Options. And a menu
-- with no pool at all is refused out loud rather than half joined.
if button then
	local options = _G.GAMEMENU_OPTIONS
	_G.GAMEMENU_OPTIONS = "Einstellungen"
	menu.withEvent = true
	local other = press()
	check(ours(other) == 2 and other[1]:GetText() == "Event",
		"the button did not follow the first button in a menu without Options")
	_G.GAMEMENU_OPTIONS = options
	menu.withEvent = false

	local pool = menu.buttonPool
	menu.buttonPool = nil
	check(not Menu.Attach(), "the button claimed a place in a menu with no column")
	check(not button:IsShown(), "the button stayed up in a menu with no column")
	check(Menu.Describe():find("no column") ~= nil,
		"the status line does not say why the button is missing: " .. Menu.Describe())
	menu.buttonPool = pool
	check(Menu.Attach(), "the button did not come back when the column did")
	column = press()
end

--------------------------------------------------------------------------
-- The paint
--
-- Core/MenuSkin.lua walks a frame the addon did not build and draws over it,
-- and then walks it again on every press of Escape. It can miss art, eat its
-- own, grow, and fail to go back.
--------------------------------------------------------------------------

local Skin = ns.MenuSkin
local UI = ns.UI
local KIT = UI.Font(M.font, UI.FLAT)

check(Skin ~= nil, "Core/MenuSkin.lua left nothing on ns")

local border, header = menu.Border, menu.Header

local function mine(frame, kind)
	local out = {}
	for _, region in ipairs(frame.regions) do
		if region.wkOurs and region:GetObjectType() == kind then
			out[#out + 1] = region
		end
	end
	return out
end

local function theirs(frame, kind)
	local out = {}
	for _, region in ipairs(frame.regions) do
		if not region.wkOurs and region:GetObjectType() == kind then
			out[#out + 1] = region
		end
	end
	return out
end

local function hidden(frame, where)
	for _, art in ipairs(theirs(frame, "Texture")) do
		check(art.wkStripped and not art:IsShown(),
			("%s is still showing on %s"):format(art.name or "an unnamed texture", where))
	end
end

local function shown(frame, where)
	for _, art in ipairs(theirs(frame, "Texture")) do
		check(not art.wkStripped and art:IsShown(),
			("%s did not come back on %s"):format(art.name or "an unnamed texture", where))
	end
end

-- Blizzard's own buttons in the column, which is every one but our two.
local function blizzard()
	local out = {}
	for _, entry in ipairs(column) do
		if entry ~= button and entry ~= setup then
			out[#out + 1] = entry
		end
	end
	return out
end

local buttons = blizzard()

hidden(border, "the menu's border")
hidden(header, "the menu's header")
for _, entry in ipairs(buttons) do
	hidden(entry, entry.name)
end

-- The heading. Blizzard's is hidden and ours says what it said.
local heading = theirs(header, "FontString")
check(#heading == 1, ("the header carries %d headings of Blizzard's"):format(#heading))
for _, text in ipairs(heading) do
	check(not text:IsShown(), "the client's own heading is still drawn under ours")
end

local title = mine(menu, "FontString")
check(#title == 1, ("the addon drew %d headings on the menu"):format(#title))
if #title == 1 then
	check(title[1]:GetText() == "Game Menu",
		("the title says %q and the client's menu said \"Game Menu\""):format(
			tostring(title[1]:GetText())))
	check(title[1]:IsShown(), "the title was not drawn")
end

local painted, labels = 0, 0
for _, entry in ipairs(buttons) do
	check(entry.wkOn == true, entry.name .. " was not painted")
	check(entry.wkPaint ~= nil and entry.wkPaint:IsShown(),
		entry.name .. " carries no fill of the addon's")
	if entry.wkPaint then
		painted = painted + 1
	end
	for _, text in ipairs(theirs(entry, "FontString")) do
		labels = labels + 1
		check(text:GetFontObject() == KIT,
			("%s draws its label in %s rather than the kit's font"):format(
				entry.name, tostring(text:GetFont())))
	end
end
check(labels == #buttons, ("%d labels dressed across %d buttons"):format(labels, #buttons))

check(button == nil or button.wkPaint == nil,
	"the skin painted the addon's own button a second time")
check(setup == nil or setup.wkPaint == nil,
	"the skin painted the setup's button a second time")

-- The same pass again, twice. Nothing new is drawn and nothing of ours is
-- taken off.
do
	local before, first = #menu.regions, #buttons[1].regions
	Skin.Apply()
	Skin.Apply()
	check(#menu.regions == before,
		("the menu went from %d regions to %d over two more passes")
			:format(before, #menu.regions))
	check(#buttons[1].regions == first,
		("%s went from %d regions to %d over two more passes")
			:format(buttons[1].name, first, #buttons[1].regions))
	for _, entry in ipairs(buttons) do
		hidden(entry, entry.name .. " after two more passes")
		check(entry.wkPaint:IsShown(), entry.name .. " lost its fill to the second pass")
	end
end

-- Off, which is the switch on the panel. Everything of Blizzard's comes back,
-- every string goes back into its own font, and the next press lays the
-- column out with Blizzard's own air.
do
	ns.db.menuSkin = false
	Skin.Apply()

	shown(border, "the menu's border")
	shown(header, "the menu's header")
	for _, entry in ipairs(buttons) do
		shown(entry, entry.name)
		check(not entry.wkPaint:IsShown(), entry.name .. " kept the addon's fill")
		for _, text in ipairs(theirs(entry, "FontString")) do
			check(text:GetFontObject() == _G.GameFontNormal,
				("%s did not get its own font back"):format(entry.name))
		end
	end
	for _, text in ipairs(heading) do
		check(text:IsShown(), "the client's own heading did not come back")
	end
	for _, region in ipairs(mine(menu, "Texture")) do
		check(not region:IsShown(), "a region of the addon's stayed up on the menu with the paint off")
	end
	if #title == 1 then
		check(not title[1]:IsShown(), "the addon's title stayed up with the paint off")
	end
	for key, value in pairs(H.MENU_PADDING) do
		check(menu[key] == value, ("the menu's %s is %s and Blizzard's is %s")
			:format(key, tostring(menu[key]), tostring(value)))
	end
	local bare = press()
	local _, y = offset(bare[1])
	check(y == H.MENU_PADDING.topPadding,
		("with the paint off the column starts %g down, not Blizzard's %g")
			:format(y, H.MENU_PADDING.topPadding))
	check(bare[#bare].topPadding == H.MENU_SECTION,
		"with the paint off Return to Game lost Blizzard's section gap")
	check(Skin.Describe():find("client's own") ~= nil,
		"the reading does not say the menu is the client's own: " .. Skin.Describe())

	ns.db.menuSkin = true
	column = press()
	buttons = blizzard()
	hidden(border, "the menu's border on the way back")
	for _, entry in ipairs(buttons) do
		hidden(entry, entry.name .. " on the way back")
		check(entry.wkPaint:IsShown(), entry.name .. " did not get its fill back")
	end
	local _, back = offset(column[1])
	check(math.abs(back - TOP) < 0.001, "the pad did not come back with the paint")
end

check(painted == #buttons,
	("%d of the menu's %d buttons were painted"):format(painted, #buttons))

-- The probe runs. It is what somebody types when the button has not turned
-- up, and a probe that raises at that moment is worse than no probe.
check(pcall(SlashCmdList.WARRIORKIT, "menu"), "/wk menu raised")

check(pcall(SlashCmdList.WARRIORKIT, "menu off"), "/wk menu off raised")
check(ns.db.menuSkin == false, "/wk menu off left the paint on")
check(pcall(SlashCmdList.WARRIORKIT, "menu on"), "/wk menu on raised")
check(ns.db.menuSkin == true, "/wk menu on left the paint off")
for _, entry in ipairs(buttons) do
	check(entry.wkPaint:IsShown(), entry.name .. " did not come back after /wk menu on")
end

print(("game menu %d in the column, ours under Options, %g x %g, %s")
	:format(#column, menu:GetWidth(), menu:GetHeight(), Menu.Describe()))
print(("game menu %d buttons in the kit's paint, %d labels dressed, %s")
	:format(painted, labels, Skin.Describe()))
