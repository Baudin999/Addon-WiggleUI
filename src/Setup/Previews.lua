local ADDON, ns = ...

local UI = ns.UI
local C = UI.Color

-- Probed rather than called, for the reason UnitFrames/Paint.lua gives.
local SetPortraitTexture = _G.SetPortraitTexture

--------------------------------------------------------------------------
-- The pictures on the setup's cards
--
-- A new player is asked four questions and none of them can be answered from a
-- word. "Exploration" says nothing until you have seen what it leaves on the
-- screen, and "modern" says less. So each card carries a small drawing of what
-- the answer puts in front of you, and every drawing is made from the same
-- table the answer is: the mode's picture is Themes.lua read cell by cell, and
-- the palette's is that palette's own colours and painting. A picture that was
-- drawn by hand would be a second description of the theme, and the first
-- change to Themes.lua would make it a wrong one.
--
-- Built once per card and never redrawn. The setup is a window you see once,
-- and a drawing that cost a frame per block is still nothing next to one
-- loading screen.
--------------------------------------------------------------------------

local Previews = {}
ns.SetupPreviews = Previews

local function Paint(parent, color, alpha, layer)
	return ns.Fill(parent, layer or "ARTWORK", color[1], color[2], color[3],
		(color[4] or 1) * (alpha or 1))
end

-- A rectangle at a fraction of its parent, which is how every block in these
-- drawings is placed: the card's size is decided by the window, and a drawing
-- in fractions is right at whatever that turns out to be.
local function Place(region, parent, width, height, spot)
	region:ClearAllPoints()
	region:SetPoint("TOPLEFT", parent, "TOPLEFT",
		math.floor(spot[1] * width), -math.floor(spot[2] * height))
	region:SetSize(math.max(math.floor(spot[3] * width), 2),
		math.max(math.floor(spot[4] * height), 2))
	return region
end

-- The monitor the mode and tooltip pictures are drawn on: the sunken floor
-- with a hairline round it, which is what a window in this addon calls empty.
local function Screen(preview)
	local screen = UI.Box(preview, C.sunken, C.hairline)
	screen:SetAllPoints()
	return screen
end

--------------------------------------------------------------------------
-- The mode
--------------------------------------------------------------------------

-- Where each element sits on a 16 by 9 screen, as left, top, width and height
-- in fractions of it. Roughly where the shipped screen puts each one, because
-- the point of the picture is that you recognise it once you are in the world.
-- Every element in Themes.ELEMENTS has a spot, and the check under the table
-- holds a new element to having one: a mode picture missing a row would be a
-- picture of a theme that does not exist.
local SPOTS = {
	player     = { 0.28, 0.60, 0.13, 0.06 },
	target     = { 0.59, 0.60, 0.13, 0.06 },
	party      = { 0.02, 0.20, 0.07, 0.22 },
	raid       = { 0.02, 0.45, 0.12, 0.18 },
	castbar    = { 0.42, 0.72, 0.16, 0.025 },
	enemies    = { 0.74, 0.10, 0.10, 0.14 },
	swing      = { 0.42, 0.67, 0.16, 0.02 },
	bars       = { 0.32, 0.84, 0.36, 0.08 },
	loadout    = { 0.32, 0.77, 0.36, 0.03 },
	charge     = { 0.70, 0.84, 0.04, 0.07 },
	cooldowns  = { 0.42, 0.53, 0.16, 0.04 },
	buffs      = { 0.40, 0.04, 0.20, 0.04 },
	numbers    = { 0.44, 0.28, 0.12, 0.14 },
	chat       = { 0.02, 0.72, 0.26, 0.22 },
	quests     = { 0.88, 0.24, 0.10, 0.28 },
	minimap    = { 0.88, 0.03, 0.10, 0.17 },
	meters     = { 0.80, 0.62, 0.18, 0.14 },
	feeds      = { 0.76, 0.30, 0.10, 0.25 },
	drops      = { 0.62, 0.30, 0.10, 0.18 },
	messages   = { 0.35, 0.11, 0.30, 0.04 },
	standing   = { 0.02, 0.03, 0.20, 0.03 },
	experience = { 0.32, 0.94, 0.36, 0.015 },
	keys       = { 0.15, 0.25, 0.10, 0.12 },
}

for _, element in ipairs(ns.Themes.ELEMENTS) do
	assert(SPOTS[element.key],
		("the setup's mode picture has no spot for the element %q"):format(element.key))
end
for key in pairs(SPOTS) do
	local found = false
	for _, element in ipairs(ns.Themes.ELEMENTS) do
		found = found or element.key == key
	end
	assert(found, ("the setup's mode picture places %q, which is not an element"):format(key))
