-- The swing timer, as a person sees it
--
-- The section above asserts the arithmetic and every one of its assertions
-- passed while the bar was unusable in game. What was wrong is not
-- arithmetic: the bar moved in steps, and it took two goes to find out why,
-- because there were two throttles on one edge and removing the first left
-- the second.
--
-- The first was a 20 Hz ticker. The second was the rounding: the fill was
-- snapped to a whole pixel, so it could only change value 53 times a second at
-- the shipped width however often the tick ran. A 144 Hz screen drew the same
-- position on 91 of its 144 frames, and each move was a whole design unit,
-- which is three screen pixels at swing zoom 3.
--
-- No assertion in this file can prove that a bar looks smooth. Smooth is a
-- property of a screen and an eye, and the stub has neither. What can be
-- proved is the property that leaves the client nothing to be blamed for, and
-- it is one sentence: on every frame it is given, the addon hands the widget
-- the exact position the elapsed time puts the edge at. So the fill is driven
-- across a whole swing at two frame rates and three things are asserted, none
-- of which is a tolerance. The drawn position equals elapsed over duration
-- times the width, exactly. The value changes on every frame, with no frame
-- repeating the one before it. And every step is the same size as every other,
-- which is what constant velocity means and what a quantiser destroys.
--
-- The second of those is also the gate on the addon's second pixel rule: a
-- moving fill is not quantised. Reintroduce a Whole() around the fill and the
-- repeated frames come back and this fails.

local H = ...
local guids = H.guids
local advance, itemLink, swing = H.advance, H.itemLink, H.swing
local ns, fire, check = H.ns, H.fire, H.check

-- One frame on a 60 fps client. The fill test below runs at 144 fps as well,
-- because a rounded fill is worse on a faster screen and an addon that only
-- ever looked right at 60 is an addon that looks wrong on half the monitors
-- sold. Everything else in the section is about drawing rather than rate and
-- uses the 60 fps figure.
local FRAME = 1 / 60
local FAST_FRAME = 1 / 144

guids.player = "Player-0-0000000f"
swing.mainhand = itemLink("Arcanite Reaper")
swing.main, swing.off, swing.offhand = 3.4, nil, nil
fire("PLAYER_ENTERING_WORLD")
ns.SwingGauges.Apply()

local ticker = H.tick("swing")

local bar = ns.SwingGauges.Bar(ns.Swing.MAIN)
local width = ns.db.swingWidth

-- One frame of the client, through whatever the ticker decides to do with it.
-- Only the fill test below uses this, because it is the only test about the
-- rate rather than about the drawing.
local function tick(interval)
	ticker:Beat(interval or FRAME)
end

-- The layout has run, so the bar counts in its own width rather than in the
-- one pixel it was built with. A bar left on the seed draws a whole swing in
-- two positions.
check(bar.pixels == width,
	("the bar counts to %s and the setting says %d"):format(tostring(bar.pixels), width))

----------------------------------------------------------------------------
-- The fill, frame by frame
----------------------------------------------------------------------------

