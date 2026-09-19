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
	texture:Show()
	return texture
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
	local piece = self.art[key]
	local width, height = piece[2], piece[3]
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

function Backdrop:Layout(width, height)
	local art, frame = self.art, self.frame
	local side, corner = art.thickness, art.corner

	-- The floor, from the window's top left, which is where the bake cut it to
	-- be in phase with the painting.
	local middle = art.Middle
	local used = 0
	for y = 0, height - 1, middle[3] do
		for x = 0, width - 1, middle[2] do
			local across = math.min(middle[2], width - x)
			local down = math.min(middle[3], height - y)
			used = used + 1
			Put(self:Tile("Middle", used), frame, x, y, across, down,
				across / middle[2], down / middle[3])
		end
	end
	self:Trim("Middle", used)

	-- The rails, between the corners. Each starts where its corner ends,
	-- which is the phase the bake cut it at.
	local left, top = corner - side.left, corner - side.top
	local wide = math.max(0, width + side.right - corner - left)
	local tall = math.max(0, height + side.bottom - corner - top)
	self:Run("Top", left, -side.top, wide, true)
	self:Run("Bottom", left, height + side.bottom - art.Bottom[3], wide, true)
	self:Run("Left", -side.left, top, tall, false)
	self:Run("Right", width + side.right - art.Right[2], top, tall, false)

	local far, low = width + side.right - corner, height + side.bottom - corner
	Put(self:Tile("TopLeft", 1), frame, -side.left, -side.top, corner, corner, 1, 1)
	Put(self:Tile("TopRight", 1), frame, far, -side.top, corner, corner, 1, 1)
	Put(self:Tile("BottomLeft", 1), frame, -side.left, low, corner, corner, 1, 1)
	Put(self:Tile("BottomRight", 1), frame, far, low, corner, corner, 1, 1)
end

-- The chosen palette's painting behind a frame, or nil when the palette has
-- none and the caller should draw its flat fill. Nothing is drawn until the
-- first Layout, which the window's resize makes.
function UI.Backdrop(frame)
	if not chosen then
		return nil
	end
	local backdrop = setmetatable({ frame = frame, art = chosen, pool = {} }, Backdrop)
	for key in pairs(SUBLEVEL) do
		backdrop.pool[key] = {}
	end
	return backdrop
end

-- The nine pieces by name, for Theme/Theme.lua to hold every painting to.
UI.BACKDROP_PIECES = SUBLEVEL
