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

-- The swap
--
-- The harness loads informational, which wiggles to nothing out of the box, so
-- a pin there changes nothing. Aimed at exploration, a pin redresses every worn
-- frame with exploration's modes, and dropping it puts informational back.

local Theme = ns.Theme
check(Theme.Showing() == "informational", "the harness is not showing informational at load")
check(not Theme.Pinned(), "a theme with no target loaded wiggled")
Theme.Pin(true)
check(not Theme.Pinned(), "a wiggle with no target was taken")

local heard = {}
Theme.OnPin(function(on) heard[#heard + 1] = on end)
local style = ns.ProgressRails.Describe()

-- A frame of every mode exploration has, worn the way a part wears one.
local function Worn(key)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(40, 40)
	frame:SetPoint("CENTER")
	Theme.Wear(key, frame)
	return frame
end
local chat, meters, player = Worn("chat"), Worn("meters"), Worn("player")
check(UI.Veiled(player) == nil, "an element shown in both themes took a veil")

ns.db.wiggleInformational = "exploration"
Theme.Aim()
check(UI.Ticking("wiggle") ~= nil, "a theme with a target does not read the mouse")
check(UI.Veiled(chat) and UI.Veiled(meters),
	"aiming at a target that dresses differently left an element unveiled")
check(UI.Veiled(chat):GetAlpha() == 1 and UI.Veiled(meters):IsShown(), "aiming alone changed the screen")

Theme.Pin(true)
check(Theme.Pinned() and Theme.Showing() == "exploration" and ns.db.wiggled,
	"the wiggle did not swap to its target, or did not save it")
check(heard[#heard] == true, "the wiggle was not heard by its watcher")
check(Theme.Mode("meters") == "hide", "a part asking for a mode still reads the theme at rest")
check(not UI.Veiled(meters):IsShown(), "the wiggle to exploration left the meters up")
check(UI.Veiled(chat):GetAlpha() == 0 and chat.wkReveal and chat.wkReveal:IsShown(),
	"the wiggle to exploration did not put the chat under the pointer")
check(ns.ProgressRails.Describe():find("minimal", 1, true),
	"exploration on the screen did not draw the minimal rail")

Theme.Pin(false)
check(not Theme.Pinned() and Theme.Showing() == "informational" and not ns.db.wiggled,
	"the second wiggle did not swap back")
check(heard[#heard] == false, "the swap back was not heard by its watcher")
check(UI.Veiled(meters):IsShown() and UI.Veiled(chat):GetAlpha() == 1,
	"the swap back left an element dressed for exploration")
check(not chat.wkReveal:IsShown(), "the swap back left a catcher over the chat window")
check(ns.ProgressRails.Describe() == style, "the swap back did not put the rail's style back")

ns.db.wiggleInformational = "none"
Theme.Aim()
check(not UI.Ticking("wiggle"), "a theme aimed at nothing still reads the mouse")
chat:Hide()
meters:Hide()
player:Hide()
