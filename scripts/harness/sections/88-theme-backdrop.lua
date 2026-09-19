-- The painted frame
--
-- Laid out as a grid of plain textures, so what can be wrong is arithmetic: how
-- many tiles a size takes, how much of the last one is shown, and whether a
-- window that shrinks hides the tiles it no longer needs. Each is invisible on
-- the screen as a fault until the wrong window size comes up, where it is a
-- stripe of stretched floor or a tile hanging off the edge.
--
-- Laid out on a frame of its own with the forest painting chosen by hand, and
-- the choice put back to none at the foot, which is what the default dark
-- palette the load painted left there.

local H = ...
local ns, check = H.ns, H.check
local UI = ns.UI

local art = ns.Backdrops.forest
check(art ~= nil, "the forest palette has a painting")

UI.ChooseBackdrop(nil)
check(UI.Backdrop(CreateFrame("Frame", nil, UIParent)) == nil,
	"a palette with no painting asks for the flat fill")

UI.ChooseBackdrop(art)
local frame = CreateFrame("Frame", nil, UIParent)
local backdrop = UI.Backdrop(frame)
check(backdrop ~= nil, "a palette with a painting gives a backdrop")

local function shown(key)
	local count = 0
	for _, texture in ipairs(backdrop.pool[key]) do
		if texture:IsShown() then
			count = count + 1
		end
	end
	return count
end

-- Two and a half tiles across and not quite three down.
local tileW, tileH = art.Middle[2], art.Middle[3]
local width, height = tileW * 2 + tileW / 2, tileH * 3 - 4
backdrop:Layout(width, height)

check(shown("Middle") == 9, ("a 2.5 by 3 floor is nine tiles, got %d"):format(shown("Middle")))
local last = backdrop.pool.Middle[9]
check(math.abs(last.texcoord[2] - 0.5) < 1e-9,
	"the last tile across shows half of itself")
check(math.abs(last.texcoord[4] - (tileH - 4) / tileH) < 1e-9,
	"the last tile down shows what is left of the height")
check(last.width == tileW / 2 and last.height == tileH - 4,
	"the last tile is drawn at the size it shows, not stretched")

for _, key in ipairs({ "TopLeft", "TopRight", "BottomLeft", "BottomRight" }) do
	check(shown(key) == 1, ("the %s corner is drawn once"):format(key))
end
check(shown("Top") > 0 and shown("Left") > 0, "the rails are drawn")
check(backdrop.pool.Top[1].layer == "BACKGROUND", "the frame is under everything the window draws")

-- Shrunk to one tile, the rest go down rather than stay where they were.
backdrop:Layout(tileW, tileH)
check(shown("Middle") == 1, ("a one-tile window shows one tile, got %d"):format(shown("Middle")))

-- The minimap's: half scale and no floor. The map is the floor, so a tile
-- drawn there would cover the world; and every piece is half its size,
-- including how far the frame hangs outside, which is what the clock tab reads.
local ring = UI.Backdrop(CreateFrame("Frame", nil, UIParent), { scale = 0.5, floor = false })
ring:Layout(200, 200)
check(#ring.pool.Middle == 0, "a frame with no floor lays no floor tile")
local corner = ring.pool.TopLeft[1]
check(corner.width == art.corner / 2, ("the corner is drawn at half, %s against %s")
	:format(tostring(corner.width), tostring(art.corner / 2)))
check(ring:Thickness("bottom") == art.thickness.bottom / 2, "the thickness is asked at half")
check(ring.pool.Top[1].height == art.Top[3] / 2, "the rail is drawn at half its height")

-- A gauge's floor: the tile alone, no rails and no corners, and the track
-- kept over it thin enough for the pattern to show. Laid in design pixels at a
-- unit, the way the rails and the cast bar lay it after their zoom.
local Gauge = UI.Gauge
local gauge = Gauge.New(CreateFrame("Frame", nil, UIParent))
check(Gauge.Floor(gauge) ~= nil, "a palette with a painting gives a gauge a floor")
Gauge.LayFloor(gauge, 2, 200, 14)
check(#gauge.floor.pool.Middle > 0, "the floor is laid across the gauge")
check(#gauge.floor.pool.Top == 0 and #gauge.floor.pool.TopLeft == 0,
	"a floor alone draws no rail and no corner")
check(gauge.floor.pool.Middle[1].width == art.Middle[2] * 0.35 * 2,
	"the floor tile is drawn at the gauge's scale times the unit")
Gauge.Paint(gauge, gauge.track, { 1, 0, 0 })
check(gauge.track.a == 0.35, ("the track over a floor is a thin tint, got %s"):format(tostring(gauge.track.a)))

frame:Hide()
UI.ChooseBackdrop(nil)
check(Gauge.Floor(Gauge.New(CreateFrame("Frame", nil, UIParent))) == nil,
	"a palette with no painting gives a gauge no floor")
