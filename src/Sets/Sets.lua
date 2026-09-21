local ADDON, ns = ...

local Sets = {}
ns.Sets = Sets

--------------------------------------------------------------------------
-- Named sets of gear, per character
--
-- A tanking set, a shadow resist set for Mother Shahraz, the two hander you
-- swing once the boss is down. This file is the model and the readers; Wear.lua
-- is what putting one on costs and Feature.lua is the words.
--
-- **There is no equipment manager on this client and there is no borrowing
-- one.** Blizzard's arrived in 3.3. Baganator guards its own set tracker with
-- `not IsEra and not IsBC` and the comment "Wrath onwards", which is the proof:
-- C_EquipmentSet is not there, and every part of this is built from nothing.
--
-- **Sets are per character.** Gear is a fact about one character: your
-- warrior's tanking set names pieces your mage will never see, and an
-- account-wide list would be a list of names for items nobody in the room is
-- carrying. So the store is ns.dbc and the key is declared in Feature.lua, the
-- way every other per-character setting in the addon is.
--
-- **A slot is in one of three states and unset is the one that matters.** An
-- item, deliberately empty, or unset. A shadow resist set names five pieces and
-- leaves your rings and trinkets alone, and that is the most common real set on
-- this client; a full nineteen slot set is only the case where nothing is
-- unset. Deliberately empty is the third because taking the shield off is a
-- thing a set has to be able to say, and saying it with an absent entry would
-- make it indistinguishable from not having decided.
--
-- **A set may follow a talent group, and most do not.** `group` is the group
-- the set is worn for, or nil. A resist set and a PvP set are real sets with no
-- spec behind them, so the row is never capped at the number of talent groups;
-- only two of them can carry a number, and Follow takes a number off whichever
-- set was holding it, because "the set for group two" has to answer with one
-- set.
--
-- **Nothing here draws and nothing here moves an item.** The page card is
-- written against the names below in another branch, so the whole of what this
-- file owes it is that the names mean the same thing in both.
--------------------------------------------------------------------------

-- Character/Worn.lua, captured at load rather than asked for per call. The toc
-- puts this block under the Character block, so the name is there by the time
-- this file runs, and scripts/trees.lua holds the edge with its reason.
local Worn = ns.Worn

-- The ammo slot's number. Zero is a real inventory slot and it is the one
-- number here that reads as "no slot" everywhere else, so it is named once and
-- compared against by name.
local AMMO = 0

