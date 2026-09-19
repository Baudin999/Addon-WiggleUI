-- Deleting from the loot feed
--
-- 40-loot-remove.lua holds the ring arithmetic of taking a row out. This is
-- what deleting does to your bags, and the delete list beside it.
--
-- Delete means destroyed, through Comfort/Leftovers.lua and nothing else, so
-- the claims are the ones 71-leftovers.lua makes about a corpse, asked from a
-- feed row. Does the cross destroy what the row counted and leave the rest of
-- the stack. Does a blue stay. Does the can sweep every row of an item, destroy
-- what they counted, and destroy every later drop of it as it lands with no row
-- and no floating message. Is the list impossible to miss: a red control on the
-- strip with the count on it, holding the strip up with the title off. And does
-- pressing that control empty the list and let the item make a row again.
--
-- It runs on a bag of its own, for the reason 71-leftovers.lua gives, and puts
-- the character's back at the foot of the file.

local H = ...
local ns, fire, check, advance = H.ns, H.fire, H.check, H.advance
local CARRIED, carrying, counted, destroyed = H.CARRIED, H.carrying, H.counted, H.destroyed

local Loot = ns.LootFeed
local lootStream = Loot.Stream()
local feed = lootStream:Feed()

local held = {}
for index = 0, 4 do
	held[index] = CARRIED[index]
	CARRIED[index] = nil
end

local function bags(...)
	CARRIED[4] = { ... }
end

local function frame()
	local tick = feed.frame:GetScript("OnUpdate")
	if tick then
		tick(feed.frame, 1 / 60)
	end
end

local LINEN = _G.WarriorKitItemLink("Linen Cloth")
local WOOL = _G.WarriorKitItemLink("Wool Cloth")
local AEGIS = _G.WarriorKitItemLink("Aegis")

local function sentence(item, count)
	if count then
		return ("You receive loot: %sx%d."):format(item, count)
	end
	return ("You receive loot: %s."):format(item)
end

local function loot(item, count)
	fire("CHAT_MSG_LOOT", sentence(item, count))
	frame()
end

-- Point at a row and press one of its buttons, the way a hand does.
local function press(index, which)
	local row = feed:Row(index)
	H.mouse.Place(H.mouse.Point(row))
	row:GetScript("OnEnter")(row)
	H.mouse.On(row[which])
	feed:Leave()
end

----------------------------------------------------------------------
-- The cross
----------------------------------------------------------------------

