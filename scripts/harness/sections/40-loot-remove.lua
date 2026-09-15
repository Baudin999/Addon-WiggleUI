-- Taking a row out of the loot feed
--
-- 31-feeds.lua holds what the ring is and 40-loot-feed.lua what a loot row
-- says. This is the cross on a row, in a file of its own because both of those
-- are at their ceilings.
--
-- Four questions. Does a removal close the gap without reordering what is left
-- or allocating a table. Does the count stay true once the ring has lapped,
-- where min(written, cap) could never go down. Do the filter's cached count and
-- the offset under a reader follow it. And does the cross come up on the row
-- under the pointer, stay up while the pointer moves onto it, and take out the
-- row it sits on when pressed.

local H = ...
local ns, fire, check = H.ns, H.fire, H.check

local Loot = ns.LootFeed
local lootStream = Loot.Stream()
local feed = lootStream:Feed()

-- One frame of the client, through the feed's own tick, for the reason
-- 31-feeds.lua gives: that is the one road a paint takes in the game.
local function frame()
	local tick = feed.frame:GetScript("OnUpdate")
	if tick then
		tick(feed.frame, 1 / 60)
	end
end

-- A distinct link per number, so no two drops fold onto one row.
local function link(index)
	return _G.WarriorKitItemLink("Aegis", index)
end

local function pour(from, to)
	for index = from, to do
		fire("CHAT_MSG_LOOT", ("You receive loot: %s."):format(link(index)))
	end
	frame()
end

----------------------------------------------------------------------
-- The gap
----------------------------------------------------------------------

do
	feed:Clear()
	pour(1, 5)
	local gone = feed:Held(2)
	check(feed:Remove(gone), "taking out an entry the feed holds answered false")
	check(feed:Count() == 4, ("four left and the feed holds %d"):format(feed:Count()))
	local want = { 5, 4, 2, 1 }
	for back = 0, 3 do
		check(feed:Held(back).link == link(want[back + 1]),
			("after the removal entry %d is %s"):format(back, tostring(feed:Held(back).link)))
	end
	check(not feed:Remove(gone), "the same entry came out twice")

	pour(6, 6)
	check(feed:Held(0) == gone and gone.link == link(6),
		"the next drop did not land in the table the removal gave back, so a removal leaks one")

	-- The newest and the oldest, the two ends the shift turns at.
	feed:Remove(feed:Held(0))
	feed:Remove(feed:Held(feed:Count() - 1))
	check(feed:Count() == 3 and feed:Held(0).link == link(5) and feed:Held(2).link == link(2),
		"taking out the newest and the oldest left the wrong three")
end

----------------------------------------------------------------------
-- A ring that has lapped
--
-- The count was min(written, cap), and past one lap that is the cap whatever
-- has been taken out. So the claim is about the far end: a removal from a full
-- ring leaves room, the next drop fills it without pushing the oldest out, and
-- the drop after that does push it out.
----------------------------------------------------------------------

do
	feed:Clear()
	local cap = feed.cap
	pour(1001, 1000 + cap + 5)
	local oldest = feed:Held(cap - 1)
	check(feed:Count() == cap and oldest.link == link(1006),
		("a ring filled past its cap holds %d, oldest %s"):format(feed:Count(), tostring(oldest.link)))

	feed:Remove(feed:Held(10))
	check(feed:Count() == cap - 1,
		("a removal from a full ring left the count at %d"):format(feed:Count()))
	check(feed:Held(cap - 2) == oldest, "a removal from a full ring moved the oldest entry")

	pour(2000, 2000)
	check(feed:Count() == cap and feed:Held(cap - 1) == oldest,
		"the drop after a removal pushed an entry out of a ring that had room for it")
	pour(2001, 2001)
	check(feed:Count() == cap and feed:Held(cap - 1).link == link(1007),
		"a full ring did not push its oldest entry out on the drop after it filled again")

	----------------------------------------------------------------------
	-- The filter's count and the offset
	----------------------------------------------------------------------

	check(feed.filter ~= nil, "the loot feed has no filter running, so the count below proves nothing")
	local counted = feed:Shown()
	feed:Remove(feed:Held(3))
	local after = feed:Shown()
	feed:Refilter()
	check(after == counted - 1 and feed:Shown() == after,
		("a removal left the count at %d, a recount says %d, from %d"):format(after, feed:Shown(), counted))

	feed:ScrollTo(20)
	local reading = feed:Row(1).shownEntry
	feed:Remove(feed:At(2))
	check(feed:Offset() == 19 and feed:Row(1).shownEntry == reading,
		"taking out a row above the view moved the one being read")
	feed:Remove(feed:At(feed:Offset() + 3))
	check(feed:Offset() == 19 and feed:Row(1).shownEntry == reading,
		"taking out a row inside the view moved the row above it")
	feed:ToTop()
end

----------------------------------------------------------------------
-- The cross
----------------------------------------------------------------------

do
	feed:Clear()
	pour(3001, 3003)
	local row = feed:Row(2)
	local cross = row.cross
	check(cross ~= nil, "a loot feed row has no cross")
	check(not cross:IsShown(), "the cross is up on a row nobody is pointing at")
	check(not ns.CombatFeed.Stream().removable, "the combat feed asks for a cross")

	H.mouse.Place(H.mouse.Point(row))
	row:GetScript("OnEnter")(row)
	check(cross:IsShown(), "pointing at a row did not bring its cross up")

	-- The client tells the row it left when the pointer reaches the cross.
	H.mouse.Place(H.mouse.Point(cross))
	row:GetScript("OnLeave")(row)
	check(feed.hovered == 2 and cross:IsShown(),
		"moving onto the cross took the row's hover and the cross with it")

	local oldest = feed:Held(2)
	H.mouse.On(cross)
	check(feed:Count() == 2, ("pressing the cross left %d of three"):format(feed:Count()))
	check(feed:Held(1) == oldest and row.shownEntry == oldest,
		"pressing the cross on row two took out something other than row two")

	H.mouse.Place(0, 0)
	cross:GetScript("OnLeave")(cross)
	check(feed.hovered == nil and not cross:IsShown(),
		"leaving the cross for the world left the row lit and its cross up")

	feed:Clear()
end
