local ADDON, ns = ...

local SwingGauges = {}
ns.SwingGauges = SwingGauges

--------------------------------------------------------------------------
-- One bar per hand
--
-- Drawn with ns.UI.Gauge on the pixel grid. No window round them, no text on
-- them and no chrome at all, for the reason Meter/Window.lua carries: this is
-- read out of the corner of your eye during a pull and every pixel of frame
-- around it is a pixel of the fight it stands on.
--
-- What is on the screen is the weapon you are holding. One bar for a two
-- hander, two for a pair, and none at all for a hand with nothing in it. The
-- second bar appears and disappears with the off hand weapon rather than with
-- a setting, because a setting for it would be a second way of asking a
-- question the character sheet already answers.
--
-- The bar counts in pixels rather than in a fraction from zero to one, so what
-- is drawn is measured in the units the eye reads it in.
--
-- The fill is not quantised, and this is where the addon's two pixel rules
-- disagree. Both are in docs/README.md and both are gated in
-- scripts/harness.lua.
--
-- A static edge lands on a whole pixel. A border or an icon crop drawn across
-- two rows of pixels reads as blurry, and blurry is what the grid exists to
-- stop.
--
-- A moving fill is not quantised. What the eye reads on a moving edge is its
-- velocity, and velocity lives in where the edge sits between two pixels as
-- much as in which pixel it is on. Rounding throws that away to buy a sharpness
-- nobody can see on something in motion, and rounding is also a throttle: the
-- fill crosses 330 units in a 3.4 second swing, so a rounded fill changes value
-- 97 times a second and no oftener, whatever rate the tick runs at. Deleting
-- the 20 Hz ticker raised the drawn rate and left that second throttle
-- standing, which is why the bar still stepped after the first repair.
--
-- So the fill is written as a fraction, on every frame a hand is swinging, with
-- no comparison in front of it except the one that catches a hand that is not.
-- What that costs was measured rather than argued: the harness read 0.03 KB per
-- fifty ticks rounded and guarded and 0.03 unguarded, so dropping the guard
-- bought smooth motion for nothing. It reads 0.00 now that the Slam band is not
-- repainting the gauge twice a swing.
--
-- Every other part of this addon draws on a ticker, because every other part is
-- a readout and a readout fifty milliseconds stale is one nobody can fault.
-- This one is an animation, and an animation is drawn on the frame the screen
-- is drawn on or it is drawn in steps.
--
-- Mouse only while unlocked, the same as the meters and the charge icon, and
-- for the same reason: a mouse enabled frame swallows the right button drag
-- that turns the camera, and this sits under the middle of the screen where
-- that drag starts.
--------------------------------------------------------------------------

local Gauge = ns.UI.Gauge

local FRAME_NAME = "WiggleUISwing"

-- One bar to the next. One pixel would put two hairlines against each other
-- and read as a single thick line between the bars.
local GAP = 2

-- Gold for the hand that carries the abilities, steel for the one that does
-- not, so the two are told apart by colour rather than by position. Both sit
-- where a health bar does not, because a bar under the middle of the screen in
-- red or green would read as somebody's health. The palette's, so a forest or
-- desert screen gets its own gold and steel.
local MAIN_FILL = ns.Unit.Color.swing.main
local OFF_FILL = ns.Unit.Color.swing.off

local EDGE = ns.UI.Color.chrome

local frame, main, off, place
local built = false
local dual = false

-- The frame the events and the tick hang off, and the tick itself. Declared
-- here rather than at the foot of the file because SwingGauges.Apply is what
-- arms and stops the tick and is written above where they are made.
local events, tick

-- One pixel of the design in this frame's units, which is exactly 1 once
-- ns.UI.Adopt has taken the frame onto the grid. Read again in every layout
-- pass rather than only at login: on a client with no SetIgnoreParentScale the
-- answer is a fraction of the screen height, and a monitor swap moves it under
-- a value read once.
local unit = 1

--------------------------------------------------------------------------
-- Building
--------------------------------------------------------------------------