do
	feed:Clear()
	Loot.Unwatch()
	advance(61)

	bags("Linen Cloth", false, false)
	counted(4, 1, 5)
	loot(LINEN, 2)
	local before = #destroyed
	press(1, "cross")
	check(feed:Count() == 0, "pressing the cross left the row on the feed")
	check(#destroyed == before + 1 and counted(4, 1) == 3,
		("the cross on a row of two left a stack of %d from five, %d deletes")
			:format(counted(4, 1), #destroyed - before))

	-- A bounced click. The first press takes the row out and the next row moves
	-- up under the same button, so a second press inside the guard would
	-- destroy an item nobody pointed at.
	advance(1)
	bags("Linen Cloth", false, false)
	counted(4, 1, 5)
	loot(LINEN)
	advance(61)
	loot(LINEN)
	before = #destroyed
	press(1, "cross")
	press(1, "cross")
	check(#destroyed == before + 1 and counted(4, 1) == 4 and feed:Count() == 1,
		("a double click destroyed %d and left %d rows"):format(#destroyed - before, feed:Count()))
	advance(1)
	press(1, "cross")
	check(counted(4, 1) == 3 and feed:Count() == 0,
		"a press after the guard ran out did not take the next row")

	advance(1)
	bags("Aegis", false, false)
	loot(AEGIS)
	before = #destroyed
	press(1, "cross")
	check(carrying(4, 1) == "Aegis" and #destroyed == before,
		"the cross destroyed a blue")
end

----------------------------------------------------------------------
-- The can
----------------------------------------------------------------------

do
	feed:Clear()
	advance(61)
	check(feed.list ~= nil and not feed.list:IsShown(),
		"the delete list's control is up with nothing on the list")

	bags("Linen Cloth", "Wool Cloth", false)
	counted(4, 1, 10)
	counted(4, 2, 4)
	-- Two rows of linen with wool between them, a minute apart so they do not fold.
	loot(LINEN)
	advance(61)
	loot(WOOL)
	advance(61)
	loot(LINEN, 2)
	check(feed:Count() == 3, ("three pickups and the feed holds %d"):format(feed:Count()))

	local row = feed:Row(1)
	H.mouse.Place(H.mouse.Point(row))
	row:GetScript("OnEnter")(row)
	check(row.trash:IsShown() and row.cross:IsShown(),
		"pointing at a row did not bring up both its buttons")
	for _, button in ipairs({ row.cross, row.trash }) do
		local clicks = button:GetRegisteredClicks()
		check(button.wkEdge == "up" and clicks and clicks.LeftButtonUp,
			"a button on a loot row did not register its click through UI.Press")
	end
	check(row.trash:GetRight() <= row.cross:GetLeft() + 0.01,
		"the can is drawn over the cross rather than beside it")
	-- Onto the can is still the row, the same as onto the cross.
	H.mouse.Place(H.mouse.Point(row.trash))
	row:GetScript("OnLeave")(row)
	check(feed.hovered == 1 and row.trash:IsShown(),
		"moving onto the can took the row's hover and the can with it")
	H.mouse.On(row.trash)
	feed:Leave()

	check(feed:Count() == 1 and feed:Held(0).link == WOOL,
		"the can left a row of the item it put on the list, or took the wool with it")
	check(counted(4, 1) == 7 and counted(4, 2) == 4,
		("the can on two rows of linen left linen %d of ten and wool %d of four")
			:format(counted(4, 1), counted(4, 2)))
	check(Loot.Listed(LINEN) and not Loot.Listed(WOOL), "the can listed the wrong item")
	check(feed.list:IsShown() and feed.list.count:GetText() == "1",
		("the strip does not show a delete list of one: %s"):format(tostring(feed.list.count:GetText())))

	----------------------------------------------------------------------
	-- A listed item arriving
	----------------------------------------------------------------------

	loot(LINEN, 3)
	local items, refused = Loot.List()
	check(feed:Count() == 1 and items == 1 and refused == 1,
		("a listed drop: %d rows, %d listed, %d refused"):format(feed:Count(), items, refused))
	check(counted(4, 1) == 4,
		("three listed linen landed on seven and the stack holds %d"):format(counted(4, 1)))

	local floating = ns.db.lootFloat
	ns.db.lootFloat = true
	check(ns.Floats.OnLoot(sentence(LINEN)) == false, "a listed item still floats across the screen")
	ns.db.lootFloat = floating

	----------------------------------------------------------------------
	-- The strip, with the title off
	----------------------------------------------------------------------

	local header = ns.db.lootFeedHeader
	ns.db.lootFeedHeader = false
	lootStream:Apply()
	check(feed.head > 0 and feed.list:IsShown(),
		"with the title off the delete list took the strip down")

	H.mouse.On(feed.list)
	check(Loot.List() == 0, "pressing the delete list's control left items on it")
	check(feed.head == 0 and not feed.list:IsShown(),
		"the strip stayed up for an empty list with the title off")

	loot(LINEN)
	check(feed:Held(0).link == LINEN and counted(4, 1) == 4,
		"an item taken off the list still makes no row, or is still destroyed")

	ns.db.lootFeedHeader = header
	lootStream:Apply()
	check(not feed.list:IsShown(), "the delete list's control came back with the title")
	feed:Clear()
end

-- Nothing left owed, so the addon is off the bag path again with the switch off.
check(#(H.events.BAG_UPDATE_DELAYED or {}) == 0,
	"the feed's deletes left the bag event registered with nothing owed")

for index = 0, 4 do
	CARRIED[index] = held[index]
end
