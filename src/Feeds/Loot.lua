local ADDON, ns = ...

local LootFeed = {}
ns.LootFeed = LootFeed

local C = ns.UI.Color

--------------------------------------------------------------------------
-- What dropped
--
-- Every item that reaches you, as a row: the icon, the name in the item's own
-- quality colour, how many of it there were, and why you want it.
--
-- **The last of those is not this file's.** Core/Need.lua answers it, and what
-- happens here is that its colour goes round the icon, its phrase goes in the
-- dim middle column and its sentence goes on the hover. A quality colour says
-- what the game thinks an item is worth and cannot say that eight of this one
-- finishes a quest, which is the whole of what a loot feed is read for.
--
-- Only a quest reason reaches the column, because only a quest reason has a
-- number in it. A reagent's answer is a profession's name in the player's own
-- language, which measures 104 units against a column that is never wider than
-- 81, so it is a green ring on the row and a word on the hover.
--
-- **Why this reads chat rather than the loot window.** The obvious source is
-- the loot window itself, and it is the wrong one twice over. Comfort/Loot.lua
-- empties a corpse at LOOT_READY before the window is ever drawn, so on this
-- addon's own default there is no window to read; and a window says what is on
-- the corpse rather than what ended up in your bags, which for a group is a
-- different list. CHAT_MSG_LOOT is the server telling you what you actually
-- got, it fires for a quest reward and a crafted item as well as a corpse, and
-- it is the only source that is right in all of those cases.
--
-- **Why the sentences are built rather than typed.** The message is a localised
-- format string with the link poked into it, and the client hands the addon the
-- same format strings it used. Turning LOOT_ITEM_SELF_MULTIPLE into a pattern
-- means a German client is read by German rules without this file knowing a
-- word of German. Typing "You receive loot:" here would be an addon that works
-- on one locale and silently captures nothing on the rest.
--
-- Nothing here is on a ticker. An item drops when it drops.
--------------------------------------------------------------------------

-- The quality palette, which lives in UI/Theme.lua.
--
-- It was written here and moved when the quest log's reward column became its
-- second reader. The tables are the same tables, which matters: every guard in
-- UI/Feed.lua compares a colour by table identity, so a palette read fresh out
-- of the client on each row would fail every one of those guards and repaint a
-- colour that had not changed. Taken into a local at load, the same as the
-- palette and the metrics above it.
local QUALITY = ns.UI.Quality

-- What class the client files a quest item under. Comfort/Clutter.lua reads the
-- same number off the same call and says so in its own header; this is the
-- second reader, and the two are deliberately not sharing a constant, because
-- one of them scanning your bags and the other reading a loot message are not
-- one decision.
local QUEST_CLASS = 12

-- The ring round a quest item's icon, and the line on its hover.
--
-- Orange rather than the heading gold beside it. Gold is what the coin rows are
-- and what the account's own accent is, and a quest marker in that colour is a
-- marker you have to work out. This is the only orange in the addon.
local QUEST = { 0.98, 0.55, 0.15 }

local COIN = "Interface\\Icons\\INV_Misc_Coin_01"

-- What the client draws where an item's icon should be and cannot say which.
-- Named rather than left nil, because a texture of nil is a blank square and a
-- question mark is the client's own way of saying it does not know yet.
local UNKNOWN = "Interface\\Icons\\INV_Misc_QuestionMark"

-- How long two of the same item are one pickup rather than two rows.
--
-- Sixty seconds, and it is a number rather than the whole ring for the reason
-- Feed:Fold is bounded at sixteen entries. Bandages come off a craft one a
-- second and belong on one row; a vendor run an hour ago is a different
-- afternoon and belongs on its own. The window is not a setting, because a
-- slider on it would be one more control over what this column shows.
local FOLD_WINDOW = 60

-- Need/Need.lua's word for the one reason this feed draws differently from the
-- other two. Written as the word rather than tested some other way, because the
-- brightness of a ring is the only thing in this file that has to tell the three
-- answers apart and the word is what the call hands over.
local TRASH = "trash"

