-- Bakes src/UnitFrames/Debuffs.lua out of Blizzard's own spell tables.
--
--   lua5.1 scripts/bake-debuffs.lua <path to a folder of exports>
--
-- Run through scripts/bake-debuffs.sh, which fetches the exports. Not part of
-- the addon and never loaded by a client.
--
-- Two answers come out of it, and the debuff row on the enemy bars needs both.
--
-- Which auras a player puts on a mob. Every spell a class skill line teaches,
-- and every rank of every talent, that applies an aura to an enemy target. The
-- name box on the panel searches this, so typing "sun" finds Sunder Armor
-- without anybody knowing its number.
--
-- Which aura a spell leaves when it is not the aura itself. A talent is mostly
-- a passive that procs something else: Improved Hamstring is 12289 and the root
-- it leaves is 23694, under another name. Dragged onto the row, the talent has
-- to become the root, or the square waits for an aura called Improved Hamstring
-- that never lands. Those edges are in SpellEffect as trigger spells, one hop.
--
-- One entry per name, the lowest id that carries it. The row matches on the
-- name, so rank 1 stands for every rank and rank never has to be picked.

local CSV = dofile("scripts/csv.lua")
local Rows = CSV.Rows

-- CategoryID 7 in SkillLine is "Class Skills": the talent trees, the class's
-- own general line, and the hunter pet families.
local CLASS_SKILLS = "7"

-- SpellEffect.Effect values. APPLY_AURA is the one that puts something on a
-- unit; TRIGGER_SPELL casts a second spell as part of the first.
local APPLY_AURA, TRIGGER_SPELL = 6, 64

-- EffectAura values that cast a second spell from inside an aura: a proc, a
-- periodic one, and a proc on whoever the hit landed on.
local TRIGGERS = { [42] = true, [23] = true, [109] = true }

-- EffectAura values that are a talent's own passive and never land on a mob,
-- whatever ImplicitTarget the row carries. Improved Mortal Strike is two spell
-- modifiers aimed at "the enemy", and Improved Hamstring is a proc aimed the
-- same way. The periodic trigger is not here: that one is a real debuff.
local PASSIVE = { [42] = true, [107] = true, [108] = true, [109] = true }

-- The ImplicitTarget values that mean an enemy: the target, an area round a
-- point or a caster, a cone, a persistent area, and a channel's target.
local ENEMY = {
	[6] = true, [15] = true, [16] = true, [24] = true, [28] = true,
	[54] = true, [77] = true, [104] = true,
}

-- The edges SpellEffect cannot give, because the talent is a dummy effect a
-- server script reads. By name on both ends, so no id here was typed: the ids
-- come out of the same tables as everything else.
--
-- Deep Wounds is the talent and Deep Wound, singular, is the bleed. The row
-- used to offer the talent and its square never lit once.
local SCRIPTED = {
	["Deep Wounds"] = "Deep Wound",
}

local root = ...
if not root then
	io.stderr:write("usage: lua5.1 bake-debuffs.lua <path to a folder of exports>\n")
	os.exit(2)
end
root = root:gsub("/$", "")

local function Load(name)
	local held, why = Rows(root .. "/" .. name)
	if not held then
		io.stderr:write(tostring(why) .. "\n")
		os.exit(1)
	end
	return held
end

--------------------------------------------------------------------------
-- What a class casts
--------------------------------------------------------------------------

local function ClassSpells(lines, abilities, talents)
	local classLine = {}
	for _, row in ipairs(lines) do
		if row.CategoryID == CLASS_SKILLS then
			classLine[row.ID] = true
		end
	end

	local spells = {}
	for _, row in ipairs(abilities) do
		if classLine[row.SkillLine] then
			spells[tonumber(row.Spell)] = true
		end
	end
	for _, row in ipairs(talents) do
		for rank = 0, 8 do
			local id = tonumber(row["SpellRank_" .. rank])
			if id and id > 0 then
				spells[id] = true
			end
		end
	end
	return spells
end

--------------------------------------------------------------------------
-- What a spell does
--------------------------------------------------------------------------

-- Per spell, whether it puts an aura on an enemy and which spells it casts
-- after it. The export is filtered on the Effect column and the filter is a
-- substring match, so every row is checked for the value it was fetched for.
local function Effects(rows)
	local harmful, leads = {}, {}
	for _, row in ipairs(rows) do
		local spell = tonumber(row.SpellID)
		local effect = tonumber(row.Effect)
		local aura = tonumber(row.EffectAura)
		local target = tonumber(row.ImplicitTarget_0)
		local second = tonumber(row.ImplicitTarget_1)
		local trigger = tonumber(row.EffectTriggerSpell) or 0
		local difficulty = tonumber(row.DifficultyID) or 0

		if difficulty == 0 and effect == APPLY_AURA and not PASSIVE[aura]
				and (ENEMY[target] or ENEMY[second]) then
			harmful[spell] = true
		end
		if difficulty == 0 and trigger > 0
				and (effect == TRIGGER_SPELL or (effect == APPLY_AURA and TRIGGERS[aura])) then
			leads[spell] = leads[spell] or {}
			table.insert(leads[spell], trigger)
		end
	end
	return harmful, leads