-- Nineteen, and the twentieth is deliberately left out. The sheet draws twenty
-- and the ammo slot is not one a set may hold: it is a stack the bow eats out
-- of rather than a piece, the client answers it by id and never by link, and a
-- set that recorded it would be a set that moves your arrows about. Everything
-- else comes off Worn.Slots so that a slot added to the client is a slot sets
-- get for free.
local ORDER, ROWS = {}, {}
for _, entry in ipairs(Worn.Slots()) do
	if entry.slot ~= AMMO then
		ORDER[#ORDER + 1] = entry.slot
		ROWS[entry.slot] = entry
	end
end

-- The slots a set is made of, in the order the sheet draws them, and what one
-- of them is called. The label is what a sentence about a slot is written with,
-- so nothing outside this folder has to turn 11 into "ring".
function Sets.Slots()
	return ORDER
end

function Sets.Label(slot)
	return ROWS[slot] and ROWS[slot].label or ("slot " .. tostring(slot))
end

--------------------------------------------------------------------------
-- How an item is written down
--------------------------------------------------------------------------

-- Fields 2 through 8 of the item string, which is the id, the enchant, the four
-- gem sockets and the suffix. Auctionator's legacy path reads the suffix out of
-- field 8 on this client, which is what proves the offset rather than a count
-- made here.
--
-- `uniqueId` and everything past it is dropped on purpose. It changes as the
-- item moves between your bags and your person, so a set keyed on it would stop
-- matching itself the first time you took the piece off. Two genuinely
-- identical rings are then interchangeable, which is the right answer: a set
-- says which ring, not which of the two copies of it you happen to be holding.
--
-- The id comes off ns.ItemKind rather than off the string, although the two are
-- the same number. Core resolves GetItemInfoInstant against C_Item once for the
-- whole addon and answers nil for something that is not an item at all, so
-- reading the field again here would be a second reader to keep right and one
-- that cannot tell an item link from any other string with a colon in it.
--
-- A blank field and a zero are the same nothing and the client writes both, so
-- both come out as zero. Without that, the same ring read off two links would
-- key two different ways and a set would never match what you had on.
local FIELDS = 7 -- the id and the six after it, which is fields 2 through 8

local function Key(link)
	local id = type(link) == "string" and ns.ItemKind(link) or nil
	if not id then
		return nil
	end

	local out = tostring(id)
	local body = link:match("item:([%-%d:]*)") or ""
	local at = 1
	for field in (body .. ":"):gmatch("([^:]*):") do
		if at > 1 then
			out = out .. ":" .. (field == "" and "0" or field)
		end
		at = at + 1
		if at > FIELDS then
			break
		end
	end
	-- A link the client wrote short, which is every link on a client that has
	-- fewer fields than this one. The missing tail is nothing, and nothing is
	-- zero, so a short link and a long blank one key alike.
	for _ = at, FIELDS do
		out = out .. ":0"
	end
	return out
end

Sets.Key = Key

--------------------------------------------------------------------------
-- The store
--------------------------------------------------------------------------

-- The saved list, or nil before the client has handed the saved variables over.
-- Every writer below checks it rather than assuming: a word typed during the
-- load would otherwise write a set into a table that is thrown away.
local function Store()
	return ns.dbc and ns.dbc.gearSets or nil
end

-- Names are matched with the case folded away, because a set is something you
-- type at a slash prompt and "Fury" and "fury" are one set. New refuses a name
-- that already exists under that folding, so there is never more than one
-- answer here.
local function Find(name)
	if type(name) ~= "string" then
		return nil
	end
	local wanted = name:lower()
	local store = Store() or {}
	for index = 1, #store do
		if store[index].name:lower() == wanted then
			return store[index], index
		end
	end
	return nil
end

function Sets.All()
	return Store() or {}
end

function Sets.Get(name)
	return (Find(name))
end

-- What one set says about one slot, and whether that is what you have on.
--
-- The third answer is only there where the caller hands in the worn link, and
-- it is here rather than at the call site because it is a comparison of keys
-- and there is exactly one file that knows how an item is written down. The
-- gear page compared two raw links, which is the field `uniqueId` moving the
-- first time anything touches your gear: every circle under every row lit up
-- together and the page's headline reading went with them. Standing above and
-- Wearing below both compare keys; that one line did not.
function Sets.Entry(name, slot, worn)
	local record = Find(name)
	local entry = record and record.slots[slot]
	if entry == nil then
		return "unset"
	end
	if entry == false then
		return "empty"
	end
	return "item", entry.link, entry.key == Key(worn)
end

--------------------------------------------------------------------------
-- Who is told, and the one step back
--------------------------------------------------------------------------

-- One listener and not a list, which is the shape ns.UI.Scan.Watch hands out
-- and is here for the same reason: one page draws the sets, and two parts
-- deciding what a row says are two rows that disagree. Answered as true rather
-- than as nothing so a caller can tell it was heard.
local watcher = nil

function Sets.Watch(fn)
	watcher = type(fn) == "function" and fn or nil
	return true
end

local function Told()
	if watcher then
		watcher()
	end
end

-- The whole store, copied deep enough that nothing in the copy shares a table
-- with the original. A shallow copy would hand the undo the same slot tables
-- the next write edits, which is an undo that quietly restores what you just
-- did.
local function Copy(list)
	local out = {}
	for index = 1, #(list or {}) do
		local record = list[index]
		local slots = {}
		for slot, entry in pairs(record.slots or {}) do
			slots[slot] = (type(entry) == "table")
				and { key = entry.key, link = entry.link } or entry
		end
		out[index] = { name = record.name, group = record.group, slots = slots }
	end
	return out
end

-- One level, and that is the decision rather than a start on a stack.
--
-- The mistake this exists for is dropping a ring on the wrong row, and the
-- correction for it is immediate: you see the wrong name under the wrong slot
-- and you say so. A stack would be a second model of the same data to keep in
-- step with the first, and a set is thirty numbers; the way back from two wrong
-- moves is to drop the right ring on the row.
local undo = nil

local function Remember()
	undo = Copy(Store())
end

function Sets.Undo()
	local store = Store()
	if not undo or not store then
		return false, "there is nothing to undo."
	end
	-- Into the same table the saved variables point at, rather than over the
	-- field. A fresh table here is a table the client never writes to disk.
	for index = #store, 1, -1 do
		store[index] = nil
	end
	for index, record in ipairs(undo) do
		store[index] = record
	end
	undo = nil
	Told()
	return true
end

--------------------------------------------------------------------------
-- Writing a set
--------------------------------------------------------------------------

-- Long enough for "shadow resist" and short enough to sit on a row without
-- being cut. Refused rather than trimmed: a name silently shortened is a name
-- you cannot type back.
local NAME_MAX = 24

local function Clean(name)
	if type(name) ~= "string" then
		return nil, "a set needs a name."
	end
	local clean = name:match("^%s*(.-)%s*$")
	if clean == "" then
		return nil, "a set needs a name."
	end
	if #clean > NAME_MAX then
		return nil, ("a set's name is %d letters at most."):format(NAME_MAX)
	end
	return clean
end

function Sets.New(name)
	local clean, why = Clean(name)
	if not clean then
		return nil, why
	end
	if Find(clean) then
		return nil, ("there is already a set called %q."):format(clean)
	end
	local store = Store()
	if not store then
		return nil, "the saved variables are not up yet."
	end

	Remember()
	local record = { name = clean, slots = {} }
	store[#store + 1] = record
	Told()
	return record
end

function Sets.Remove(name)
	local record, index = Find(name)
	if not record then
		return false, ("there is no set called %q."):format(tostring(name))
	end
	Remember()
	table.remove(Store(), index)
	Told()
	return true
end

function Sets.Rename(old, new)
	local record = Find(old)
	if not record then
		return false, ("there is no set called %q."):format(tostring(old))
	end
	local clean, why = Clean(new)
	if not clean then
		return false, why
	end
	local taken = Find(clean)
	if taken and taken ~= record then
		return false, ("there is already a set called %q."):format(clean)
	end
	Remember()
	-- Every square on an ad hoc bar that points at this set, rewritten before
	-- the name moves. A set on a bar is a macro square whose body names the set,
	-- and a macro is text: renaming the set would otherwise leave a square that
	-- refuses with "no set called Bling" for a set you are still looking at.
	-- The bars are ours, so this is a rewrite rather than a warning.
	local bars = ns.AdHoc
	if bars then
		bars.Renamed(record.name, clean)
	end
	record.name = clean
	Told()
	return true
end

-- What is worn in one slot, into the set.
--
-- An empty slot is captured as deliberately empty and never as unset, because a
-- save is a photograph of what you have on: the off hand you are not carrying
-- is part of the picture, and recording it as "no opinion" would make a set
-- that never takes the shield off again.
local function Take(record, slot)
	local link = Worn.Link(slot)
	local key = link and Key(link)
	record.slots[slot] = key and { key = key, link = link } or false
end

function Sets.Capture(name, slot)
	local record = Find(name)
	if not record then
		return false, ("there is no set called %q."):format(tostring(name))
	end
	Remember()
	if slot then
		Take(record, slot)
	else
		for index = 1, #ORDER do
			Take(record, ORDER[index])
		end
	end
	Told()
	return true
end

-- A piece into a slot it goes in, and a refusal naming the piece for one it
-- does not. Core/Gear.lua answers where an item lands, which is the same table
-- the compare tooltip and the charge macro read: a ring is two slots and a two
-- hander is one, and this file having its own opinion about that is how the two
-- drift apart.
function Sets.Put(name, slot, link)
	local record = Find(name)
	if not record then
		return false, ("there is no set called %q."):format(tostring(name))
	end
	local key = Key(link)
	if not key then
		return false, "that is not an item."
	end

	local lands = ns.Gear.Replaces(link) or {}
	local fits = false
	for index = 1, #lands do
		if lands[index] == slot then
			fits = true
		end
	end
	if not fits then
		return false, ("%s does not go in the %s slot."):format(link, Sets.Label(slot))
	end

	Remember()
	record.slots[slot] = { key = key, link = link }
	Told()
	return true
end

local function Write(name, slot, value)
	local record = Find(name)
	if not record then
		return false, ("there is no set called %q."):format(tostring(name))
	end
	Remember()
	record.slots[slot] = value
	Told()
	return true
end

function Sets.Empty(name, slot)
	return Write(name, slot, false)
end

function Sets.Clear(name, slot)
	return Write(name, slot, nil)
end

-- A group belongs to one set. Taking it off whoever held it is the whole of
-- what makes Active answerable: two sets both claiming group two would make
-- "the set for this spec" a question with two answers and a list order deciding
-- between them.
function Sets.Follow(name, group)
	local record = Find(name)
	if not record then
		return false, ("there is no set called %q."):format(tostring(name))
	end
	Remember()
	if group then
		for _, other in ipairs(Sets.All()) do
			if other.group == group then
				other.group = nil
			end
		end
	end
	record.group = group
	Told()
	return true
end

--------------------------------------------------------------------------
-- Reading it back against what you have on
--------------------------------------------------------------------------

-- Which talent group is live, through Class/Spec.lua, and nil on a client with
-- one of them. Probed rather than called flat, because a set with no group is
-- the whole answer on a client where the question does not arise and this file
-- is not the place to decide the client has dual spec.
local function Group()
	local Spec = ns.Class and ns.Class.Spec
	if not Spec or type(Spec.Group) ~= "function" then
		return nil
	end
	local ok, group = pcall(Spec.Group)
	return ok and group or nil
end

Sets.Group = Group

function Sets.Active()
	local group = Group()
	if not group then
		return nil
	end
	for _, record in ipairs(Sets.All()) do
		if record.group == group then
			return record
		end
	end
	return nil
end

-- Whether every entry in the set matches what is on you now.
--
-- Unset slots are not read at all, which is the point of them: a resist set you
-- are wearing over your own rings is a set you are wearing. Deliberately empty
-- is read, and a slot with something in it fails it.
function Sets.Wearing(name)
	local record = Find(name)
	if not record then
		return false
	end
	for index = 1, #ORDER do
		local slot = ORDER[index]
		local entry = record.slots[slot]
		local link = Worn.Link(slot)
		if entry == false then
			if link then
				return false
			end
		elseif entry and Key(link) ~= entry.key then
			return false
		end
	end
	return true
end

-- What one set reads as on a status line: how much of it you have on, and which
-- spec it is worn for.
function Sets.Describe(name)
	local record = Find(name)
	if not record then
		return "no such set"
	end
	local on, of = 0, 0
	for index = 1, #ORDER do
		local slot = ORDER[index]
		local entry = record.slots[slot]
		if entry ~= nil then
			of = of + 1
			local link = Worn.Link(slot)
			if entry == false then
				on = on + (link and 0 or 1)
			elseif Key(link) == entry.key then
				on = on + 1
			end
		end
	end
	local line = ("%d of %d on"):format(on, of)
	if record.group then
		line = ("%s, worn for talent group %d"):format(line, record.group)
	end
	return line
end
