local ADDON, ns = ...

local Book = {}
ns.DebuffBook = Book

--------------------------------------------------------------------------
-- Which aura a spell really leaves on a mob
--
-- The debuff row matches auras by their localised name, which is what makes
-- rank a non-question: Rend rank 1 and Rend rank 8 are both "Rend". What the
-- name match cannot fix is a spell whose aura is called something else. Drag
-- the Deep Wounds talent onto the row and the square waits for an aura called
-- "Deep Wounds"; the bleed that lands is "Deep Wound". Drag Charge and it
-- waits for "Charge"; the mob is holding "Charge Stun".
--
-- Debuffs.lua is the answer, baked out of Blizzard's spell tables: every aura
-- a class puts on a mob, and the spell or talent that leads to each one when
-- it is not the aura itself. This file asks it three ways, one per door onto
-- the row: a spell dropped from the spellbook, a talent dropped from the talent
-- window, and a name typed into the box.
--
-- Every answer is the first id of the aura's name, which is rank 1 where there
-- are ranks. Two ids with one name are refused by the row as a duplicate, so a
-- single id per name is also what keeps the refusal honest.
--------------------------------------------------------------------------

local Data = ns.DebuffData

-- An id the row once offered that no aura will ever carry, and the id that
-- works in its place.
--
-- 12162 is a Deep Wounds talent id the old picker offered and some saved lists
-- still carry. It is not in the anniversary client's Talent table, whose three
-- ranks are the ones Debuffs.lua leads to the bleed, so the bake cannot reach
-- it. It stays here so a list saved before the bake still repairs at login and
-- a number typed off Wowhead, whose search lands on this id first, still turns
-- into the bleed.
local REPLACED = {
	[12162] = 12721, -- the Deep Wounds talent, for the Deep Wound bleed
}

-- The client's name for every aura in the book, to its id, built the first
-- time anything asks. Not at load: the client's spell data is not promised
-- before login, and the book is only asked from a page or a drop.
local byName = nil

local function Names()
	if byName then
		return byName
	end
	byName = {}
	for _, id in ipairs(Data.AURAS) do
		local name = ns.SpellName(id)
		if name and not byName[name] then
			byName[name] = id
		end
	end
	return byName
end

-- The aura a spell leaves, as the book's id for it, or nil when the book does
-- not know the spell as anything that lands on a mob.
function Book.Aura(spellID)
	spellID = REPLACED[spellID] or Data.LEADS[spellID] or spellID
	local name = ns.SpellName(spellID)
	return name and Names()[name] or nil
end

-- The same, for a spell the book may not know: a number typed at the slash
-- word stays itself rather than being refused, because the book is a list of
-- class spells and a boss's debuff is a fair thing to watch.
function Book.Canonical(spellID)
	return Book.Aura(spellID) or REPLACED[spellID] or spellID
end

-- The aura a talent leads to. By the Talent table's id, which is what the
-- talent window holds, and by its name for a client that answers no id: a
-- talent like Mortal Strike is its own aura.
function Book.ForTalent(talentID, name)
	local id = talentID and Data.TALENTS[talentID]
	if id then
		return id
	end
	return name and Names()[name] or nil
end

-- The auras whose name has `text` in it, ignoring case, names that start with
-- it first and then the rest, each group alphabetical. At most `limit`, and
-- none that `skip(id)` answers true for, which is how the row leaves out what
-- it already tracks.
function Book.Search(text, limit, skip)
	local wanted = (text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if wanted == "" then
		return {}
	end

	local starts, inside = {}, {}
	for name, id in pairs(Names()) do
		local at = name:lower():find(wanted, 1, true)
		if at and not (skip and skip(id)) then
			local into = at == 1 and starts or inside
			into[#into + 1] = { id = id, name = name }
		end
	end

	local function ByName(a, b)
		return a.name < b.name
	end
	table.sort(starts, ByName)
	table.sort(inside, ByName)

	local out = {}
	for _, list in ipairs({ starts, inside }) do
		for _, entry in ipairs(list) do
			if #out >= limit then
				return out
			end
			out[#out + 1] = entry.id
		end
	end
	return out
end
