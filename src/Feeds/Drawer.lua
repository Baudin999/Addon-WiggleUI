local ADDON, ns = ...

local Drawer = {}
ns.Drawer = Drawer

local UI = ns.UI
local Animations = ns.Ck.Animations

--------------------------------------------------------------------------
-- A panel that slides out from behind a feed
--
-- The purse was a strip of three numbers under the loot feed and a tooltip on
-- top of that. The strip went and one figure took the right end of the header;
-- what the tooltip said now lives on a panel that comes out from behind the
-- feed's left edge while you hover that figure, and goes back in when you stop.
--
-- **Behind, not over.** The panel sits in a frame that clips it, and the clip's
-- edge is the feed's edge. At rest the panel is wholly past that edge, inside
-- the feed's rectangle, so nothing of it is drawn; travelling out it appears a
-- column at a time from under the feed. The feed is see-through, so without the
-- clip the tucked-in panel would show through the rows it is meant to be
-- under. The clip and the panel are also one level under the feed, so the rows
-- are drawn over the seam.
--
-- **Hover opens it and hover closes it.** There is no click. The pointer has to
-- rest on the figure for UI/Tip.lua's HOLD before it opens, the same wait every
-- hover box in the addon takes, so a pointer crossing the header on its way to
-- a row opens nothing. Leaving takes the same wait before it closes, and the
-- panel counts as still hovered: the pointer goes from the figure to the panel
-- across the width of the feed, and the wait is what lets it arrive. Coming back
-- while it is moving turns it round where it is, with no wait, because the hand
-- has already said what it wants.
--
-- **The drops' motion, not a curve of its own.** Ck/Float.lua moves a drop in
-- on Ease.out over lootFloatSeconds, and this is the same curve over the same
-- setting. A turn part way through runs for the share of that time the
-- distance left is of the whole, so it keeps the drops' speed rather than
-- taking a full slide to cover a sliver.
--
-- **Nothing moves while nothing is moving.** Both the wait and the slide are
-- tweens on Ck/Animations.lua's one tick, which stops when the last tween
-- lands. A panel at rest, in or out, costs no frame at all.
--------------------------------------------------------------------------

-- The curve Ck/Float.lua moves a drop on. Feeds/Floats.lua does not name one,
-- so a drop gets the library's default, and this is it by name.
local EASE = Animations.Ease.out

-- The drops' travel time, which is a setting. Read at each slide so a slider
-- moved on the floats page moves this too.
local function Seconds()
	return ns.db.lootFloatSeconds
end

local Panel = {}
Panel.__index = Panel

-- owner    the frame the panel comes out from behind, which is a stream's
-- under    the frame whose level the panel sits one under, which is the feed
-- describe function(), answering the UI/Tip.lua subject the panel shows
function Drawer.New(owner, under, describe)
	local clip = CreateFrame("Frame", nil, owner)
	-- On this client SetClipsChildren is on every frame. Probed rather than
	-- called because UI/Scroll.lua and UI/Chart.lua probe it, and a client
	-- without it draws the panel unclipped rather than failing to load.
	if type(clip.SetClipsChildren) == "function" then
		clip:SetClipsChildren(true)
	end
	clip:Hide()

	local box = UI.Tooltip.Surface(clip)
	local drawer = setmetatable({
		owner = owner, under = under, describe = describe,
		clip = clip, box = box, panel = box.frame,
		-- Which of the figure and the panel the pointer is on.
		over = {},
		want = false,
		-- At rest out, at rest in, or nil while it travels.
		out = false,
		-- Where the panel stood when its last run was armed, and the offset
		-- that is all the way in. Signed: in is to the right when it opens to
		-- the left, and to the left when it opens to the right.
		x = 0, hidden = 0,
		side = "left",
	}, Panel)

	drawer.wait = Animations.New(clip)
	drawer.wait.drawer = drawer
	drawer.slide = Animations.New(box.frame)
	drawer.slide.drawer = drawer

	box.frame:EnableMouse(true)
	box.frame:SetScript("OnEnter", function() drawer:Enter("panel") end)
	box.frame:SetScript("OnLeave", function() drawer:Leave("panel") end)
	UI.PassCamera(box.frame)
	return drawer
end

--------------------------------------------------------------------------
-- Moving
--------------------------------------------------------------------------