--------------------------------------------------------------------------
-- The delete list
--
-- Items this character has told the feed never to draw again, and grinding is
-- the case: the tenth stack of linen off the tenth gnoll is a row you would
-- take out every time. The can on a row puts that item here and takes every
-- row of it out of the column, and from then on a drop of it never becomes a
-- row at all.
--
-- **Refused at the door.** This is "never", asked for one item at a time, and a
-- listed item taking slots in the ring would push out the drops you do want to
-- scroll back to. What it refused is counted, so the strip's hover can say what
-- the list has kept off the feed.
--
-- **Deleted means destroyed.** The rows the can takes out are destroyed from
-- the bags, and so is every later drop of a listed item, through
-- Comfort/Leftovers.lua under its refusals: never blue and up, never a quest
-- item, and never the group's drops. Feeds/Floats.lua asks the same list,
-- because a message sliding across the screen for an item you deleted is the
-- same row again.
--
-- Per character and keyed by item id, the shape Comfort's reagent list has.
-- The value is the link, so the hover names each item in its own colour.
--------------------------------------------------------------------------

-- The most items the strip's hover names before it says how many more.
local LIST_SHOWN = 12

-- The id the client files an item under, which is the number
-- Comfort/Leftovers.lua pays a destroy against.
local function ItemId(link)
	return (ns.ItemKind(link))
end

-- How many drops the list has kept off the feed since login.
local refused = 0

local function Listed(link)
	local id = ItemId(link)
	return id ~= nil and ns.dbc.lootFeedDelete[id] ~= nil
end

local function ListCount()
	local count = 0
	for _ in pairs(ns.dbc and ns.dbc.lootFeedDelete or {}) do
		count = count + 1
	end
	return count
end

