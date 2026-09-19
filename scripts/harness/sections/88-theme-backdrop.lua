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

-- An action bar: a stand-in box painted through Look.Paint with bar 1's
-- definition, so the alpha is the one the player gave that bar. The floor goes
-- down at the bar's size and at that alpha, and the flat fill under it goes to
-- nothing rather than doubling the ground.
local bar1
for _, entry in ipairs(ns.Bars.All()) do
	if entry.def.key == "bar1" then
		bar1 = entry
	end
end
check(bar1 ~= nil, "bar 1 is standing to borrow a definition from")
if bar1 then
	local box = UI.Box(UIParent, UI.Color.window, UI.Color.hairline)
	box:SetSize(250, 40)
	ns.BarLook.Paint({ frame = box, def = bar1.def })
	local alpha = ns.BarLook.Alpha(bar1.def) / 100
	check(box.floor and #box.floor.pool.Middle == 3, "a 250 wide bar lays three floor tiles")
	check(box.floor.pool.Middle[1].alpha == alpha,
		("the floor is at the bar's own alpha, %s against %s")
			:format(tostring(box.floor.pool.Middle[1].alpha), tostring(alpha)))
	check(box.bg.a == 0, "the flat fill under a painted floor is at nothing")
	box:Hide()
end

-- A painted window: no flat fill, no chrome strip across the top, and a rule
-- under the title the way the footer has one over it.
local painted = UI.Window({ title = "Painted", width = 300, height = 200, backdrop = true })
check(painted.backdrop ~= nil and painted.bg == nil, "a painted window has the painting and no fill")
check(painted.titleRule ~= nil, "a painted window's header is ruled like its footer")
painted:Hide()

-- A screen window takes the flag like any other: the painting when it asks,
-- and then no wash, which would only darken the opaque floor. One that does
-- not ask keeps the wash and no painting.
local sheet = UI.Window({ screen = true, secure = true, backdrop = true })
check(sheet.backdrop ~= nil and sheet.bg == nil, "a screen window that asks for the painting gets it")
check(sheet.dark == nil, "a painted screen window lays no wash over its floor")
sheet:Hide()
local bare = UI.Window({ screen = true, secure = true })
check(bare.backdrop == nil and bare.dark ~= nil, "a screen window that does not ask keeps the wash")
bare:Hide()

-- A feed row's wash on the floor: the tile's file under the same ramp, and
-- rows stacked down a feed cut consecutive bands so the column reads as one
-- painting. A band that would run off the tile's foot ends on it instead.
local floor = UI.Floor()
check(floor == art.Middle, "the floor a wash paints with is the palette's Middle tile")
local wash = UI.Wash(frame, { 0.5, 0.5, 0.5, 0.55 }, "LEFT", "BACKGROUND", floor[1])
check(wash.texture == floor[1], "a painted wash draws the tile's file")
check(wash.gradient and wash.gradient.min[4] == 0.55 and wash.gradient.max[4] == 0,
	"a painted wash still fades from the shadow's alpha to nothing")
UI.FloorBand(wash, floor, 20, floor[2] / 2, 18)
check(math.abs(wash.texcoord[3] - 20 / floor[3]) < 1e-9
	and math.abs(wash.texcoord[4] - 38 / floor[3]) < 1e-9,
	"a row 20 down cuts the band 20 down the tile")
check(math.abs(wash.texcoord[2] - 0.5) < 1e-9, "a half-tile row takes half the tile across")
UI.FloorBand(wash, floor, floor[3] - 4, floor[2] * 2, 18)
check(math.abs(wash.texcoord[4] - 1) < 1e-9 and wash.texcoord[2] == 1,
	"a band past the foot ends on it, and a wide row stretches one tile")

-- The tooltip: the floor alone at the ground's scale, laid at the size the
-- box came out, over a fill gone to nothing and inside the hairline it keeps.
-- The box was built under the dark palette by an earlier section and decided
-- flat then, so the decision is put back to undecided for the painted open and
-- again at the foot, where the dark open decides flat once more.
local Tooltip = UI.Tooltip
local owner = CreateFrame("Frame", nil, UIParent)
Tooltip.Show(owner, { "Title", "a line under it" }, nil, "control")
local tip = Tooltip.Frame()
tip.ground = nil
tip.bg:SetAlpha(1)
Tooltip.Show(owner, { "Title", "a line under it", "and another", "and a fourth" }, nil, "control")
local ground = tip.ground
check(ground ~= nil and ground ~= false, "a painted palette puts the tooltip on its floor")
if ground then
	local scale = UI.GROUND_SCALE
	local tileW, tileH = art.Middle[2] * scale, art.Middle[3] * scale
	local want = math.ceil(tip:GetWidth() / tileW) * math.ceil(tip:GetHeight() / tileH)
	local laid = 0
	for _, texture in ipairs(ground.pool.Middle) do
		laid = laid + (texture:IsShown() and 1 or 0)
	end
	check(laid == want, ("the floor covers the box it was sized to, %d tiles against %d"):format(laid, want))
	-- The stand-in font measures narrow, so the box is under one tile wide and
	-- the scale shows in how much of the tile the first texture cuts.
	local first = ground.pool.Middle[1]
	local across = math.min(tileW, tip:GetWidth())
	check(first.width == across and math.abs(first.texcoord[2] - across / tileW) < 1e-9,
		("the tooltip's floor tile is at the ground's scale, %s of %s shown")
			:format(tostring(first.texcoord[2]), tostring(across / tileW)))
	check(#ground.pool.Top == 0 and #ground.pool.TopLeft == 0, "the tooltip draws no rail and no corner")
	check(tip.bg:GetAlpha() == 0, "the flat fill under the tooltip's floor is at nothing")
	check(tip.edges[1]:IsShown() ~= false and tip.edges[1].layer == "BORDER",
		"the tooltip keeps its hairline over the floor")
	for _, texture in ipairs(ground.pool.Middle) do
		texture:Hide()
	end
end
Tooltip.Close(true)
tip.ground = nil
tip.bg:SetAlpha(1)

frame:Hide()
UI.ChooseBackdrop(nil)
Tooltip.Show(owner, { "Title", "a line under it" }, nil, "control")
check(tip.ground == false and tip.bg:GetAlpha() == 1,
	"under a palette with no painting the tooltip keeps its flat fill")
Tooltip.Close(true)
owner:Hide()
check(UI.Floor() == nil, "a palette with no painting has no floor to wash with")
check(Gauge.Floor(Gauge.New(CreateFrame("Frame", nil, UIParent))) == nil,
	"a palette with no painting gives a gauge no floor")
