-- The strip over the loot feed
--
-- 40-loot-feed.lua holds what a chip filters. This is what the strip is drawn
-- as and the one control on it that is not a chip, in a file of its own because
-- that one is at its ceiling.
--
-- Three questions. Is each run of chips one bar, with its cells flush inside it
-- and the break between two bars the only air on the strip. Does the reason
-- chip draw the ring a row draws rather than a glyph, which at chip size was a
-- filled white disc. And does the reset come up when a chip goes off, put every
-- chip back when it is pressed, and go when the strip goes.

local H = ...
local ns, check = H.ns, H.check

local Loot = ns.LootFeed
local lootStream = Loot.Stream()
local feed = lootStream:Feed()

----------------------------------------------------------------------
-- The bars
--
-- Five qualities, a break, then quest, reason and coin. Eight squares with a
-- hairline each was the version this replaced, and what made it read as a row
-- of emoji was that the break between the runs looked like the gaps inside
-- them. So the claim is about edges: a bar starts at its first cell and ends at
-- its last, the cells meet, and the two bars do not.
----------------------------------------------------------------------

do
	local function Edge(region, side)
		return ns.Measure(region, side)
	end
	local function Same(a, b)
		return math.abs(a - b) < 0.01
	end

	check(#feed.bars == 2,
		("the loot feed's chips stand on %d bars, not on one per run"):format(#feed.bars))
	local first, second = feed.bars[1], feed.bars[2]
	check(Same(Edge(first, "GetLeft"), Edge(feed:Chip(1), "GetLeft")),
		"the first bar does not start at the first chip")
	check(Same(Edge(first, "GetRight"), Edge(feed:Chip(5), "GetRight")),
		"the first bar does not end at the fifth chip")
	check(Same(Edge(feed:Chip(2), "GetLeft"), Edge(feed:Chip(1), "GetRight")),
		"two chips inside one bar do not meet")
	check(Same(Edge(second, "GetLeft"), Edge(feed:Chip(6), "GetLeft")),
		"the second bar does not start at the quest chip")
	check(Edge(second, "GetLeft") > Edge(first, "GetRight"),
		"the two bars touch, so the break between the runs is gone")
	check(feed:Chip(1):GetFrameLevel() > first:GetFrameLevel(),
		"a chip is not drawn over the bar it sits on")
end

-- The reason chip is the seventh, after the five qualities and the quest chip.
do
	local reason = feed:Chip(7)
	check(reason.mark:GetObjectType() == "Frame",
		"the reason chip draws a glyph rather than the ring a row draws round its icon")
	check(reason.mark.edges ~= nil, "the reason chip's ring has no edge to draw")
end

----------------------------------------------------------------------
-- The reset
----------------------------------------------------------------------

do
	local reset = feed.reset
	check(reset ~= nil, "the loot feed has no reset")
	check(not reset:IsShown(), "the reset is up with every chip on")

	Loot.Light(1, false)
	ns.db.lootFeedMoney = false
	feed:Chipped()
	check(reset:IsShown(), "two chips are off from the panel and the reset is not up")

	-- Hidden with the strip, because a reset for a filter that is not running is
	-- a control with nothing behind it.
	ns.db.lootFeedFilters = false
	lootStream:Apply()
	check(not reset:IsShown(), "the strip is hidden and its reset is still up")
	ns.db.lootFeedFilters = true
	lootStream:Apply()
	check(reset:IsShown(), "the strip came back without its reset")

	H.mouse.On(reset)
	check(Loot.Lit(1) and ns.db.lootFeedMoney, "pressing the reset left a chip off")
	check(feed:Chip(2).lit and feed:Chip(8).lit,
		"pressing the reset turned the chips on and left their marks dim")
	check(feed:Shown() == feed:Count(),
		("after the reset the column draws %d of the %d it holds"):format(feed:Shown(), feed:Count()))
	check(not reset:IsShown(), "the reset is still up with nothing left to undo")

	-- And from the strip itself, which is where somebody actually turns one off.
	H.mouse.On(feed:Chip(6))
	check(reset:IsShown(), "clicking the quest chip off did not bring the reset up")
	H.mouse.On(feed:Chip(6))
	check(not reset:IsShown(), "clicking the quest chip back on left the reset up")

	ns.db.lootFeedMouse = false
	lootStream:Apply()
	check(not reset:IsMouseEnabled(), "the reset still takes the mouse with the feed set to a picture")
	ns.db.lootFeedMouse = true
	lootStream:Apply()
	check(reset:IsMouseEnabled(), "the reset does not take the mouse with the setting back on")
end