do
	local SPEED = 3.4

	-- How close "exactly" can be, on the clock this section happens to run at.
	--
	-- The two checks below read `< 1e-9`, which reads as a spelling of zero and
	-- was in fact the measured drift with about a tenth of a decimal place to
	-- spare. It held for as long as the stub clock was still near the 100 seconds
	-- it starts at. 04-ability-square.lua sweeps a three hour cooldown twice to
	-- weigh what the countdown allocates, so every section after it now runs at
	-- about twenty-two thousand seconds, the drift went to 3.8e-8, and this failed
	-- with the fill exact and the arithmetic sound.
	--
	-- The drift is not the addon's and it is not noise. `elapsed` below counts up
	-- from nothing and the stub clock counts up from wherever the run has got to,
	-- so the two sums round differently, by at most one unit in the last place of
	-- the clock on each frame. Seconds become pixels at `width / SPEED`, which is
	-- 97 of them a second, and the walk takes 490 frames at 144 fps. That product
	-- is the whole of it, and it is what the bound is made of, times four for
	-- headroom. It is 9e-7 px at the clock this runs at today and 4e-9 at the one
	-- the file was written against, so a clock wound further on still fails for a
	-- real defect rather than for its own arithmetic.
	--
	-- Still an exact comparison rather than a tolerance, which is what the note
	-- under it claims. The defect this catches is a fill snapped to a whole pixel,
	-- and that is half a pixel out at worst: five orders of magnitude above this
	-- bound at any clock the suite will reach.
	local ULP = 2 ^ -52
	local function exactly(frames)
		return 4 * frames * ULP * math.max(_G.GetTime(), 1) * width / SPEED
	end

	-- One swing, one frame at a time, reading the widget rather than the field
	-- beside it. Three numbers come back: the worst distance between what was
	-- drawn and where the elapsed time says the edge belongs, how many frames
	-- drew the same position as the frame before them, and the widest and
	-- narrowest step taken.
	--
	-- The elapsed time is accumulated here in the same order the stub clock
	-- accumulates it, so the two agree bit for bit and the comparison can be an
	-- exact one. A tolerance would let a rounded fill through at any width where
	-- a pixel is small.
	local function run(interval)
		swing.main = SPEED
		fire("UNIT_ATTACK_SPEED", "player")
		ns.Swing.Start(ns.Swing.MAIN)
		tick(interval)

		local elapsed, frames, repeated = 0, 0, 0
		local worst, widest, narrowest = 0, 0, math.huge
		local last = bar:GetValue()
		while elapsed + interval < SPEED do
			advance(interval)
			elapsed = elapsed + interval
			tick(interval)

			local at = bar:GetValue()
			local off = math.abs(at - elapsed / SPEED * width)
			if off > worst then
				worst = off
			end
			local step = at - last
			if step == 0 then
				repeated = repeated + 1
			end
			if step > widest then
				widest = step
			end
			if step < narrowest then
				narrowest = step
			end
			last = at
			frames = frames + 1
		end
		return frames, worst, repeated, widest - narrowest
	end

	for _, pass in ipairs{ { FRAME, 60 }, { FAST_FRAME, 144 } } do
		local frames, worst, repeated, spread = run(pass[1])
		check(worst < exactly(frames),
			("at %d fps the fill was drawn %.4f px from where the elapsed time puts it")
				:format(pass[2], worst))
		check(repeated == 0,
			("at %d fps the fill drew the same position twice on %d of %d frames, and a frame it does not move on is a frame the eye reads as a stall")
				:format(pass[2], repeated, frames))
		check(spread < exactly(frames),
			("at %d fps the widest step was %.6f px more than the narrowest, and a fill at constant velocity takes one step size")
				:format(pass[2], spread))
	end

	-- And the positive form of the addon's second pixel rule, stated on its own
	-- so that deleting the three assertions above cannot quietly take it with
	-- them: the fill really does sit between pixels. A whole number every frame
	-- is a quantiser, and a quantiser is the defect this section exists for.
	ns.Swing.Start(ns.Swing.MAIN)
	local fractional = 0
	for _ = 1, 60 do
		advance(FRAME)
		tick()
		local at = bar:GetValue()
		if math.abs(at - math.floor(at + 0.5)) > 1e-6 then
			fractional = fractional + 1
		end
	end
	check(fractional >= 50,
		("the fill landed off a whole pixel on %d of 60 frames, and a moving fill is not quantised")
			:format(fractional))
end

----------------------------------------------------------------------------
-- The width
--
-- A wider bar is the same swing drawn on more pixels, and the fill's scale has
-- to follow the setting in the same layout pass. Left on the old scale the bar
-- counts to 330 on a widget 240 wide, and every swing runs off the end of it.
----------------------------------------------------------------------------

do
	ns.db.swingWidth = 240
	ns.SwingGauges.Apply()
	check(bar.pixels == 240,
		("the width went to 240 and the bar still counts to %s"):format(tostring(bar.pixels)))

	ns.Swing.Start(ns.Swing.MAIN)
	advance(1.7)
	ns.SwingGauges.Update()
	check(math.abs(bar:GetValue() - 120) < 1e-6,
		("half a swing on a 240 pixel bar drew %.3f px"):format(bar:GetValue()))

	ns.db.swingWidth = ns.DefaultFor("swingWidth")
	ns.SwingGauges.Apply()
end

----------------------------------------------------------------------------
-- Put the client back the way the sections after this one expect it.
----------------------------------------------------------------------------

guids.player = nil
swing.mainhand, swing.offhand, swing.off = nil, nil, nil
swing.main = 3.4
fire("UNIT_INVENTORY_CHANGED", "player")
ns.Swing.Stop(ns.Swing.MAIN)
ns.Swing.Stop(ns.Swing.OFF)

-- The two section 26 pinned to the design scene, back to what the addon ships.
ns.db.swing = ns.DefaultFor("swing")
ns.db.swingZoom = ns.DefaultFor("swingZoom")
ns.SwingGauges.Apply()
