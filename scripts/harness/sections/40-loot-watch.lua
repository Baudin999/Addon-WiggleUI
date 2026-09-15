-- The loot feed's delete list
--
-- 40-loot-remove.lua holds the cross that takes one row out. This is the can
-- beside it, which takes out every row of an item and keeps that item off the
-- feed from then on.
--
-- Four questions. Does pressing the can list the item and sweep every row of
-- it, leaving the rows of other items where they were. Does a later drop of it
-- make no row and no floating message. Is the list impossible to miss: a red
-- control on the strip with the count on it, holding the strip up even with
-- the chips off. And does pressing that control empty the list, take the strip
-- back down, and let the item make a row again.

local H = ...
local ns, fire, check, advance = H.ns, H.fire, H.check, H.advance

local Loot = ns.LootFeed
local lootStream = Loot.Stream()
local feed = lootStream:Feed()

local function frame()
	local tick = feed.frame:GetScript("OnUpdate")
	if tick then
		tick(feed.frame, 1 / 60)
	end
end

-- The stub's own link carries item id 1 for every name, and the list is keyed
-- by id, so two items need two ids written out.
local function link(id, name)
	return ("|cffffffff|Hitem:%d::::::::60:::::|h[%s]|h|r"):format(id, name)
end
local LINEN, WOOL = link(2589, "Linen Cloth"), link(2592, "Wool Cloth")

local function sentence(item)
	return ("You receive loot: %s."):format(item)
end

local function loot(item)
	fire("CHAT_MSG_LOOT", sentence(item))
	frame()
end

----------------------------------------------------------------------
-- The can on a row
----------------------------------------------------------------------

do
	feed:Clear()
	Loot.Unwatch()
	check(feed.list ~= nil and not feed.list:IsShown(),
		"the delete list's control is up with nothing on the list")

	-- Two rows of linen with wool between them, a minute apart so they do not fold.
	loot(LINEN)
	advance(61)
	loot(WOOL)
	advance(61)
	loot(LINEN)
	check(feed:Count() == 3, ("three pickups and the feed holds %d"):format(feed:Count()))

	local row = feed:Row(1)
	check(row.trash ~= nil, "a loot row has no can")
	H.mouse.Place(H.mouse.Point(row))
	row:GetScript("OnEnter")(row)
	check(row.trash:IsShown() and row.cross:IsShown(),
		"pointing at a row did not bring up both its buttons")
	check(row.trash:GetRight() <= row.cross:GetLeft() + 0.01,
		"the can is drawn over the cross rather than beside it")

	-- Onto the can is still the row, the same as onto the cross.
	H.mouse.Place(H.mouse.Point(row.trash))
	row:GetScript("OnLeave")(row)
	check(feed.hovered == 1 and row.trash:IsShown(),
		"moving onto the can took the row's hover and the can with it")

	H.mouse.On(row.trash)
	check(feed:Count() == 1 and feed:Held(0).link == WOOL,
		"the can left a row of the item it put on the list, or took the wool with it")
	check(Loot.Listed(LINEN) and not Loot.Listed(WOOL),
		"the can listed the wrong item")
	check(feed.list:IsShown() and feed.list.count:GetText() == "1",
		("the strip does not show a delete list of one: %s"):format(tostring(feed.list.count:GetText())))
	feed:Leave()

	----------------------------------------------------------------------
	-- A listed item arriving
	----------------------------------------------------------------------

	loot(LINEN)
	local items, refused = Loot.List()
	check(feed:Count() == 1 and items == 1 and refused == 1,
		("a listed drop: %d rows, %d listed, %d refused"):format(feed:Count(), items, refused))

	local floating = ns.db.lootFloat
	ns.db.lootFloat = true
	check(ns.Floats.OnLoot(sentence(LINEN)) == false,
		"a listed item still floats across the screen")
	ns.db.lootFloat = floating

	----------------------------------------------------------------------
	-- The strip, with the chips off
	----------------------------------------------------------------------

	local chips, header = ns.db.lootFeedFilters, ns.db.lootFeedHeader
	ns.db.lootFeedFilters, ns.db.lootFeedHeader = false, false
	lootStream:Apply()
	check(feed.head > 0 and feed.list:IsShown(),
		"with the chips and the title off the delete list took the strip down")

	H.mouse.On(feed.list)
	check(Loot.List() == 0, "pressing the delete list's control left items on it")
	check(feed.head == 0 and not feed.list:IsShown(),
		"the strip stayed up for an empty list with the chips and the title off")

	loot(LINEN)
	check(feed:Held(0).link == LINEN, "an item taken off the list still makes no row")

	ns.db.lootFeedFilters, ns.db.lootFeedHeader = chips, header
	lootStream:Apply()
	check(not feed.list:IsShown(), "the delete list's control came back with the chips")
	feed:Clear()
end