-- Where the panel is, as an offset from all the way out. The tween writes what
-- it last put on the frame and Arm clears it, so between an arm and the first
-- frame of the run the answer is where the run starts.
local function Position(drawer)
	return drawer.slide.atX or drawer.x
end

-- hot: Landed is a tween's onDone, called back through the field when the panel has finished sliding
local function Landed(tween)
	local drawer = tween.drawer
	drawer.out = drawer.want
	if not drawer.out then
		drawer.clip:Hide()
	end
end

-- The panel drawn, placed and parked all the way in, on the side there is room
-- on. False for a subject with nothing in it, which opens nothing.
--
-- The left side unless the feed is closer to the left edge of the screen than
-- the panel is wide, and then the right: the panel slides out over the world
-- either way, and one that slid off the screen would be the purse you asked
-- for, drawn where you cannot read it.
-- cold: Fill draws the panel once, on the frame the hover wait ran out
local function Fill(drawer)
	local width, height = UI.Tooltip.Paint(drawer.box, ns.Tip.Build(drawer.describe()))
	if not width then
		return false
	end
	local owner, clip = drawer.owner, drawer.clip
	local left = owner:GetLeft() or 0
	drawer.side = (left < width) and "right" or "left"

	clip:ClearAllPoints()
	if drawer.side == "left" then
		clip:SetPoint("TOPRIGHT", owner, "TOPLEFT", 0, 0)
		drawer.hidden = width
	else
		clip:SetPoint("TOPLEFT", owner, "TOPRIGHT", 0, 0)
		drawer.hidden = -width
	end
	clip:SetSize(width, height)

	local level = math.max(drawer.under:GetFrameLevel() - 1, 0)
	clip:SetFrameLevel(level)
	drawer.panel:SetFrameLevel(level)

	drawer.x = drawer.hidden
	drawer.slide.atX = nil
	drawer.panel:ClearAllPoints()
	drawer.panel:SetPoint("TOPLEFT", clip, "TOPLEFT", drawer.hidden, 0)
	drawer.panel:Show()
	clip:Show()
	return true
end

-- Out or in from wherever it stands, for the share of the drops' time the
-- distance left is of the whole run.
local function Slide(drawer, want)
	if want and drawer.out == false and not drawer.slide.playing then
		if not Fill(drawer) then
			return false
		end
	end
	local from = Position(drawer)
	local to = want and 0 or drawer.hidden
	local share = (drawer.hidden ~= 0) and math.abs(to - from) / math.abs(drawer.hidden) or 0
	drawer.out = nil
	drawer.x = from
	if share <= 0 then
		Animations.Stop(drawer.slide)
		Landed(drawer.slide)
		return true
	end
	Animations.Arm(drawer.slide, Seconds() * share, EASE, 0)
	Animations.Path(drawer.slide, "TOPLEFT", drawer.clip, "TOPLEFT", from, 0, to, 0)
	Animations.Start(drawer.slide, Landed)
	return true
end

-- hot: Due is a tween's onDone, called back through the field when the hover wait runs out
local function Due(tween)
	local drawer = tween.drawer
	Slide(drawer, drawer.want)
end

--------------------------------------------------------------------------
-- The pointer
--------------------------------------------------------------------------

-- The pointer's answer changed. Travelling, the panel turns round at once; at
-- rest where the pointer wants it, any wait the other way is called off; at
-- rest the other way, the wait starts.
function Panel:Want(want)
	if want == self.want then
		return false
	end
	self.want = want
	if self.slide.playing then
		return Slide(self, want)
	end
	if self.out == want then
		Animations.Stop(self.wait)
		return false
	end
	Animations.Arm(self.wait, ns.Tip.HOLD, nil, 0)
	Animations.Start(self.wait, Due)
	return true
end

-- `which` is "figure" or "panel". Either one holds it out.
function Panel:Enter(which)
	self.over[which] = true
	return self:Want(true)
end

function Panel:Leave(which)
	self.over[which] = nil
	return self:Want(next(self.over) ~= nil)
end

-- Put away on the spot, for a purse switched off with the panel out.
function Panel:Shut()
	Animations.Stop(self.wait)
	Animations.Stop(self.slide)
	self.over = {}
	self.want, self.out = false, false
	self.x = self.hidden
	self.clip:Hide()
	return true
end

-- The clip and the panel, and the side it opened on, for scripts/harness.lua.
function Panel:Parts()
	return self.clip, self.panel, self.side
end

-- Out, in, or nil while it travels.
function Panel:Out()
	return self.out
end