local function BuildBar(parent, fill)
	local bar = Gauge.New(parent)
	Gauge.Paint(bar, bar.track, fill)

	-- No width until the layout has given it one. Not 1: a bar counting to one
	-- pixel draws a whole swing in two positions, empty and full, which reads
	-- as a bar that teleports rather than as a bar that has not been laid out.
	bar.pixels = 0

	bar.edges = ns.Outline(bar, EDGE[1], EDGE[2], EDGE[3], 1, "OVERLAY")
	return bar
end

--------------------------------------------------------------------------
-- Layout
--
-- Everything a setting can move. Called at login, whenever a number in the
-- panel changes, and whenever the client says a hand has changed. Never from
-- the tick.
--------------------------------------------------------------------------

local function SizeBar(bar, width, height)
	bar.pixels = width
	bar:SetSize(width * unit, height * unit)
	bar:SetMinMaxValues(0, width)
	bar:SetValue(0)
	bar.shownValue = 0
	-- The hairline is one screen pixel and stays one when the zoom grows, which
	-- is what ns.Pixel answers and ns.UI.Unit does not.
	ns.EdgeSize(bar.edges, ns.Pixel(bar))
end

-- The frame and the two bars, made the first time the swing timer is switched
-- on.
--
-- The part ships off. It was built at login anyway, and its ticker was armed at
-- interval zero, so a feature nobody had turned on ran a function on every frame
-- the client drew for the whole session.
local function Build()
	frame = CreateFrame("Frame", FRAME_NAME, UIParent)
	ns.UI.Adopt(frame, ns.db.swingZoom)
	-- And it stands down while a screen window is up. UI/Hush.lua carries the
	-- whole of what that means; what it means here is that the character sheet
	-- is read against the world rather than against this row.
	ns.UI.Hushable(frame)
	unit = ns.UI.Unit(frame)
	place = ns.UI.Placeable(frame, {
		name = "WiggleUI swing",
		moved = function(anchor)
			ns.db.swingPoint = anchor
			SwingGauges.Apply()
		end,
	})

	main = BuildBar(frame, MAIN_FILL)
	main:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	off = BuildBar(frame, OFF_FILL)
	-- Anchored after both bars exist, because the off hand hangs off the main
	-- hand's bottom edge and the gap between them is a design number rather than
	-- a share of anything.
	off:SetPoint("TOPLEFT", main, "BOTTOMLEFT", 0, -GAP * unit)
	ns.Theme.Wear("swing", frame)
	built = true
end

-- The tick, armed by the switch going on and stopped by it going off.
--
-- It lives on the events frame, which is never hidden. On the gauges it would
-- stop the moment the bars hid and never come back, which is the trap
-- Charge/Icon.lua already carries a note about, and Update's first line is what
-- makes a hidden pair of bars free.
--
-- ns.UI.Ticker refuses a second running tick of one name on one frame, so the
-- tick is kept here and started again rather than made again.
local function Beat()
	if ns.db.swing then
		if not tick then
			tick = ns.UI.Ticker(ns.UI.Forever, 0, "swing", SwingGauges.Update)
		elseif not tick:Running() then
			tick:Start()
		end
	elseif tick then
		tick:Stop()
	end
end

function SwingGauges.Apply()
	if not built then
		if not ns.db.swing then
			return
		end
		Build()
	end

	local db = ns.db
	local point = db.swingPoint
	frame:ClearAllPoints()
	frame:SetPoint(point[1], UIParent, point[3], point[4], point[5])
	ns.UI.Rezoom(frame, db.swingZoom)
	unit = ns.UI.Unit(frame)

	local width, height = db.swingWidth, db.swingHeight
	dual = ns.Swing.HasOffhand()

	SizeBar(main, width, height)
	SizeBar(off, width, height)
	off:SetShown(dual)

	local total = dual and (height * 2 + GAP) or height
	frame:SetSize(width * unit, total * unit)

	Beat()
	SwingGauges.Lock()
	SwingGauges.Show()
end

-- Whether there is a swing worth drawing on this character right now. A weapon
-- rather than a class, so a hunter standing in melee gets the bars.
function SwingGauges.Applicable()
	return ns.Swing.Ready() and ns.Swing.HasMainhand()
end

function SwingGauges.Show()
	if not built then
		return
	end
	if ns.db.swing and (SwingGauges.Applicable() or not ns.db.locked) then
		frame:Show()
	else
		frame:Hide()
	end
end

