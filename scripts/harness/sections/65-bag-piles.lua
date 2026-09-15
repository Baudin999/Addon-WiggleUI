-- The order inside a pile, the lines, and the quest lanes
--
-- Four claims. A pile is sorted by what an item is before how good it is:
-- subclass ahead of level and the highest level first, so the cloth sits
-- together ahead of the ore and silk leads wool, whatever bag either is in. The
-- piles are cut into lines at the sections and the rules, and a line is
-- balanced before it is broken: a big pile grows a row to let a small one sit
-- beside it. The quest pile is drawn in two lanes on a fact that is not the
-- binding: what a quest in your log wants on the left, in the order the log
-- lists the quests, and what nothing in your log wants on the right. And a
-- session with no Questie in it gets the quest pile in one lane, because
-- "cannot say" is never a suggestion to throw something away.
--
-- Its own section rather than part of 62-bag-lanes.lua because the subject is
-- not the same. That file asks where a square landed when the pile splits on
-- the tooltip; this one asks what order the piles and their squares come out in.
--
-- **The fifth bag.** Every scene before this one is written against the four
-- bags 55-bags.lua describes, and the piles those hold are each one subclass
-- wide, which is the case where the subclass decides nothing. So a fifth bag is
-- stood up with two kinds of cloth, an ore, two totems, a pet, one more quest
-- item, a recipe and six linen, and taken down again at the end.

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
-- below, so a pile that kept it fails. The six linen make the trade goods ten
-- squares, too wide at one row to share a line with the recipe beside them.
CARRIED[4] = {
	"Tin Ore", "Wool Cloth", "Silk Cloth",
	"Snake Basket", "Earth Totem", "Air Totem",
	"Trapper's Rope", "Master First Aid - Doctor in the House",
	"Linen Cloth", "Linen Cloth", "Linen Cloth",
	"Linen Cloth", "Linen Cloth", "Linen Cloth",
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

-- Where the pile with this key was laid, by its row in the scan.
local function block(key)
	for index = 1, read.shown do
		if read.groups[index].key == key then
			return Grid.Block(index)
		end
	end
	return nil
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
-- and wool 15, so silk leads. Emerald Pigment and the linen carry no subclass,
-- which no item on the real client lacks, so they come after the ore although
-- the pigment sits in an earlier bag than all of it; the pigment is green and
-- the linen white, so the pigment leads.
local led = "Silk Cloth, Wool Cloth, Tin Ore, Emerald Pigment, Linen Cloth"
check(trade[1] and names(trade[1]):sub(1, #led) == led,
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
-- The lines
--
-- The rows of the scan, read as a sentence: a key for a pile, a bracketed
-- caption for a section, a bar for a break and a dash for a rule. Then where
-- the blocks landed, off the layout itself.
----------------------------------------------------------------------

do
	local said = {}
	for index = 1, read.shown do
		local row = read.groups[index]
		if row.kind == "section" then
			said[#said + 1] = "[" .. row.name .. "]"
		elseif row.kind == "rule" then
			said[#said + 1] = "-"
		elseif row.kind == "break" then
			said[#said + 1] = "|"
		else
			said[#said + 1] = row.key
		end
	end
	-- No rule over the quest pile, because nothing is drawn above it. The
	-- equipment and the crafting each under a caption, a break where the
	-- crafting ends, and a rule over the junk.
	local want = "quest [Equipment] weapon armor [Crafting] trade recipe | misc - junk empty"
	check(table.concat(said, " ") == want,
		("the rows came out as %q"):format(table.concat(said, " ")))

	-- The shield shares the weapons' line. Filled greedily, a split pile took a
	-- whole line of its own and the shield sat under it.
	local _, weaponTop = block("weapon")
	local _, armorTop = block("armor")
	check(weaponTop ~= nil and weaponTop == armorTop,
		("the weapons are at %s and the armour at %s, so they are not on one line")
			:format(tostring(weaponTop), tostring(armorTop)))

	-- Ten trade goods are the whole width at one row, and the recipe beside them
	-- makes the line too wide. So the trade goods take a second row and the
	-- recipe keeps the line, rather than the recipe starting a line of its own.
	local _, tradeTop, tradeLane = block("trade")
	local _, recipeTop = block("recipe")
	check(tradeTop ~= nil and tradeTop == recipeTop,
		("the trade goods are at %s and the recipe at %s, so they are not on one line")
			:format(tostring(tradeTop), tostring(recipeTop)))
	check(tradeLane and tradeLane < #trade[1].entries,
		("the trade goods are %s across for %d squares, so they did not grow a row to make room")
			:format(tostring(tradeLane), #trade[1].entries))

	local _, miscTop = block("misc")
	check(miscTop and tradeTop and miscTop > tradeTop,
		"the miscellany is on the crafting line, past the break that ends it")

	-- And no block past the window's right edge.
	local over = 0
	for index = 1, read.shown do
		local left, _, _, _, width = Grid.Block(index)
		if not read.groups[index].kind and left
			and left + width > Grid.Width(ns.db.bagColumns) + 0.001 then
			over = over + 1
		end
	end
	check(over == 0, ("%d blocks run past the window's right edge"):format(over))

	local up = 0
	for _, rule in ipairs(Grid.Rules()) do
		if rule:IsShown() then
			up = up + 1
		end
	end
	check(up == 1, ("%d rules are drawn and the junk has the one"):format(up))
end

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
-- found by counting to it the way the layout did, and the lane's start is the
-- block's own left edge, its left lane's squares and the half square of air.
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
do
	local gap = ns.UI.Round(canvas, ns.UI.SLOT_LANE)
	local left, _, lane = block("quest")
	local start = ns.UI.Round(canvas, left + lane * (ns.UI.SLOT + ns.UI.SLOT_GAP) + gap)
	check(offset(quest[1], "Diplomat's Ring") == ns.UI.Round(canvas, left),
		("the ring is %s units in and the quest block starts at %.3f")
			:format(tostring(offset(quest[1], "Diplomat's Ring")), left))
	check(offset(quest[1], "Hogger's Claw") == start,
		("the claw is %s units in and the right lane starts at %.3f")
			:format(tostring(offset(quest[1], "Hogger's Claw")), start))
end

----------------------------------------------------------------------
-- The captions
--
-- One heading per pile, and one caption per section. The cloth and the ore
-- used to carry sub-captions of their own under Trade Goods, most of them over
-- one square, and neither word is drawn in either pool any more.
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
	check(count(subs, "Equipment") == 1 and count(subs, "Crafting") == 1,
		("the section captions read Equipment %d times and Crafting %d times, and once each")
			:format(count(subs, "Equipment"), count(subs, "Crafting")))
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
	local _, _, _, rest = block("quest")
	check(rest == 0,
		("with no Questie the quest pile still has %s squares across a right lane"):format(tostring(rest)))
	_G.QuestieLoader = loader
end

print(("piles  trade runs %s; misc runs %s; the quest pile in two lanes of %d and %d")
	:format(trade[1] and names(trade[1]) or "?", misc[1] and names(misc[1]) or "?",
		mine, #quest[1].entries - mine))

-- The fifth bag down and the window shut, the way 55-bags.lua found them.
CARRIED[4] = nil
Window.Hide()
