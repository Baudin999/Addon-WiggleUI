-- The enemy bars on the nameplates
--
-- Two mobs pulled under plates that carry a scale of their own, and the bar the
-- addon hangs on each one held to the pixel grid: the scale, whole pixels, the
-- width the setting asks for, the gauge inside its box, one pixel edges and the
-- icon crop. The anchor, the wanted width and the first plate's widget go on
-- in H.carry to the debuff row and the zoom sections.
--
-- It sat at the bottom of 05-action-bars and shared nothing with the cloned
-- bars above it except the order they run in, which the runner still keeps.

local H = ...
local state = H.state
local CHURN, region = H.CHURN, H.region
local plates, plateSize, guids = H.plates, H.plateSize, H.guids
local PLATE_W, PLATE_H = H.PLATE_W, H.PLATE_H
local ns, fire = H.ns, H.fire
local check = H.check

-- The anchors a plate hands back, copied both ways because the client copies
-- both ways: a caller that reuses its table must not move a plate's click.
function H.CopyAnchors(anchors)
	local copy = {}
	for index, anchor in ipairs(anchors) do
		copy[index] = { point = anchor.point, relativeTo = anchor.relativeTo,
			relativePoint = anchor.relativePoint, offsetX = anchor.offsetX, offsetY = anchor.offsetY }
	end
	return copy
end

-- The table ApplyFrameOptions reads its hit test figures from. Style 2 is
-- NAME_ANCHOR_STYLES.AboveHealthBar, the name above the bar.
_G.NamePlateSetupOptions = { healthBarHeight = 4, unitNameAnchorStyle = 2 }

-- What Blizzard_NamePlateUnitFrame.lua's ApplyFrameOptions writes for a name
-- above the bar: the name's top left, ten pixels and four out, down to the
-- health bar's bottom right, ten out and half the bar down.
function H.BlizzardAnchors(plate)
	local unitFrame = plate.UnitFrame
	local halfBar = _G.NamePlateSetupOptions.healthBarHeight / 2
	return {
		{ point = "TOPLEFT", relativeTo = unitFrame.name, relativePoint = "TOPLEFT", offsetX = -14, offsetY = 0 },
		{ point = "BOTTOMRIGHT", relativeTo = unitFrame.healthBar, relativePoint = "BOTTOMRIGHT", offsetX = 10, offsetY = -halfBar },
	}
end

