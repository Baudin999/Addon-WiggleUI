-- The order inside a pile, and the quest lanes
--
-- Three claims. A pile is sorted by what an item is before how good it is:
-- subclass ahead of level and the highest level first, so the cloth sits
-- together ahead of the ore and silk leads wool, whatever bag either is in.
-- The quest pile is drawn in two lanes on a fact that is not the binding: what
-- a quest in your log wants on the left, in the order the log lists the
-- quests, and what nothing in your log wants on the right. And a session with
-- no Questie in it gets the quest pile in one lane, because "cannot say" is
-- never a suggestion to throw something away.
--
-- Its own section rather than part of 62-bag-lanes.lua because the subject is
-- not the same. That file asks where a square landed when the pile splits on
-- the tooltip; this one asks what order a pile comes out in.
--
-- **The fifth bag.** Every scene before this one is written against the four
-- bags 55-bags.lua describes, and the piles those hold are each one subclass
-- wide, which is the case where the subclass decides nothing. So a fifth bag is
-- stood up with two kinds of cloth, an ore, two totems, a pet and one more
-- quest item, and taken down again at the end.

local H = ...
local ns, check = H.ns, H.check
local CARRIED, refill, refillQuests = H.CARRIED, H.refill, H.refillQuests

local Bags, Grid, Window = ns.Bags, ns.BagsGrid, ns.BagsWindow

----------------------------------------------------------------------
-- The scene
----------------------------------------------------------------------

refill()
refillQuests()
CARRIED[3] = { false, false, false }
-- Ore before cloth, wool before silk, the pet before the totems and earth
-- before air, on purpose: the bag order is the wrong order for every claim
-- below, so a pile that kept it fails.
CARRIED[4] = {
	"Tin Ore", "Wool Cloth", "Silk Cloth",
	"Snake Basket", "Earth Totem", "Air Totem",
	"Trapper's Rope",
}

Window.Show()
local read = Bags.Read()
Window.Refresh()