end

-- How strongly a block is drawn when it is up. Under full, so the blocks read as
-- a map of the screen rather than as buttons on the card.
local SHOWN = 0.55

-- One element as its mode draws it. Shown is a block, a fraction is the block
-- at that fraction, and under the pointer is the outline of one: there, and
-- empty until you reach for it. Hidden is not drawn at all.
local function Element(screen, width, height, spot, mode)
	if mode == "hide" then
		return
	end
	if mode == "hover" then
		local frame = Place(CreateFrame("Frame", nil, screen), screen, width, height, spot)
		local edges = ns.Outline(frame, C.dim[1], C.dim[2], C.dim[3], 0.8)
		ns.EdgeSize(edges, ns.Pixel(frame))
		return
	end
	local alpha = mode == "show" and SHOWN or SHOWN * mode
	Place(Paint(screen, C.accent, alpha), screen, width, height, spot)
end

function Previews.Mode(preview, width, height, theme)
	local screen = Screen(preview)
	for _, element in ipairs(ns.Themes.ELEMENTS) do
		Element(screen, width, height, SPOTS[element.key], ns.Themes[theme][element.key])
	end
	return screen
end

--------------------------------------------------------------------------
-- The palette
--------------------------------------------------------------------------

-- A window in miniature, in the palette's own colours: its floor, its title
-- band, a line of text and a quieter one, the accent and a button. On the
-- palette's painting where it has one, because the painting is most of what
-- choosing forest over dark changes.
--
-- The floor is cropped to the card's shape rather than stretched to it, the
-- way UI/Backdrop.lua covers a window with a floor drawn once: arcane's is one
-- wide starfield, and squeezed into a card it would read as a smear.
local function Crop(texture, piece, width, height)
	local want, have = width / height, piece[2] / piece[3]
	if have > want then
		local keep = want / have
		texture:SetTexCoord((1 - keep) / 2, (1 + keep) / 2, 0, 1)
	else
		local keep = have / want
		texture:SetTexCoord(0, 1, (1 - keep) / 2, (1 + keep) / 2)
	end
end

local function Ground(preview, name, width, height)
	local art = ns.Backdrops[name]
	local ground = preview:CreateTexture(nil, "BACKGROUND")
	ground:SetAllPoints()
	if art then
		ground:SetTexture(art.Middle[1])
		Crop(ground, art.Middle, width, height)
	else
		local window = ns.Palettes[name].window
		ground:SetColorTexture(window[1], window[2], window[3], 1)
	end
	return ground
end

local function Line(parent, size, color, text)
	local label = UI.Label(parent, size, color, "LEFT", UI.FLAT)
	label:SetText(text)
	return label
end

function Previews.Palette(preview, width, height, name)
	local palette = ns.Palettes[name]
	Ground(preview, name, width, height)
	local edges = ns.Outline(preview, palette.edge[1], palette.edge[2], palette.edge[3], 1)
	ns.EdgeSize(edges, ns.Pixel(preview))

	local band = Paint(preview, palette.chrome, 0.9)
	band:SetPoint("TOPLEFT")
	band:SetPoint("TOPRIGHT")
	band:SetHeight(math.floor(height * 0.24))
	Line(preview, UI.Metric.small, palette.heading, "Bags"):SetPoint("LEFT", band, "LEFT", 6, 0)

	local first = Line(preview, UI.Metric.small, palette.text, "Hearthstone")
	first:SetPoint("TOPLEFT", band, "BOTTOMLEFT", 6, -5)
	local second = Line(preview, UI.Metric.small, palette.dim, "Linen Cloth  x20")
	second:SetPoint("TOPLEFT", first, "BOTTOMLEFT", 0, -3)

	local accent = Paint(preview, palette.accent)
	accent:SetSize(math.floor(width * 0.4), 3)
	accent:SetPoint("BOTTOMLEFT", 6, 6)

	local button = UI.Box(preview, palette.control, palette.edge)
	button:SetSize(38, 14)
	button:SetPoint("BOTTOMRIGHT", -6, 4)
	Line(button, UI.Metric.small, palette.text, "use"):SetPoint("CENTER")
	return preview
end

--------------------------------------------------------------------------
-- The unit frames
--------------------------------------------------------------------------

-- Your own frame, in your class's colour and your power's, which is what the
-- block will actually be when you log in. The portrait is the client's picture
-- of your character where the call exists, and the palette's control grey
-- where it does not.
local function Colours()
	local class = select(2, UnitClass("player"))
	local health = ns.Unit.Color.class[class] or ns.Unit.Color.class.WARRIOR
	local power = ns.Unit.Color.power[UnitPowerType("player") or 1] or ns.Unit.Color.power[1]
	return health, power
