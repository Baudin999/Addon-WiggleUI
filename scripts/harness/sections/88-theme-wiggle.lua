-- The shake
--
-- A shake of the mouse pins the exploration theme's hover elements up and the
-- next one drops them. The detector is the part that can go wrong without a
-- sound: too eager and a pointer crossing the screen flips the chat window
-- away under the player's hand, too strict and the shake does nothing. So both
-- are driven here with the pointer paths a hand actually makes.

local H = ...
local ns, check = H.ns, H.check
local UI = ns.UI

-- A path of x positions, one every fiftieth of a second, which is the rate the
-- tick samples at. Answers whether any sample completed a shake, and on which.
local function Drive(state, path, start)
	local now = start or 100
	for index, x in ipairs(path) do
		if UI.WiggleFeed(state, x, now) then
			return index
		end
		now = now + 0.02
	end
	return nil
end

-- Legs of `span` units, `steps` samples each, starting at 500 and going right.
local function Shake(legs, span, steps)
	local path, x, way = { 500 }, 500, 1
	for _ = 1, legs do
		for _ = 1, steps do
			x = x + way * span / steps
			path[#path + 1] = x
		end
		way = -way
	end
	return path
end

-- Seven legs make six turns, and the sixth completes the shake.
check(Drive(UI.Wiggle(), Shake(7, 80, 5)) ~= nil,
	"seven brisk legs of 80 units did not read as a shake")
check(Drive(UI.Wiggle(), Shake(6, 80, 5)) == nil,
	"six legs, five turns, already read as a shake")

-- A small shake of 40 units is under the span however many times it turns.
check(Drive(UI.Wiggle(), Shake(9, 40, 4)) == nil, "a shake of 40 units read as a shake")

-- A sweep across the screen and back is one turn, however fast.
local sweep = {}
for x = 100, 1500, 70 do sweep[#sweep + 1] = x end
for x = 1500, 100, -70 do sweep[#sweep + 1] = x end
check(Drive(UI.Wiggle(), sweep) == nil, "a sweep across the screen and back read as a shake")

-- A tremor: many turns, every one under the span.
check(Drive(UI.Wiggle(), Shake(12, 20, 2)) == nil, "a tremor of 20 units read as a shake")

-- Slow legs, half a second each, are a hand wandering and not a shake.
check(Drive(UI.Wiggle(), Shake(7, 80, 25)) == nil, "seven slow legs read as a shake")

-- One long shake toggles once, not twice: the detector is deaf for a moment
-- after it answers.
local state, fired, now = UI.Wiggle(), 0, 100
for _, x in ipairs(Shake(12, 80, 5)) do
	if UI.WiggleFeed(state, x, now) then
		fired = fired + 1
	end
	now = now + 0.02
end
check(fired == 1, ("one long shake toggled %d times"):format(fired))

-- And after the quiet a second shake answers again.
check(Drive(state, Shake(7, 80, 5), now + 2) ~= nil, "a second shake after a pause did not answer")

-- Losing the leg, which a camera turn does, means the jump back is not travel.
state = UI.Wiggle()
check(Drive(state, Shake(3, 80, 5)) == nil, "three legs read as a shake")
UI.WiggleLose(state)
check(not UI.WiggleFeed(state, 2000, 100.4), "a jump after a lost leg counted as travel")

-- The harness loads the informational theme, which keeps nothing under the
-- pointer, so it has no reason to read the mouse.
check(not ns.Theme.Hovering(), "informational claims to keep something under the pointer")
check(not ns.Theme.Pinned(), "the pin is up at load")

-- A part watching the pin hears both ways. The experience rail is one, and in
-- informational its style is still the setting's, pinned or not.
local heard = {}
ns.Theme.OnPin(function(on) heard[#heard + 1] = on end)
local style = ns.ProgressRails.Describe()
ns.Theme.Pin(true)
check(heard[#heard] == true and ns.Theme.Pinned(), "a pin was not heard by its watcher")
check(ns.ProgressRails.Describe() == style,
	"a pin moved the experience rail in a theme with nothing under the pointer")
ns.Theme.Pin(false)
check(heard[#heard] == false and not ns.Theme.Pinned(), "a pin dropped was not heard by its watcher")
