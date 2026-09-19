local ADDON, ns = ...

local UI = ns.UI

--------------------------------------------------------------------------
-- A painted frame behind a window
--
-- The palette's painting, cut into nine by scripts/bake-backdrops.sh and
-- described in Theme/Backdrops.lua: a floor tiled under the whole window, four
-- rails round the outside and a corner on each end of them. The rails and the
-- corners hang outside the window by the frame's thickness, so the window's
-- size and everything laid out in it stay where they were, and the title bar
-- and footer are drawn over the floor as they were over the flat fill.
--
-- The tiles are laid as a grid of plain textures, each drawn once, with the
-- last in a row cut short by its texcoord. Not a wrapped texture: the client
-- tiles one at the texture's own pixel size, which is not the size it is drawn
-- at here, and no installed addon asks it for a repeat any other way.
--
-- Which painting is the palette's, and the palette is chosen once at load, so
-- Theme/Theme.lua hands it over in the same pass that paints UI.Color. A
-- window built before that pass gets the flat fill, and none is: the one
-- window that asks is the bag window, built on its first open.
--------------------------------------------------------------------------

local Backdrop = {}
Backdrop.__index = Backdrop

local chosen

function UI.ChooseBackdrop(art)
	chosen = art
end

-- Under everything the window draws, and in the order they overlap: the floor,
-- the rails over its edge, the corners over the ends of the rails.
local SUBLEVEL = {
	Middle = -8,
	Top = -7, Bottom = -7, Left = -7, Right = -7,
	TopLeft = -6, TopRight = -6, BottomLeft = -6, BottomRight = -6,
}

-- The texture at index in the pool for a piece, made the first time it is
-- asked for.
function Backdrop:Tile(key, index)
	local pool = self.pool[key]
	local texture = pool[index]
	if not texture then
		texture = self.frame:CreateTexture(nil, "BACKGROUND", nil, SUBLEVEL[key])
		texture:SetTexture(self.art[key][1])
		pool[index] = texture
	end
	texture:SetAlpha(self.alpha)
	texture:Show()
	return texture
end

-- How much of the painting shows, for an owner whose ground is a setting: the
-- action bars draw theirs at the alpha the player gave the bar. Every tile
-- takes it now and every tile made by a later layout takes it as it is shown.
function Backdrop:SetAlpha(alpha)
	self.alpha = alpha
	for _, pool in pairs(self.pool) do
		for _, texture in ipairs(pool) do
			texture:SetAlpha(alpha)
		end
	end
end

-- Puts a texture at x, y from the frame's top left, y counted down, cut to the
-- fraction of the tile that fits.
local function Put(texture, frame, x, y, width, height, across, down)
	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
	texture:SetSize(width, height)
	texture:SetTexCoord(0, across, 0, down)
end

-- Hides every texture in a pool past the ones this layout used.
function Backdrop:Trim(key, used)
	local pool = self.pool[key]
	for index = used + 1, #pool do
		pool[index]:Hide()
	end
end

-- One rail: a row of its tile from x, y along length, across or down.
function Backdrop:Run(key, x, y, length, across)
	local piece, scale = self.art[key], self.scale
	local width, height = piece[2] * scale, piece[3] * scale
	local step = across and width or height
	local used, at = 0, 0
	while at < length do
		local part = math.min(step, length - at)
		used = used + 1
		local texture = self:Tile(key, used)
		if across then
			Put(texture, self.frame, x + at, y, part, height, part / step, 1)
		else
			Put(texture, self.frame, x, y + at, width, part, 1, part / step)
		end
		at = at + part
	end
	self:Trim(key, used)
end

-- The scale is set again by an owner on the pixel grid, whose unit moves with
-- its zoom, before it lays the painting out again.
function Backdrop:SetScale(scale)
	self.scale = scale
end

-- How far the frame hangs outside the rectangle it is laid round, on one
-- side, at the scale it is drawn at. The minimap's clock tab hangs below this.
function Backdrop:Thickness(side)
	return self.art.thickness[side] * self.scale
end