end

--------------------------------------------------------------------------
-- The two answers
--------------------------------------------------------------------------

local names = {}
for _, row in ipairs(Load("SpellName.csv")) do
	names[tonumber(row.ID)] = row.Name_lang
end

local talents = Load("Talent.csv")
local class = ClassSpells(Load("SkillLine.csv"), Load("SkillLineAbility.csv"), talents)
local harmful, triggers = Effects(Load("SpellEffect.csv"))

-- The lowest id for each name among the spells kept, which is what both lists
-- are written in.
local first = {}
local function Keep(id)
	local name = names[id]
	if name and name ~= "" and (not first[name] or id < first[name]) then
		first[name] = id
	end
end

local auras = {}
for id in pairs(class) do
	if harmful[id] then
		auras[id] = true
		Keep(id)
	end
end

-- One hop from a class spell to an enemy aura it casts. A class spell that is
-- itself a debuff keeps its own name even when it casts a second one, because
-- the name on the spellbook is the name on the mob.
local leads = {}
for id in pairs(class) do
	if not harmful[id] then
		for _, to in ipairs(triggers[id] or {}) do
			if harmful[to] and names[to] then
				auras[to] = true
				Keep(to)
				leads[id] = to
				break
			end
		end
	end
end

-- The scripted edges, by name, for every rank of the talent.
local complaints = {}
for from, to in pairs(SCRIPTED) do
	local target, found = nil, false
	for id in pairs(harmful) do
		if names[id] == to and (not target or id < target) then
			target = id
		end
	end
	if target then
		auras[target] = true
		Keep(target)
		for id in pairs(class) do
			if names[id] == from then
				leads[id] = target
				found = true
			end
		end
	end
	if not target or not found then
		complaints[#complaints + 1] = ("%s -> %s did not resolve"):format(from, to)
	end
end

if #complaints > 0 then
	for _, line in ipairs(complaints) do
		io.stderr:write(line .. "\n")
	end
	os.exit(1)
end

-- Every lead points at the first id of its aura's name, so a talent and the
-- spell it procs agree with the name box on one number.
local list = {}
for name, id in pairs(first) do
	list[#list + 1] = { id = id, name = name }
end
table.sort(list, function(a, b)
	if a.name ~= b.name then
		return a.name < b.name
	end
	return a.id < b.id
end)

local order = {}
for from, to in pairs(leads) do
	leads[from] = first[names[to]]
	order[#order + 1] = from
end
table.sort(order)

-- Per talent, the aura it ends in: its own name when a rank of it is a debuff,
-- or the one its first rank leads to. Keyed on the Talent table's own id,
-- because that is what the talent window has in hand; it holds no spell id.
local byTalent, talentOrder = {}, {}
for _, row in ipairs(talents) do
	local spell = tonumber(row.SpellRank_0)
	local aura = spell and (harmful[spell] and first[names[spell]] or leads[spell])
	if aura then
		local id = tonumber(row.ID)
		byTalent[id] = aura
		talentOrder[#talentOrder + 1] = id
	end
end
table.sort(talentOrder)

--------------------------------------------------------------------------
-- The file
--------------------------------------------------------------------------

local out = assert(io.open("src/UnitFrames/Debuffs.lua", "w"))
out:write([[
local ADDON, ns = ...

-- Generated by ./scripts/bake-debuffs.sh. Do not hand edit.
--
-- The auras a player class puts on a mob, and the aura a spell or a talent
-- leaves when it is not that aura itself. UnitFrames/Book.lua reads these for
-- the debuff row on the enemy bars: the name box searches AURAS, a spell
-- dragged onto the row is looked up in LEADS, and a talent dragged out of the
-- talent window in TALENTS. So the Improved Hamstring talent becomes the root
-- it procs and the Deep Wounds talent becomes the Deep Wound bleed.
--
-- Nothing here was typed. SkillLine and SkillLineAbility say which spells a
-- class casts, Talent adds every rank of every talent, and SpellEffect says
-- which of those puts an aura on an enemy and which casts another spell. One id
-- per name, the lowest, because the row matches on the name and rank 1 stands
-- for every rank. The names beside the ids are the English ones the bake read;
-- the addon asks the client for its own.

ns.DebuffData = {}

ns.DebuffData.AURAS = {
]])
for _, entry in ipairs(list) do
	out:write(("\t%d, -- %s\n"):format(entry.id, entry.name))
end
out:write("}\n\nns.DebuffData.LEADS = {\n")
for _, from in ipairs(order) do
	out:write(("\t[%d] = %d, -- %s, %s\n"):format(from, leads[from], names[from], names[leads[from]]))
end
out:write("}\n\nns.DebuffData.TALENTS = {\n")
for _, id in ipairs(talentOrder) do
	out:write(("\t[%d] = %d, -- %s\n"):format(id, byTalent[id], names[byTalent[id]]))
end
out:write("}\n")
out:close()

io.stdout:write(("%d auras, %d leads, %d talents\n"):format(#list, #order, #talentOrder))
