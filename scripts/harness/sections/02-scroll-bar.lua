-- The scroll view and the bar down its right
--
-- ns.UI.ScrollView and ns.UI.ScrollBar on their own, before any window built
-- out of them, for the reason 02-layout-engine goes here: a scroll bug found
-- inside the quest log is an hour of reading three files, and the same bug
-- named here is one line.
--
-- Two questions, and the client is the whole of both.
--
-- Which way the canvas moves. The offset counts down from the top of the
-- content, and the canvas has to rise as it grows, because what a viewport
-- shows is whatever is in front of it.
--
-- Which way up the slider's track is. A vertical Slider's thumb moves from the
-- top of the track to the bottom as its value rises, which is the direction
-- the offset counts in, so the value on the bar is the offset itself. Nothing
-- about that is visible from the addon's side: the value goes in, the value
-- comes out, and only a hand on the thumb in the game says which end of the
-- track it was at. So what is asserted here is that nothing happens to the
-- number on the way through. At the top of the content the bar stands at its
-- minimum, and a drag reporting a larger value, which is the client's word for
-- a thumb pulled down, scrolls the content down. A mirror between the two,
-- which is what 30958cfa put here, fails four of the lines below.

local H = ...
local ns, check = H.ns, H.check
local UI = ns.UI

local PORT, CONTENT = 100, 300

-- Half a unit of slack on every distance below. The view snaps its offset to
-- whole physical pixels and a unit is not one of those on any screen but the
-- one the addon was drawn on, so two hundred units of scrolling comes back as
-- two hundred and a fifth. A page that scrolled the wrong way is out by all of
-- it.
local function Near(a, b)
	return math.abs(a - b) < 0.5
end

local host = CreateFrame("Frame", nil, _G.UIParent)
host:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", 0, 0)
host:SetSize(200, PORT)

local view = UI.ScrollView(host)
view:Resize(200, PORT)
local filling = CreateFrame("Frame", nil, view.canvas)
filling:SetPoint("TOPLEFT")
filling:SetSize(view.width, CONTENT)
view:Update(CONTENT)

local room = CONTENT - PORT
check(view.scrollable, "a view with three times its own height of content does not scroll")
check(view.bar ~= nil, "the scroll view made no bar, and this client has the Slider type")

----------------------------------------------------------------------
-- The canvas
----------------------------------------------------------------------

local top = view.canvas:GetTop()
view:ScrollTo(room)
check(Near(view.offset, room), ("scrolling to the end landed at %.1f, not %.1f"):format(view.offset, room))
check(Near(view.canvas:GetTop() - top, room),
	("scrolling down %.0f moved the canvas %.1f, and down the page is up the canvas")
		:format(room, view.canvas:GetTop() - top))

----------------------------------------------------------------------
-- The bar, mirrored
----------------------------------------------------------------------

local bar = view.bar
local low, high = bar:GetMinMaxValues()
check(low == 0 and high == room,
	("the bar's range is %s to %s and the room is %.0f"):format(tostring(low), tostring(high), room))

check(bar:GetValue() == room, "at the end of the content the bar is not at the bottom of its track")
view:ScrollTo(0)
check(bar:GetValue() == 0, "at the top of the content the bar is not at the top of its track")

-- What the client reports as the thumb is dragged: a value off the track, the
-- minimum at the top of it. Written straight onto the widget, the way the drag
-- writes it, so the page is moved from the same end the player is on.
bar:SetValue(room)
check(Near(view.offset, room),
	("dragging the thumb to the bottom left the page at %.1f, not %.1f"):format(view.offset, room))
bar:SetValue(0)
check(Near(view.offset, 0), ("dragging the thumb to the top left the page at %.1f"):format(view.offset))
bar:SetValue(room / 2)
check(Near(view.offset, room / 2),
	("dragging the thumb halfway left the page at %.1f, not %.1f"):format(view.offset, room / 2))

host:Hide()