-- Locked is the normal state. Unlocked draws an outline and a name, because
-- two thin bars with nothing in them are a piece of empty screen you would
-- otherwise have to find by memory.
function SwingGauges.Lock()
	if not built then
		return
	end
	place:Lock(not ns.db.locked)
	SwingGauges.Show()
end

function SwingGauges.Reset()
	ns.db.swingPoint = ns.DefaultCopy("swingPoint")
	SwingGauges.Apply()
end

-- The two bars, for scripts/harness.lua and for a macro. Handed out rather
-- than kept private for the reason MeterWindow.Pane is: the harness has to
-- measure what was drawn, and measuring it any other way would mean this file
-- publishing its own frame.
function SwingGauges.Bar(which)
	return (which == ns.Swing.OFF) and off or main
end

--------------------------------------------------------------------------
-- Painting
--------------------------------------------------------------------------

-- Fraction returns zero for a hand with no swing running, so a bar between
-- swings draws empty without a branch here.
--
-- The one comparison is the empty bar. A hand that is not swinging answers zero
-- on every frame for as long as you stand there, and writing zero onto a bar
-- already at zero is a measure and a relayout for a bar nobody can see moving.
-- A hand that is swinging fails the test on its first frame and is written on
-- every frame after it, which is what the header above argues for: the velocity
-- of the edge is read out of where it sits between two pixels, and a frame it
-- does not write is a frame it does not move on.
local function DrawHand(bar, which)
	local value = ns.Swing.Fraction(which) * bar.pixels
	if value ~= 0 or bar.shownValue ~= 0 then
		bar.shownValue = value
		bar:SetValue(value)
	end
end

function SwingGauges.Update()
	if not built or not frame:IsShown() then
		return
	end
	DrawHand(main, ns.Swing.MAIN)
	if dual then
		DrawHand(off, ns.Swing.OFF)
	end
end

--------------------------------------------------------------------------
-- Status
--------------------------------------------------------------------------

function SwingGauges.Describe()
	if not ns.db.swing then
		return "off"
	end
	if not ns.Swing.Ready() then
		return "|cffd08040this client has no UnitAttackSpeed|r, so nothing is drawn"
	end
	if not ns.Swing.HasMainhand() then
		return "on, and nothing in your main hand to time"
	end

	local line = ("main hand %.2fs"):format(ns.Swing.Speed(ns.Swing.MAIN))
	if dual then
		line = line .. (", off hand %.2fs"):format(ns.Swing.Speed(ns.Swing.OFF))
	end
	return line
end

--------------------------------------------------------------------------

events = CreateFrame("Frame")

-- No accumulator, because there is no rate to keep. See the header: this is the
-- one thing in the addon that draws motion, and motion is drawn on the frame
-- the screen is drawn on or it is drawn in steps.

events:RegisterEvent("PLAYER_LOGIN")
-- A weapon swap changes how many bars there are, and this addon swaps weapons
-- itself out of the charge macro and out of a loadout key. Both events are
-- taken because one of them is the client telling you the item moved and the
-- other is it telling you the speed did, and neither implies the other on
-- these clients.
--
-- Filtered to the player where the client can filter, for the reason
-- Swing/Swing.lua filters the same two.
ns.RegisterUnitEvent(events, "UNIT_INVENTORY_CHANGED", "player")
ns.RegisterUnitEvent(events, "UNIT_ATTACK_SPEED", "player")
events:SetScript("OnEvent", function(_, event, token)
	if event == "PLAYER_LOGIN" then
		-- Apply is the only way in. It builds nothing while the part is off, and
		-- the switch going on is what calls it next.
		SwingGauges.Apply()
		return
	end

	if token ~= "player" or not built then
		return
	end

	-- Only the one thing these two events can move here, which is how many bars
	-- there are. UNIT_INVENTORY_CHANGED is every bag change as well, and a
	-- layout pass sets the fill back to nothing: run on all of them, the bar
	-- blanked for a frame every time a mob dropped something.
	if ns.Swing.HasOffhand() ~= dual then
		SwingGauges.Apply()
	else
		SwingGauges.Show()
	end
end)

-- A resolution change moves every size in this file at once, the same way it
-- moves the meters.
ns.UI.OnRescale(function()
	SwingGauges.Apply()
end)