end

local function Portrait(frame, size)
	local portrait = frame:CreateTexture(nil, "ARTWORK")
	portrait:SetSize(size, size)
	portrait:SetPoint("LEFT")
	if type(SetPortraitTexture) == "function" then
		SetPortraitTexture(portrait, "player")
	else
		portrait:SetColorTexture(C.control[1], C.control[2], C.control[3], 1)
	end
	return portrait
end

-- One fill with its track. Modern lays a sheen down it, light at the top and
-- gone by the bottom, which is the look's whole difference on a single bar.
local function Fill(frame, color, share, modern)
	local track = Paint(frame, ns.Palettes.dark.unit.backdrop, 1, "BACKGROUND")
	track:SetAllPoints()
	local fill = Paint(frame, color)
	fill:SetPoint("TOPLEFT")
	fill:SetPoint("BOTTOMLEFT")
	fill:SetWidth(math.floor(frame:GetWidth() * share))
	if modern then
		local sheen = UI.Wash(frame, { 1, 1, 1, 0.12 }, "TOP", "OVERLAY")
		sheen:SetAllPoints(fill)
	end
	return fill
end

local function Bar(parent, width, height, color, share, modern)
	local bar = CreateFrame("Frame", nil, parent)
	bar:SetSize(width, height)
	Fill(bar, color, share, modern)
	if not modern then
		local edges = ns.Outline(bar, C.edge[1], C.edge[2], C.edge[3], 1)
		ns.EdgeSize(edges, ns.Pixel(bar))
	end
	return bar
end

-- Flat: the portrait's square, then health over power with a hairline round
-- each. Modern: no portrait, the bars take its room, stacked tight, and one
-- dark edge round the whole unit.
function Previews.Plate(preview, width, height, modern)
	local health, power = Colours()
	local unit = CreateFrame("Frame", nil, preview)
	local tall = math.floor(height * 0.42)
	local wide = math.floor(width * 0.8)
	unit:SetSize(wide, tall)
	unit:SetPoint("CENTER")

	local left = 0
	if not modern then
		Portrait(unit, tall)
		left = tall + 3
	end
	local healthTall = math.floor(tall * 0.68)
	local gap = modern and 0 or 2
	local top = Bar(unit, wide - left, healthTall, health, 0.72, modern)
	top:SetPoint("TOPLEFT", left, 0)
	local bottom = Bar(unit, wide - left, tall - healthTall - gap, power, 0.45, modern)
	bottom:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -gap)

	Line(top, UI.Metric.small, C.text, UnitName("player") or "You"):SetPoint("LEFT", 5, 0)
	if modern then
		local edges = ns.Outline(unit, C.chrome[1], C.chrome[2], C.chrome[3], 1)
		ns.EdgeSize(edges, ns.Pixel(unit))
	end
	return unit
end

--------------------------------------------------------------------------
-- The tooltip
--------------------------------------------------------------------------

-- What you are pointing at: a sword in a bag square, near the middle of the
-- screen, where the things you hover mostly are.
local ICON = "Interface\\Icons\\INV_Sword_04"

local function Box(screen, width, height)
	local box = UI.Box(screen, C.window, C.edge)
	box:SetSize(math.floor(width * 0.34), math.floor(height * 0.40))
	local title = Paint(box, C.heading, 0.9)
	title:SetPoint("TOPLEFT", 4, -4)
	title:SetSize(math.floor(width * 0.20), 3)
	for index = 1, 3 do
		local line = Paint(box, C.dim, 0.7)
		line:SetPoint("TOPLEFT", 4, -6 - index * 6)
		line:SetSize(math.floor(width * (0.28 - index * 0.04)), 2)
	end
	return box
end

-- Bottom right is the corner the client keeps its own tooltip in. Attached is
-- beside the square, which is the box on the thing it describes.
function Previews.Tip(preview, width, height, where)
	local screen = Screen(preview)
	local icon = UI.Icon(screen)
	icon:SetTexture(ICON)
	icon:SetSize(16, 16)
	icon:SetPoint("TOPLEFT", math.floor(width * 0.26), -math.floor(height * 0.30))

	local box = Box(screen, width, height)
	if where == UI.Tooltip.RIGHT then
		box:SetPoint("BOTTOMRIGHT", -4, 4)
	else
		box:SetPoint("TOPLEFT", icon, "TOPRIGHT", 3, 0)
	end
	return screen
end