-- Every row with this key, in the order they came out.
local function rows(key)
	local found = {}
	for index = 1, read.shown do
		if read.groups[index].key == key then
			found[#found + 1] = read.groups[index]
		end
	end
	return found
end

local function names(row)
	local held = {}
	for index = 1, #row.entries do
		held[index] = row.entries[index].name or "?"
	end
	return table.concat(held, ", ")
end

----------------------------------------------------------------------
-- The order
----------------------------------------------------------------------

-- One row per pile, however many subclasses are in it.
local trade = rows("trade")
check(#trade == 1,
	("the trade goods came out as %d rows and a pile is one row"):format(#trade))

-- Cloth is subclass 5 and ore is 7, so the cloth comes first. Silk is level 25
-- and wool 15, so silk leads. Emerald Pigment is the trade good every earlier
-- scene carries and it has no subclass, which no item on the real client
-- lacks; it goes last, although it sits in an earlier bag than all three.
check(trade[1] and names(trade[1]) == "Silk Cloth, Wool Cloth, Tin Ore, Emerald Pigment",
	("the trade goods run %s"):format(trade[1] and names(trade[1]) or "?"))

-- Both totems are subclass 1 and the basket is 2. Air is level 30 and earth 4.
local misc = rows("misc")
check(#misc == 1 and names(misc[1]) == "Air Totem, Earth Totem, Snake Basket",
	("the miscellany came out as %d rows running %s")
		:format(#misc, misc[1] and names(misc[1]) or "?"))

check(ns.Piles.Of(H.itemLink("Bold Living Ruby")) == "gem",
	("a gem is filed under %q and it has a pile of its own")
		:format(tostring(ns.Piles.Of(H.itemLink("Bold Living Ruby")))))

local junk = rows("junk")
check(#junk == 1 and #junk[1].entries == 3,
	"the three greys did not come out as one row of three")

----------------------------------------------------------------------
-- The quest lanes
----------------------------------------------------------------------

local quest = rows("quest")
check(#quest == 1 and quest[1].split == true,
	"the quest pile is not one row marked as drawn in two lanes")

local function entry(name)
	for index = 1, #quest[1].entries do
		if quest[1].entries[index].name == name then
			return quest[1].entries[index], index
		end
	end
	return nil
end

-- The diplomat's quest is the second row of the log and the brotherhood is
-- the fifth, under the Westfall header, so the ring sits before the rope
-- whatever bag either is in. The letter starts a quest you have not done:
-- kept, and after everything you are on. Everything else is tied to a quest
-- that is behind you or one you have not taken, and is the right lane.
local ring, rope, letter = entry("Diplomat's Ring"), entry("Trapper's Rope"), entry("Sealed Letter")
check(ring and ring.yours == true and ring.rank == 2,
	("the ring a quest in your log wants reads yours=%s rank=%s")
		:format(tostring(ring and ring.yours), tostring(ring and ring.rank)))
check(rope and rope.yours == true and rope.rank == 5,
	("the rope a lower quest wants reads yours=%s rank=%s")
		:format(tostring(rope and rope.yours), tostring(rope and rope.rank)))
check(letter and letter.yours == true and letter.rank == math.huge,
	("the letter that starts a quest you have not done reads yours=%s rank=%s")
		:format(tostring(letter and letter.yours), tostring(letter and letter.rank)))

local kept = "Diplomat's Ring, Trapper's Rope, Sealed Letter, "
check(names(quest[1]):sub(1, #kept) == kept,
	("the quest pile runs %s and the log's order comes first"):format(names(quest[1])))

for _, name in ipairs({ "Hogger's Claw", "Zul'Mamwe Fetish", "Rogue's Token", "Old Cipher" }) do
	local held = entry(name)
	check(held and held.yours == false and held.rank == nil,
		("%s is tied to nothing in your log and reads yours=%s rank=%s")
			:format(name, tostring(held and held.yours), tostring(held and held.rank)))
end

-- The trinket Questie has no row for. Not "no quest wants it": the database
-- cannot say, and cannot say is kept.
local trinket = entry("Unknown Trinket")
check(trinket and trinket.yours == true and trinket.rank == nil,
	("the item Questie has never heard of reads yours=%s and it has to be kept")
		:format(tostring(trinket and trinket.yours)))

-- Counted before the no-Questie pass below reads the same state table over.
local mine = 0
for index = 1, #quest[1].entries do
	if quest[1].entries[index].yours then
		mine = mine + 1
	end
end

----------------------------------------------------------------------
-- Where they landed
--
-- The pixel, the way 62-bag-lanes.lua reads it: the square for an entry is
-- found by counting to it the way the layout did.
----------------------------------------------------------------------

local squares = Grid.Squares()

local function offset(row, name)
	local drawn = 0
	for index = 1, read.shown do
		local entries = read.groups[index].entries
		for at = 1, #entries do
			drawn = drawn + 1
			if read.groups[index] == row and entries[at].name == name then
				local _, _, _, x, y = squares[drawn]:GetPoint(1)
				return x, y
			end
		end
	end
	return nil
end

local canvas = squares[1]:GetParent()
local gap = ns.UI.Round(canvas, ns.UI.SLOT_LANE)
local lane = ns.UI.Round(canvas,
	math.ceil(ns.db.bagColumns / 2) * (ns.UI.SLOT + ns.UI.SLOT_GAP) + gap)

check(offset(quest[1], "Diplomat's Ring") == 0,
	("the ring is %s units in and the left lane starts at nought")
		:format(tostring(offset(quest[1], "Diplomat's Ring"))))
check(offset(quest[1], "Hogger's Claw") == lane,
	("the claw is %s units in and the right lane starts at %.3f")
		:format(tostring(offset(quest[1], "Hogger's Claw")), lane))

----------------------------------------------------------------------
-- The captions
--
-- One heading per pile. The cloth and the ore used to carry sub-captions of
-- their own under Trade Goods, most of them over one square, and neither word
-- is drawn in either pool any more.
----------------------------------------------------------------------

do
	local function count(pool, text)
		local found = 0
		for index = 1, #pool do
			if pool[index]:IsShown() and pool[index]:GetText() == text then
				found = found + 1
			end
		end
		return found
	end

	local headers, subs = Grid.Headers(), Grid.Subs()
	check(count(headers, "Trade Goods") == 1,
		("%d headings read Trade Goods and one should"):format(count(headers, "Trade Goods")))
	check(count(headers, "Cloth") + count(subs, "Cloth") == 0
			and count(headers, "Metal & Stone") + count(subs, "Metal & Stone") == 0,
		"a subclass caption is still drawn over the trade goods")
end

----------------------------------------------------------------------
-- The height
--
-- 55-bags.lua's reading: the body is the lowest edge of anything drawn plus the
-- padding, within the unit the pixel snap moves a square by.
----------------------------------------------------------------------

do
	local window = Window.Frame()
	local bottom = H.carry.bagBottom() + ns.BagsBelt.Height()
	check(window and math.abs(window:Body() - (bottom + ns.UI.Metric.pad * 2)) < 1,
		("the window's body is %d and what it draws comes to %.2f")
			:format(window and window:Body() or -1, bottom + ns.UI.Metric.pad * 2))
end

----------------------------------------------------------------------
-- No Questie
--
-- The quest pile in one lane: everything yours, nothing ranked, and the
-- window still up. The loader is taken away rather than the database, because
-- the loader is what ns.Questie probes, and put back the same way.
----------------------------------------------------------------------

do
	local loader = _G.QuestieLoader
	_G.QuestieLoader = nil
	local blind = Bags.Read()
	Window.Refresh()
	local pile
	for index = 1, blind.shown do
		if blind.groups[index].key == "quest" then
			pile = blind.groups[index]
		end
	end
	local kept, ranked = 0, 0
	for index = 1, pile and #pile.entries or 0 do
		if pile.entries[index].yours then
			kept = kept + 1
		end
		if pile.entries[index].rank ~= nil then
			ranked = ranked + 1
		end
	end
	check(pile and kept == #pile.entries and ranked == 0,
		("with no Questie %d of %d quest items are kept and %d are ranked; all and none")
			:format(kept, pile and #pile.entries or 0, ranked))
	local strayed = 0
	for index = 1, pile and #pile.entries or 0 do
		if offset(pile, pile.entries[index].name) >= lane then
			strayed = strayed + 1
		end
	end
	check(strayed == 0,
		("with no Questie %d quest items were still drawn in the right lane"):format(strayed))
	_G.QuestieLoader = loader
end

print(("piles  trade runs %s; misc runs %s; the quest pile in two lanes of %d and %d")
	:format(trade[1] and names(trade[1]) or "?", misc[1] and names(misc[1]) or "?",
		mine, #quest[1].entries - mine))

-- The fifth bag down and the window shut, the way 55-bags.lua found them.
CARRIED[4] = nil
Window.Hide()