function Backdrop:Layout(width, height)
	local art, frame, scale = self.art, self.frame, self.scale
	local side = {
		left = self:Thickness("left"), top = self:Thickness("top"),
		right = self:Thickness("right"), bottom = self:Thickness("bottom"),
	}
	local corner = art.corner * scale

	-- The floor, from the window's top left, which is where the bake cut it to
	-- be in phase with the painting. None round the minimap, whose map is the
	-- floor.
	local used = 0
	if self.floor then
		local tileW, tileH = art.Middle[2] * scale, art.Middle[3] * scale
		for y = 0, height - 1, tileH do
			for x = 0, width - 1, tileW do
				local across = math.min(tileW, width - x)
				local down = math.min(tileH, height - y)
				used = used + 1
				Put(self:Tile("Middle", used), frame, x, y, across, down,
					across / tileW, down / tileH)
			end
		end
	end
	self:Trim("Middle", used)
	if not self.framed then
		return
	end

	-- The rails, between the corners. Each starts where its corner ends,
	-- which is the phase the bake cut it at.
	local left, top = corner - side.left, corner - side.top
	local wide = math.max(0, width + side.right - corner - left)
	local tall = math.max(0, height + side.bottom - corner - top)
	self:Run("Top", left, -side.top, wide, true)
	self:Run("Bottom", left, height + side.bottom - art.Bottom[3] * scale, wide, true)
	self:Run("Left", -side.left, top, tall, false)
	self:Run("Right", width + side.right - art.Right[2] * scale, top, tall, false)

	local far, low = width + side.right - corner, height + side.bottom - corner
	Put(self:Tile("TopLeft", 1), frame, -side.left, -side.top, corner, corner, 1, 1)
	Put(self:Tile("TopRight", 1), frame, far, -side.top, corner, corner, 1, 1)
	Put(self:Tile("BottomLeft", 1), frame, -side.left, low, corner, corner, 1, 1)
	Put(self:Tile("BottomRight", 1), frame, far, low, corner, corner, 1, 1)
end

-- The chosen palette's painting behind a frame, or nil when the palette has
-- none and the caller should draw its flat fill. Nothing is drawn until the
-- first Layout, which the owner makes whenever the frame's size is decided.
--
-- opts.scale draws every piece at that fraction of the size the bake gave it,
-- and opts.floor = false leaves the floor out and draws the frame alone. The
-- minimap takes both: half, because a corner sized for a bag window reaches
-- forty pixels into a map two hundred wide, and no floor, because the map is
-- what it is round. opts.frame = false is the other half, the floor alone,
-- which is what a bar's empty end is drawn on.
function UI.Backdrop(frame, opts)
	if not chosen then
		return nil
	end
	opts = opts or {}
	local backdrop = setmetatable({
		frame = frame, art = chosen, pool = {},
		scale = opts.scale or 1, floor = opts.floor ~= false, framed = opts.frame ~= false,
		alpha = 1,
	}, Backdrop)
	for key in pairs(SUBLEVEL) do
		backdrop.pool[key] = {}
	end
	return backdrop
end

-- The chosen palette's floor tile, { file, width, height } in window units,
-- or nil when the palette has no painting. A feed row washes with it.
function UI.Floor()
	return chosen and chosen.Middle or nil
end

-- Cuts the band of a floor tile that lies under a strip y units down from its
-- owner's top, width by height, so strips stacked down one owner read as one
-- painting. A strip wider than the tile stretches the tile across rather than
-- repeating it: the wash on it is gone well before the stretch shows. A band
-- that would run off the tile's foot is lifted to end on it, which costs one
-- strip in every tile its continuity with the one above.
function UI.FloorBand(texture, floor, y, width, height)
	local across = math.min(width / floor[2], 1)
	local down = math.min(height / floor[3], 1)
	local top = math.min((y % floor[3]) / floor[3], 1 - down)
	texture:SetTexCoord(0, across, top, top + down)
end

-- The nine pieces by name, for Theme/Theme.lua to hold every painting to.
UI.BACKDROP_PIECES = SUBLEVEL
