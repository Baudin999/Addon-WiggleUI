-- The purse sliding out from behind the loot feed
--
-- Feeds/Drawer.lua carries the argument. Here because the slide is a tween on
-- Ck/Animations.lua's one tick, and every section above 79-floating-messages
-- has to leave that tick alone: a beat from up there would expire the drops
-- that section asserts are still in the air. 81-gear-arrival runs the list out
-- and hands it over empty, and this hands it on empty.
--
-- Each check is a way the drawer could look right in a still picture and be
-- wrong in the hand:
--
--   A pointer passing over the figure opens it. The wait is what stops that,
--   and it is the hover boxes' wait rather than one of its own.
--
--   The panel arriving over the feed rather than out from under it. It starts
--   past the clip's edge, inside the feed, travels to the clip's origin, and
--   sits a level under the rows it comes out from.
--
--   Going from the figure to the panel closes it. The pointer crosses the feed
--   to get there, and the leave has the same wait the enter has.
--
--   A turn part way. Coming back while it slides in reverses it from where it
--   stands, at once, rather than finishing the close and waiting to open.
--
--   Nothing moving at rest. Out or in, the tween list is empty.
--
--   Off the screen. A feed against the left edge opens it to the right.

local H = ...
local ns, check = H.ns, H.check

local Animations = ns.Ck.Animations
local HOLD = ns.Tip.HOLD
local FRAME = 1 / 60

-- One frame of the client for everything on the tween list, and the wall clock
-- moved with it, because a frame is both. 81-gear-arrival's own shape.
local function beat(seconds)
	while seconds > 0 do
		local step = (seconds < FRAME) and seconds or FRAME
		local tick = ns.UI.Ticking("anim")
		if tick then
			tick:Beat(step)
		end
		H.advance(step)
		seconds = seconds - step
	end
end

local stream = ns.LootFeed.Stream()
local hit, drawer = stream:Figure()
check(hit ~= nil and drawer ~= nil, "the loot feed has no figure or no drawer behind it")
local clip, panel = drawer:Parts()
local SLIDE = ns.db.lootFloatSeconds

local function enter(frame)
	frame:GetScript("OnEnter")(frame)
end

local function leave(frame)
	frame:GetScript("OnLeave")(frame)
end

-- Where the panel stands in its clip. Nought is all the way out.
local function x()
	return select(4, panel:GetPoint(1))
end

check(Animations.Running() == 0, "the tween list was handed over with something on it")

-- Every frame in the harness starts at level nought, so the feed is lifted to
-- give the panel a level to sit under.
local feedFrame = stream:Feed().frame
feedFrame:SetFrameLevel(5)

-- And UIParent has no size, so every frame hung off its right edge stands left
-- of the screen. A screen is put under it for the side the panel picks, and
-- taken away at the foot.
local screenWidth, screenHeight = _G.UIParent:GetWidth(), _G.UIParent:GetHeight()
_G.UIParent:SetSize(1920, 1080)

------------------------------------------------------------
-- Passing over
------------------------------------------------------------

enter(hit)
check(not clip:IsShown(), "the panel opened the moment the pointer arrived")
beat(HOLD / 2)
leave(hit)
beat(HOLD * 2)
check(not clip:IsShown() and Animations.Running() == 0,
	"a pointer crossing the figure on its way somewhere else opened the panel")

------------------------------------------------------------
-- Out
------------------------------------------------------------

enter(hit)
beat(HOLD + FRAME)
check(clip:IsShown(), "the wait ran out and the panel did not come")

local _, _, side = drawer:Parts()
check(side == "left", "a feed on the right of the screen opened its panel to the " .. tostring(side))
local point, anchor, relative = clip:GetPoint(1)
check(point == "TOPRIGHT" and anchor == _G.WiggleUILootFeed and relative == "TOPLEFT",
	("the clip hangs %s off the feed's %s, so the panel does not come out of its left edge")
		:format(tostring(point), tostring(relative)))