local function ListSubject()
	local lines, count = {}, 0
	for _, link in pairs(ns.dbc.lootFeedDelete) do
		count = count + 1
		if count <= LIST_SHOWN then
			local name = ns.ItemInfo(link)
			local quality = ns.ItemValue(link)
			lines[#lines + 1] = { name or link:match("%[(.-)%]") or link,
				color = QUALITY[quality or 1] or QUALITY[1] }
		end
	end
	if count > LIST_SHOWN then
		lines[#lines + 1] = ("and %d more"):format(count - LIST_SHOWN)
	end
	lines[#lines + 1] = ("%d drops kept off the feed since you logged in."):format(refused)
	lines[#lines + 1] = "Click to empty the list. What was destroyed stays destroyed."
	return { kind = "note", title = "Delete list", lines = lines }
end

-- A drop destroyed out of the bags, through Comfort/Leftovers.lua, which is the
-- one place the addon splits a count off a stack and deletes it. The group's
-- drops are in somebody else's bags and never reach it.
local function Destroy(who, link, count, quest)
	if who or not link then
		return false
	end
	return ns.Leftovers.Destroy(link, count or 1, quest)
end

-- What the cross on a row says and does, handed to UI/Feed.lua as
-- opts.removable. `gone` runs for every row a sweep takes out, the can's too.
local removable = {
	tip = "Destroy this from your bags and take the row off the feed. Blue and"
		.. " better, and quest items, stay.",
	gone = function(entry)
		return Destroy(entry.who, entry.link, entry.count, entry.quest)
	end,
}

-- What UI/Feed.lua is handed as opts.watch.
local watch = {
	row = "Destroy this item from your bags, now and every time it drops again."
		.. " Blue and better, and quest items, stay.",
	can = function(entry)
		return ItemId(entry.link) ~= nil
	end,
	add = function(entry)
		local id = ItemId(entry.link)
		ns.dbc.lootFeedDelete[id] = entry.link
		return function(slot)
			return ItemId(slot.link) == id
		end
	end,
	count = ListCount,
	subject = ListSubject,
	clear = function()
		local list = ns.dbc.lootFeedDelete
		for id in pairs(list) do
			list[id] = nil
		end
	end,
}

--------------------------------------------------------------------------
-- The tooltip
--
-- The item's own text where the client will hand it over, which is the whole
-- reason UI/Scan.lua exists, and the item's name in its quality colour where it
-- will not. Either way the facts the feed knows and the item does not go
-- underneath.
--
-- What the item is worth is not here. It is Feeds/Worth.lua, registered against
-- every item hovered anywhere in the addon, because a mail attachment and a
-- link in chat deserve the same two lines a loot row gets. The one thing this
-- file still has to say about the money is the price it recorded when the item
-- dropped, handed over on the subject: the client answers about something in
-- your bags and goes quiet about one you have already sold.
--------------------------------------------------------------------------

local function Fill(entry)
	local lines = {}

	if entry.quest then
		lines[#lines + 1] = { "Quest item", color = QUEST }
	end
	-- Why you want it, at the width a line has rather than the width a column
	-- has. This is where a reagent says which profession, because the row can
	-- only afford the green ring, and where a quest count is spelled out.
	--
	-- Asked here rather than read off the entry, because the answer the row was
	-- painted with is as old as the pickup and an objective moves while a stack
	-- is still growing.
	local _, _, tone, said = ns.Need(entry.link)
	if said then
		lines[#lines + 1] = { ("%s, %s"):format(entry.name or "?", said),
			color = tone }
	end
	-- The last of them, on a row that folded. `at` moved to the newest pickup
	-- when it folded, so this line answers "when did I last get one" rather
	-- than "when did this row start", which is the question a stack that is
	-- still growing raises.
	lines[#lines + 1] = { "Looted", ns.Stream.Clock(entry.at) }
	local picks = entry.picks or 1
	if entry.money and picks > 1 then
		-- The same line an item row gets, in the unit coin is counted in. A coin
		-- row that folded says the total and nothing about how it got there, and
		-- how it got there is the half a row cannot hold. The total is repeated
		-- beside the count of pickups for the reason the item row repeats it:
		-- "in 3 pickups" on its own is a fragment.
		lines[#lines + 1] = { "Coin",
			("%s in %d pickups"):format(ns.Coined(entry.copper), picks) }
	elseif (entry.count or 1) > 1 then
		-- The half of the fold the row cannot hold. A row reading `x12` and a
		-- tooltip reading `12` has thrown the fold away: the number is on the
		-- row already, and what is not is that twelve of them came off three
		-- separate pickups.
		lines[#lines + 1] = { "Stack", picks > 1
			and ("%d in %d pickups"):format(entry.count, picks)
			or tostring(entry.count) }
	end
	if entry.who then
		lines[#lines + 1] = { "Went to", entry.who }
	end

	return {
		kind = "item",
		link = entry.link,
		title = entry.name or "?",
		color = entry.color,
		count = entry.count,
		price = entry.price,
		lines = lines,
	}
end

--------------------------------------------------------------------------

local stream = ns.Stream.New({
	prefix = "lootFeed",
	name = "WarriorKitLootFeed",
	title = "Loot",
	empty = "nothing yet",
	-- Forty eight units, and the number is a measurement rather than a guess.
	-- The only thing this column ever draws is a quest count, and a count in the
	-- shipped face at a row's text size is 8.03 units a digit and 5.14 for the
	-- slash: 21 for `4/8`, 29 for `0/12`, 37 for `10/12` and 45 for `0/100`.
	-- Forty eight holds the last of those whole, and nothing wider than that
	-- exists as an item objective.
	--
	-- It has to hold at the narrow end as well, because UI/Feed.lua gives this
	-- column half of what is left after the number at most and hands back less
	-- than was asked for rather than saying so. Dragged to the panel's floor of
	-- 200 units the column is 41 at the shipped icon, which still holds a four
	-- digit count whole; the icon has to go past 33 at that same width before it
	-- reaches 37 and a count starts to clip, and at that setting the item's name
	-- has six characters and the row has lost more than its note.
	--
	-- The profession's name is not in this list because it cannot be. It
	-- measures 104 units and this column is never wider than 81, so it is the
	-- sentence on the hover and a green ring on the row.
	note = 48,
	onTooltip = Fill,
	-- A cross on the row under the cursor, which destroys what the row counts
	-- and takes the row out. LootFeed.Counts still counts it, because that
	-- number is what reached the feed.
	removable = removable,
	watch = watch,
	-- The strip along the bottom, which is Feeds/Purse.lua's three numbers. It
	-- is on this feed and not on the combat one because this is the window
	-- already answering "what did I just get", and gold was the part of that
	-- answer a list of rows could not give: coin gets a row when it drops and
	-- the row scrolls away, and what you want an hour later is the total and
	-- the slope.
	onStatus = ns.Purse.Line,
	onStatusTooltip = ns.Purse.Ledger,
})

function LootFeed.Stream()
	return stream
end

-- Everything this part registers, which is the six a stream owns plus the three
-- that are about loot rather than about a column on a screen.
--
-- Bottom right, above the bags and clear of the meters, which sit left of
-- centre. That is where the client's own loot text goes past and it is where
-- your eye already is when something dies.
function LootFeed.Defaults()
	-- No word over it and no line round it, which is the third argument. The
	-- rows are an icon, a name in the item's own quality colour and a count;
	-- there is nothing about that column the word "Loot" adds, and the edge
	-- was a window frame round something that is not a window.
	local defaults = ns.Stream.Defaults("lootFeed",
		{ "RIGHT", "UIParent", "RIGHT", -119, 17 }, false)

	-- Thirteen rows in 280 pixels, against the stream's own ten in 260. A drop
	-- is an item name and a count, so the column is narrow and the value of it
	-- is depth: the run of greens you picked up on the way here is still on
	-- screen when you reach the vendor.
	defaults.lootFeedRows = 13
	defaults.lootFeedWidth = 280

	-- Almost nothing behind it. This column lives against the right edge of the
	-- screen over open world, item names carry their own quality colour and
	-- their own outline, and a panel under them was covering scenery to hold up
	-- text that did not need holding up.
	defaults.lootFeedAlpha = 15

	-- 29, which is one step over the stream's 27. A loot row is an icon first
	-- and a name second, and this is the one feed where the picture is the
	-- thing you recognise before you have read anything.
	defaults.lootFeedIcon = 29

	-- Yours only. Everyone else's drops are the thing that makes the client's
	-- own loot spam unreadable in a raid, and a feed that reproduced it would
	-- have replaced one unreadable column with a prettier one.
	defaults.lootFeedGroup = false

	-- The status strip's, folded in here rather than registered on their own.
	-- Feeds/Feature.lua merges one table per stream and the strip belongs to
	-- this one, so this is where its keys reach the account file.
	for key, value in pairs(ns.Purse.Defaults()) do
		defaults[key] = value
	end
	return defaults
end

--------------------------------------------------------------------------
-- Rows
--------------------------------------------------------------------------

local seen = 0

-- Why this item matters to you, onto the row's middle column and onto the ring
-- round its icon.
--
-- Both off the one answer, because they are the one fact. A row saying `4/8` in
-- the green a reagent is drawn in would be a row disagreeing with itself, and
-- two rings for two reasons would be a row with two rings on it.
--
-- A reagent leaves the column empty, because Core/Need.lua gives it no phrase
-- and no row can hold the one it would have given. That is the ring carrying a
-- reason on its own, which is what the ring already does for trash everywhere
-- else this answer is drawn.
--
-- Asked with no loot slot, because CHAT_MSG_LOOT is the server saying what
-- reached your bags and the corpse behind it is gone by the time it arrives.
-- Trash still answers: Comfort/Loot.lua wrote down what the filter refused at
-- the moment it refused it, and Need/Need.lua reads that back by link. This is
-- the only window in the addon that ever sees a slot the filter binned, and a
-- rule set too tight is otherwise a rule nobody finds out about.
--
-- Trash is also the one reason that does not light the ring. It is the
-- commonest answer of the three and the one nobody is looking for, so it is
-- drawn at the row's own brightness with the stripe rather than held at full: a
-- column of greys each wearing a bright ring is a column where nothing stands
-- out.
--
-- The ring falls back to the quest colour for an item the client files as a
-- quest item. Core/Need.lua matches an objective by the name the client writes
-- on it and says so in its own header, and the handful whose objective is
-- worded differently from the item would otherwise lose a ring the feed has
-- drawn round them since it was written.
--
-- The ring stays at full while the stripe beside it rests. The stripe is a
-- grade and a column of grades is worth reading as a ribbon; the ring is the
-- one thing on the row telling you to look, and a thing telling you to look at
-- three fifths strength is furniture. `look` is what UI/Feed.lua reads for
-- that, and it is written here rather than at the arrival so a row that folded
-- into a reason it did not have keeps its ring lit.
local function Reason(entry)
	local why, phrase, tone = ns.Need(entry.link)
	entry.note = phrase
	entry.ring = tone or (entry.quest and C.quest) or nil
	entry.look = (entry.ring and why ~= TRASH) and true or nil
end

-- Whether an entry the feed is holding is the row a fresh one belongs on.
--
-- Three things, and the third is the one the item this was written for did not
-- ask for. The link is the item; the window is read off the held entry alone,
-- because the slot the caller has filled has no `at` yet and that is written by
-- the push this fold is deciding against; and the looter is `who`, which is nil
-- on your own pickup and a name on somebody else's. Without it your linen and a
-- party member's land on one row, and the row that says three of them says
-- "Went to" about one player. That is a column of arithmetic saying something
-- untrue, in the one feature that exists to answer who got it.
--
-- The moment sits beside this rather than inside it, so a corpse full of loot
-- is one function here and not a closure per arrival.
local foldAt = 0
local function Repeated(held, fresh)
	return held.link == fresh.link and held.who == fresh.who
		and held.at ~= nil and (foldAt - held.at) <= FOLD_WINDOW
end

-- The same, for coin.
--
-- Coin folds on being coin at all, because one copper is the same thing as
-- another and there is no link to tell two pickups apart with. The looter is
-- not in it either: the client reports nobody else's coin in a sentence
-- Core/Loot.lua can read, so every coin row is yours and `who` is nil on all of
-- them. What is left is the window and a total to add to, and a held row with
-- no total is a row this cannot add to and so is not the row.
local function AnyCoin(held)
	return held.money and held.copper ~= nil
		and held.at ~= nil and (foldAt - held.at) <= FOLD_WINDOW
end

local function AddItem(who, link, count)
	local quality, price = ns.ItemValue(link)
	local name, icon = ns.ItemInfo(link)
	local color = QUALITY[quality or 1] or QUALITY[1]

	-- The class the client files it under, which is the only thing that tells a
	-- quest item from a white one. Read here rather than on the hover, because
	-- a tooltip that asked would be asking about an item that may have left
	-- your bags an hour ago, and this is one lookup on a path a drop drives.
	local _, class = ns.ItemKind(link)

	local entry = stream:Feed():Entry()
	entry.icon = icon or UNKNOWN
	entry.name = name or link
	entry.amount = "x" .. count
	entry.color = color
	entry.stripe = color
	entry.tone = C.text
	entry.link = link
	entry.count = count
	entry.who = who
	-- The two the ring and the hover read. Quest is what the ring falls back to
	-- and the destroy refuses, and the price is the vendor's, kept because the
	-- client will answer for an item in your bags and go quiet about one you
	-- sold.
	entry.quest = (class == QUEST_CLASS) or nil
	entry.price = price
	-- After `quest`, which is one of the two things the ring is read off.
	Reason(entry)

	-- The same item again inside the window is the row you are already looking
	-- at rather than a second one under it.
	foldAt = GetTime()
	local into = stream:Feed():Fold(Repeated)

	if into then
		-- What the row says and what the tooltip says, and nothing else. The
		-- quest and price are this same item's already, and the entry
		-- itself is the feed's slot rather than something to keep past this
		-- call.
		into.count = (into.count or 1) + count
		into.amount = "x" .. into.count
		into.picks = (into.picks or 1) + 1
		-- The row is now about the last one you picked up, which is what the
		-- tooltip's clock reads and what the next arrival's window is measured
		-- against.
		into.at = foldAt
		-- And why it matters, read again, because the count on an objective
		-- moved while this row was folding. Twelve arrivals of a wolf liver is a
		-- row that opened at 4/8 and is at 8/8 by the time it reads x12, and a
		-- note written once is a row telling you to keep four more of something
		-- you already have.
		--
		-- Cheap, because Core/Need.lua answers off a cache keyed by item id and
		-- empties it on the quest log's own events. A fold that changed nothing
		-- is two table reads.
		Reason(into)
	else
		stream:Feed():Push()
	end

	seen = seen + 1
	return true
end

local function AddMoney(text)
	local phrase, copper = ns.LootLine.Money(text)
	if not phrase then
		return false
	end
	local entry = stream:Feed():Entry()
	entry.icon = COIN
	-- The phrase is the client's own coin text, which already reads "12 Silver,
	-- 39 Copper" in whatever language this client is. It goes in the name rather
	-- than the number because it is three words and the number column is one.
	entry.name = phrase
	entry.amount = ""
	entry.color = C.heading
	entry.stripe = C.heading
	entry.money = true
	entry.copper = copper

	foldAt = GetTime()
	local into = copper and stream:Feed():Fold(AnyCoin)

	if into then
		into.copper = into.copper + copper
		-- The client's sentence goes, and this is the only place in this file
		-- that throws it away. It was picked on purpose two lines up, and it is
		-- the wrong text on a row that three corpses paid into: a row reading
		-- "12 Silver, 39 Copper" when the fold has 37 silver in it is the one
		-- column that is arithmetic saying something untrue. The total is the
		-- thing being kept, so the total is what the row says.
		into.name = ns.Coined(into.copper)
		into.picks = (into.picks or 1) + 1
		into.at = foldAt
	else
		stream:Feed():Push()
	end

	seen = seen + 1
	return true
end

function LootFeed.OnLoot(text)
	if not ns.db.lootFeed or type(text) ~= "string" then
		return false
	end

	local who, link, count = ns.LootLine.Read(text)
	if not link then
		return false
	end
	if who and not ns.db.lootFeedGroup then
		return false
	end
	if Listed(link) then
		refused = refused + 1
		local _, class = ns.ItemKind(link)
		Destroy(who, link, count, class == QUEST_CLASS)
		return false
	end
	return AddItem(who, link, count)
end

function LootFeed.OnMoney(text)
	if not ns.db.lootFeed or type(text) ~= "string" then
		return false
	end
	return AddMoney(text)
end

--------------------------------------------------------------------------

-- How many of the loot sentences this client actually carries.
--
-- Worth a line in /wk status rather than assumed, because a locale that spells
-- one of them differently, or a flavour that does not have the crafted form at
-- all, is a feed that quietly misses a third of what drops. A number here is
-- the difference between finding that in a second and never finding it.
-- How many of the client's loot sentences this build actually carries. Core's,
-- because the table is Core's now; kept on this feed because this is the part
-- that reports it and a caller should not have to know where it moved to.
function LootFeed.Rules()
	return ns.LootLine.Rules()
end

function LootFeed.Describe()
	if not ns.db.lootFeed then
		return "off"
	end

	local line = stream:Describe()
	local live, total = LootFeed.Rules()
	if live < total then
		line = line .. (", and this client carries %d of the %d loot messages")
			:format(live, total)
	end
	return line
end

-- What has ever reached the feed, for the panel and for scripts/harness.lua.
--
-- One number rather than the two it was. The second was what a quality floor
-- turned away at the door, and there is no door any more: everything that drops
-- is recorded and drawn, which is a number the feed itself already carries and
-- puts in its own tally.
function LootFeed.Counts()
	return seen
end

-- Whether an item is on the delete list, for Feeds/Floats.lua.
function LootFeed.Listed(link)
	return Listed(link)
end

-- How many items are on the list and how many drops it has refused, for the
-- panel and for scripts/harness.lua.
function LootFeed.List()
	return ListCount(), refused
end

-- The list emptied from the panel. Through the feed where there is one, so the
-- strip hears about it.
function LootFeed.Unwatch()
	local feed = stream:Feed()
	if feed then
		return feed:Unwatch()
	end
	watch.clear()
	return true
end

-- The list, per character, the way Comfort's reagent list is.
function LootFeed.CharDefaults()
	return { lootFeedDelete = {} }
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("CHAT_MSG_LOOT")
events:RegisterEvent("CHAT_MSG_MONEY")
events:SetScript("OnEvent", function(_, event, text)
	if event == "PLAYER_LOGIN" then
		-- The format strings are FrameXML's and are not all in place while the
		-- addon's own files are still loading, so the patterns are built after
		-- it rather than at the top of any file. Core/Loot.lua builds them on
		-- the first line anybody reads, which is later still and cannot be got
		-- wrong by a second reader; this is the nudge, not the guarantee.
		ns.LootLine.Build()
		return
	end
	if event == "CHAT_MSG_LOOT" then
		LootFeed.OnLoot(text)
	else
		LootFeed.OnMoney(text)
	end
end)