-- A mob and the plate the client puts up for it, carrying a scale of its own
-- the way a real plate does, so a widget that inherited it would be measurably
-- wrong. The size is the client's own figure until the addon asks for another.
local function Pull(index)
	local unit = "nameplate" .. index
	local plate = region("frame", _G.UIParent)
	plate.namePlateUnitToken = unit
	plate.restricted = true -- as every plate is; see refused in client/02-place.lua
	plate.scale = 1.1
	plate:SetSize(plateSize[1] or PLATE_W, plateSize[2] or PLATE_H)
	plate.UnitFrame = region("frame", plate)
	plate.UnitFrame:SetSize(plate:GetWidth(), plate:GetHeight())
	-- The child regions a nameplate carries, read off the client's XML: they
	-- must exist rather than fall through to the metatable above, which hands
	-- the strip a method. The cast bar sits inside its container, nowhere else.
	for _, child in ipairs({ "healthBar", "name", "LevelFrame", "ClassificationFrame",
		"selectionHighlight", "aggroHighlight", "RaidTargetFrame", "CastBarsContainer" }) do
		plate.UnitFrame[child] = region("frame", plate.UnitFrame)
	end
	plate.UnitFrame.CastBarsContainer.castBar = region("frame", plate.UnitFrame.CastBarsContainer)
	-- The hit test points, which are where the client lands a click on a plate,
	-- kept as data so a section can ask what they are on. The driver's SetUnit
	-- puts them on the name and the health bar before any addon hears the plate
	-- arrive. `refusing` is the client blocking addon code in combat off the
	-- tick a unit arrives, and a write through it raises, as the client's does.
	-- The read is a measurement of a restricted region, refused to the addon
	-- always: it shipped in Plates.Aim and the client blamed WiggleUI's taint.
	function plate:CanChangeHitTestPoints() return not self.refusing end
	function plate:SetHitTestPoints(anchors)
		assert(not self.refusing, "wrote a plate's hit test points while the client refuses them")
		self.hitTest = H.CopyAnchors(anchors)
	end
	function plate:GetHitTestPoints()
		H.refused(self, "GetHitTestPoints")
		return H.CopyAnchors(self.hitTest)
	end
	plate.hitTest = H.BlizzardAnchors(plate)
	plates[#plates + 1] = plate
	guids[unit] = ("Creature-0-0-0-0-1234-0000000%d"):format(index)
	fire("NAME_PLATE_UNIT_ADDED", unit)
	return ns.EnemyBars.WidgetFor(unit)
end

for i = 1, 2 do
	Pull(i)
end

local anchor = _G.WiggleUIEnemyBarsAnchor
local widget = ns.EnemyBars.WidgetFor("nameplate1")
check(anchor ~= nil, "no anchor came up")
check(widget ~= nil, "no widget attached to nameplate1")

-- The grid.
check(math.abs(ns.UI.Scale() - 768 / state.SCREEN_H) < 1e-9,
	("perfect scale is %.6f, expected %.6f"):format(ns.UI.Scale(), 768 / state.SCREEN_H))
for name, frame in pairs({ anchor = anchor, widget = widget }) do
	local px = ns.UI.Pixel(frame)
	check(math.abs(px - 1) < 1e-9, ("%s is not on the grid: one pixel is %.4f units"):format(name, px))
end

-- Whole pixels where the grid can reach. The health number is the one size
-- derived from a measurement the client made, so it is the one that can come
-- back fractional; the tag frame that used to hold that job is gone.
-- The debuff square is in the walk only where there is one. Which debuffs a bar
-- tracks is a fact about your spec now, and a class nobody has written a file
-- for tracks none until you pick some, so on that run there is no square to put
-- on the grid rather than a square that is off it.
for _, pair in ipairs({ { "widget", widget }, { "box", widget.box },
	{ "health number", widget.healthText },
	widget.icons[1] and { "icon", widget.icons[1] } or nil }) do
	for _, axis in ipairs({ "GetWidth", "GetHeight" }) do
		local size = pair[2][axis](pair[2])
		check(math.abs(size - math.floor(size + 0.5)) < 1e-9,
			("%s %s is %.4f, not a whole pixel"):format(pair[1], axis, size))
	end
end

-- A bar on a plate is `bars width` pixels, every bar, and it stays there.
--
-- It used to be as wide as the plate under it, and it then told the driver to
-- size plates by a footprint a tag wider than itself, so the next bar measured
-- off a plate came back changed: wider every round where a plate is scaled
-- above UIParent, which is this stub and was the harness case, narrower every
-- round on the client this was reported from. Either way no fixed point and no
-- setting that chose one. The five lines below are the whole of the contract:
-- the setting decides, six mobs do not move it, and a setting change does not
-- either.
local function BarWidth(unit)
	local bar = ns.EnemyBars.WidgetFor(unit)
	return bar and bar:GetWidth() or -1
end

local wanted = ns.db.barsWidth * ns.UI.Pixel(widget)
check(BarWidth("nameplate1") == wanted,
	("a bar on a plate is %.0f px, the setting says %.0f"):format(BarWidth("nameplate1"), wanted))
for i = 3, 6 do
	Pull(i)
	check(BarWidth("nameplate" .. i) == wanted,
		("mob %d got a bar %.0f px wide, the setting says %.0f"):format(
			i, BarWidth("nameplate" .. i), wanted))
end
ns.EnemyBars.Rebuild() -- what every setting in the panel does
check(BarWidth("nameplate1") == wanted,
	("a setting change took the bar to %.0f px, the setting says %.0f"):format(
		BarWidth("nameplate1"), wanted))

-- And the setting reaches a bar that is already on a plate, which is the half
-- of it that has no second chance: a widget on a plate is laid out when it
-- attaches, and these attached before the number changed.
ns.db.barsWidth = 240
ns.EnemyBars.ApplyLayout()
check(BarWidth("nameplate1") == 240 * ns.UI.Pixel(widget),
	("bars width 240 left the bar on a plate at %.0f px"):format(BarWidth("nameplate1")))
ns.db.barsWidth = ns.DefaultFor("barsWidth")
ns.EnemyBars.ApplyLayout()

-- Back down to the two the churn figure below is quoted at. The gate is a
-- number of KB per fifty ticks with two bars up, so the mobs pulled to prove
-- the width holds have to leave again or the ratchet is measuring a different
-- scene than the one it was set on.
for i = #plates, 3, -1 do
	fire("NAME_PLATE_UNIT_REMOVED", plates[i].namePlateUnitToken)
	guids[plates[i].namePlateUnitToken] = nil
	plates[i] = nil
end

-- The gauge fills the inside of the box, which is the box less one hairline on
-- each edge. Asserted because it was briefly one pixel tall: the gauge carries
-- no height of its own and takes whatever the box has left, and a layout node
-- that is not told to grow measures zero and gets zero.
do
	local px = ns.UI.Pixel(widget)
	-- Horizontally the gauge is still the box less a hairline each side, and
	-- that half has not moved.
	check(math.abs(widget.health:GetWidth() - (widget.box:GetWidth() - 2 * px)) < 1e-9,
		("the gauge is %.0f px wide inside a %.0f px box, expected %.0f")
			:format(widget.health:GetWidth(), widget.box:GetWidth(),
				widget.box:GetWidth() - 2 * px))

	-- Vertically it is the box less two hairlines only while nothing is casting.
	-- The box has two chambers now and the second one comes and goes, so what is
	-- asserted is the arithmetic both states have to satisfy:
	--
	--   idle = hairline + health + hairline
	--   open = idle + seam + cast
	--
	-- and, the part that is the whole reason the chamber is not a Flow node,
	-- that the health gauge is the same height and in the same place in both.
	check(math.abs(widget.health:GetHeight() - (widget.boxIdle - 2 * px)) < 1e-9,
		("the gauge is %.0f px tall inside a %.0f px idle box, expected %.0f")
			:format(widget.health:GetHeight(), widget.boxIdle, widget.boxIdle - 2 * px))
	check(math.abs(widget.box:GetHeight() - widget.boxIdle) < 1e-9,
		("nothing is casting and the box is %.0f px, idle is %.0f")
			:format(widget.box:GetHeight(), widget.boxIdle))

	local cast = widget.cast
	check(math.abs(widget.boxOpen - (widget.boxIdle + px + cast:GetHeight())) < 1e-9,
		("the open box is %.0f px, expected idle %.0f plus a seam plus a %.0f px chamber")
			:format(widget.boxOpen, widget.boxIdle, cast:GetHeight()))

	local beforeH = widget.health:GetHeight()
	local _, _, _, _, beforeY = widget.health:GetPoint()
	ns.db.locked = false -- unlocked, the chamber previews itself on every bar
	ns.Cast.Update(widget, "nameplate1")
	check(math.abs(widget.box:GetHeight() - widget.boxOpen) < 1e-9,
		("a cast left the box at %.0f px, open is %.0f")
			:format(widget.box:GetHeight(), widget.boxOpen))
	check(widget.cast.seam:IsShown(), "the box has two chambers and no seam between them")
	local _, _, _, _, afterY = widget.health:GetPoint()
	check(widget.health:GetHeight() == beforeH and afterY == beforeY,
		"the cast chamber moved the health gauge, which is the whole thing it must not do")

	ns.db.locked = true
	ns.Cast.Clear(widget)
	check(math.abs(widget.box:GetHeight() - widget.boxIdle) < 1e-9,
		("the cast ended and the box stayed at %.0f px, idle is %.0f")
			:format(widget.box:GetHeight(), widget.boxIdle))
	check(not widget.cast.seam:IsShown(), "nothing is casting and the seam is still drawn")
end

-- The edges are one pixel, which was the whole complaint.
check(widget.box.edges[1].height == ns.UI.Pixel(widget),
	("hairline is %.4f units, expected %.4f"):format(widget.box.edges[1].height, ns.UI.Pixel(widget)))

-- The icon crop lands on texel boundaries and the client's snapping is off.
-- Asked only where the bar is tracking something, for the reason the grid walk
-- above skips the same square, and every class run reaches it.
local art = widget.icons[1] and widget.icons[1].icon
check(not art or (art.texcoord and math.abs(art.texcoord[1] * 64 - 5) < 1e-9),
	"icon crop is not on a texel boundary")
check(not art or (art.snapped == false and art.bias == 0),
	"icon texture is still being snapped")

-- Left for the sections below.
H.carry.anchor, H.carry.wanted, H.carry.widget = anchor, wanted, widget