check(panel:GetFrameLevel() == 4 and clip:GetFrameLevel() == 4,
	("the panel is at level %s under a feed at 5"):format(tostring(panel:GetFrameLevel())))

local width = panel:GetWidth()
check(width > 0, "the panel drew nothing")
check(clip:GetWidth() == width, "the clip is not the panel's width, so it shows the wrong slice")
local start = x()
check(start > 0 and start <= width,
	("the panel starts %s units along a clip %s wide, so it is not tucked behind the feed")
		:format(tostring(start), tostring(width)))

beat(SLIDE / 2)
local halfway = x()
check(halfway > 0 and halfway < start,
	("halfway through the slide it stands at %s, from %s"):format(tostring(halfway), tostring(start)))
-- The drops' curve is fast first: past the middle of the distance by the
-- middle of the time.
check(halfway < width / 2, "the slide is not on the drops' Ease.out")

beat(SLIDE)
check(x() == 0, ("the panel stopped %s units short of all the way out"):format(tostring(x())))
check(drawer:Out() == true, "the panel is out and does not say so")
check(Animations.Running() == 0, "the panel is at rest and something is still on the tween list")

-- What it shows is the purse tooltip's, drawn by the tooltip's own renderer.
local titled = false
for _, region in ipairs({ panel:GetRegions() }) do
	if region.GetText and region:GetText() == "The purse" then
		titled = true
	end
end
check(titled, "the panel does not say it is the purse")
check(panel.ground ~= nil, "the panel was never given the tooltip's floor")

------------------------------------------------------------
-- From the figure to the panel
------------------------------------------------------------

leave(hit)
beat(HOLD / 2)
enter(panel)
beat(HOLD * 2)
check(x() == 0 and drawer:Out() == true,
	"moving from the figure onto the panel folded it away")

------------------------------------------------------------
-- In, and turned round part way
------------------------------------------------------------

leave(panel)
beat(HOLD + FRAME)
beat(SLIDE * 0.3)
local closing = x()
check(closing > 0 and closing < width,
	("leaving the panel did not start it back in; it stands at %s"):format(tostring(closing)))

enter(hit)
beat(FRAME * 3)
check(x() < closing,
	("coming back mid slide did not turn it round: %s from %s"):format(tostring(x()), tostring(closing)))
beat(SLIDE)
check(x() == 0 and drawer:Out() == true, "the turn did not finish all the way out")

leave(hit)
beat(HOLD + SLIDE + FRAME * 3)
check(x() == width, ("the panel went back to %s rather than behind the feed"):format(tostring(x())))
check(not clip:IsShown() and drawer:Out() == false,
	"the panel slid in and was left drawn")
check(Animations.Running() == 0, "the panel is in and something is still on the tween list")

------------------------------------------------------------
-- No room on the left
------------------------------------------------------------

local placed = ns.db.lootFeedPoint
stream:Reset({ "LEFT", "UIParent", "LEFT", 10, 0 })
enter(hit)
beat(HOLD + FRAME)
local _, _, flipped = drawer:Parts()
check(flipped == "right", "a feed against the left edge opened its panel off the screen")
check(x() < 0, ("opening right, the panel starts at %s rather than tucked to the left"):format(tostring(x())))
beat(SLIDE + FRAME)
check(x() == 0, "opening right, the panel did not come all the way out")
leave(hit)
beat(HOLD + SLIDE + FRAME * 3)
check(not clip:IsShown(), "opening right, the panel did not go back")

stream:Reset(placed)
feedFrame:SetFrameLevel(0)
_G.UIParent:SetSize(screenWidth, screenHeight)
check(Animations.Running() == 0, "the drawer hands the tween list on with something on it")

print(("drawer %s wide, out and in over %.2fs after a %.2fs wait, turned round from %s"):format(
	tostring(width), SLIDE, HOLD, tostring(closing)))
