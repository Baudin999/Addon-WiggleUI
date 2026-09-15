-- The professions.
--
-- Two windows, because the client has two and the addon walks both. Every
-- profession but enchanting is the trade skill window and answers the
-- GetTradeSkill names; enchanting is the craft window and answers a parallel
-- set whose returns are in a different order. That difference is the whole
-- reason this file exists rather than one window standing in for both: the
-- trade skill row says what kind of row it is second and the craft row says it
-- third, and a stub that answered the same shape twice would agree with a Core
-- shim that read the wrong slot.
--
-- What is modelled and is not a convenience: a category folded up hides its
-- recipes. The client does not answer a list with holes in it, it answers a
-- shorter list, so the rows here are derived from the fixture rather than being
-- the fixture. That is the one thing the reagent walk has to get right, because
-- a walk that could not see everything is a walk that must not delete anything.

local H = ...
local ITEMS, itemLink = H.ITEMS, H.itemLink

-- The reagents, added to the item table the rest of the client reads so a link
-- off a recipe reads back as an id exactly the way a link out of a bag does.
-- Class 7 is a trade good, which is what every one of these is.
ITEMS["Copper Bar"] = { id = 7001, classId = 7, quality = 1, price = 40,
	icon = "Interface\\Icons\\Bar", stack = 20 }
ITEMS["Rough Stone"] = { id = 7002, classId = 7, quality = 1, price = 10,
	icon = "Interface\\Icons\\Stone", stack = 20 }
ITEMS["Silver Bar"] = { id = 7003, classId = 7, quality = 1, price = 300,
	icon = "Interface\\Icons\\Bar", stack = 20 }
ITEMS["Coarse Stone"] = { id = 7004, classId = 7, quality = 1, price = 25,
	icon = "Interface\\Icons\\Stone", stack = 20 }
-- Strange Dust is not here: 04-hands.lua already carries it, with the subclass
-- the loot filter's enchanting rule reads, and a second definition under the
-- same name would land on top of that one and take the subclass away.
ITEMS["Lesser Magic Essence"] = { id = 7006, classId = 7, quality = 1, price = 400,
	icon = "Interface\\Icons\\Essence", stack = 10 }

-- One profession, in the shape the window lists it: two categories with recipes
-- under each. Two headers rather than one because a header is the row the walk
-- has to skip, and a fixture with one of them proves only that the walk skipped
-- the first row.
--
-- The tables are the file's own and a section reaches them through the handle
-- at the foot, which is how 70-reagents.lua takes a recipe away and puts it
-- back without this file carrying a call for it.
local TRADE = {
	Blacksmithing = {
		{ header = true, expanded = true, name = "Weapons" },
		{ name = "Rough Sharpening Stone", reagents = { "Rough Stone" } },
		{ name = "Copper Chain Belt", reagents = { "Copper Bar" } },
		{ header = true, expanded = true, name = "Armor" },
		{ name = "Silvered Bronze Breastplate",
			reagents = { "Silver Bar", "Coarse Stone", "Copper Bar" } },
	},
}

-- Enchanting, which is the craft window. A shorter list on purpose: what this
-- fixture is for is that a second window's ids join the first window's without
-- either replacing the other, and two recipes say that as well as twenty.
local CRAFTS = {
	Enchanting = {
		{ header = true, expanded = true, name = "Bracer" },
		{ name = "Enchant Bracer - Minor Health", reagents = { "Strange Dust" } },
		{ name = "Enchant Chest - Lesser Mana",
			reagents = { "Lesser Magic Essence", "Strange Dust" } },
	},
	-- A hunter's pet, which is the same window with no skill line, no reagents
	-- and a price in training points. One row of each state the page draws: a
	-- rank the pet has, a rank it can be taught, one the points do not reach
	-- and one it is too young for, with a header between so a walk that took
	-- one for an ability would draw a square too many.
	["Beast Training"] = {
		training = true,
		{ name = "Bite", sub = "Rank 7", kind = "used", cost = 0, level = 48 },
		{ name = "Bite", sub = "Rank 8", cost = 17, level = 56 },
		{ header = true, expanded = true, name = "Resistances" },
		{ name = "Great Stamina", sub = "Rank 10", cost = 150, level = 50 },
		{ name = "Dash", sub = "Rank 3", cost = 20, level = 70 },
	},
}

local trade, craft, linked = nil, nil, false

-- What a window is listing. A category that is folded up is on the list and
-- everything under it is not, which is the client's own answer and the shape
-- the walk has to survive.
local function listing(fixture)
	local out = {}
	local hidden = false
	for _, row in ipairs(fixture or {}) do
		if row.header then
			hidden = not row.expanded
			out[#out + 1] = row
		elseif not hidden then
			out[#out + 1] = row
		end
	end
	return out
end

local function tradeRows()
	return listing(trade and TRADE[trade])
end

local function craftRows()
	return listing(craft and CRAFTS[craft])
end

-- The reagent link for one row of one window, or nil where the index names a
-- row that is not there. The client answers nil for an index off the end and
-- for a category, and both are indexes the addon is not supposed to ask about.
local function reagentAt(rows, index, which)
	local row = rows[index]
	local name = row and row.reagents and row.reagents[which]
	if not name then
		return nil
	end
	return itemLink(name)
end

-- UNKNOWN and three zeroes with no window open, which is the client's own
-- answer and is the reason ns.TradeSkillName reads that string as "no window"
-- rather than as a profession nobody has heard of.
_G.GetTradeSkillLine = function()
	if not trade then
		return "UNKNOWN", 0, 0
	end
	return trade, 300, 375
end

_G.GetNumTradeSkills = function()
	return #tradeRows()
end

-- A recipe answers optimal unless the fixture names a difficulty, which is how
-- a section makes one recipe grey without a second fixture to keep in step with
-- this one.
_G.GetTradeSkillInfo = function(index)
	local row = tradeRows()[index]
	if not row then
		return nil
	end
	return row.name, row.header and "header" or (row.kind or "optimal"), 1,
		row.expanded and true or false
end

_G.GetTradeSkillNumReagents = function(index)
	local row = tradeRows()[index]
	return row and row.reagents and #row.reagents or 0
end

_G.GetTradeSkillReagentItemLink = function(index, which)
	return reagentAt(tradeRows(), index, which)
end

_G.IsTradeSkillLinked = function()
	return linked
end

-- No skill line for beast training, which is what ns.CraftName reads as no
-- profession and the reagent walk as nothing to walk.
_G.GetCraftDisplaySkillLine = function()
	if not craft or CRAFTS[craft].training then
		return "UNKNOWN", 0, 0
	end
	return craft, 300, 375
end

-- The window's title, which is the profession or the spell that opened it.
_G.GetCraftName = function()
	return craft or "UNKNOWN"
end

_G.GetNumCrafts = function()
	return #craftRows()
end

-- The kind third and the expanded flag fifth, which is where the craft window
-- really puts them and is the one thing about this file that is not the same
-- as the trade skill half above.
_G.GetCraftInfo = function(index)
	local row = craftRows()[index]
	if not row then
		return nil
	end
	return row.name, row.sub, row.header and "header" or (row.kind or "optimal"), 1,
		row.expanded and true or false, row.cost or 0, row.level or 0
end

_G.GetCraftIcon = function(index)
	local row = craftRows()[index]
	return row and ("Interface\\Icons\\" .. row.name:gsub("%s", "")) or nil
end

-- The pet's training points. Two hundred earned and a hundred and fifty spent,
-- so the rank at seventeen fits and the one at a hundred and fifty does not.
local training = { total = 200, spent = 150, taught = {} }

_G.GetPetTrainingPoints = function()
	return training.total, training.spent
end

_G.UnitCreatureFamily = function(unit)
	return unit == "pet" and "Wolf" or nil
end

-- A pet taught, the way the server teaches one: refused where the client's own
-- create button would be disabled, and both events on the way back.
_G.DoCraft = function(index)
	local row = craftRows()[index]
	training.taught[#training.taught + 1] = index
	if not row or row.header or row.kind == "used" then
		return
	end
	if (row.level or 0) > _G.UnitLevel("pet") or (row.cost or 0) > training.total - training.spent then
		return
	end
	row.kind = "used"
	training.spent = training.spent + (row.cost or 0)
	H.fire("UNIT_PET_TRAINING_POINTS", "pet")
	H.fire("CRAFT_UPDATE")
end

-- The client's own frame, standing from the start the way PlayerTalentFrame
-- is in 18-talents.lua, so the park has something to move. UIParent shows it
-- on CRAFT_SHOW and hides it on CRAFT_CLOSE, ahead of any addon.
local craftFrame = H.region("frame", _G.UIParent, "CraftFrame")
craftFrame:SetSize(384, 512)
craftFrame:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116)
craftFrame:Hide()
_G.CraftFrame = craftFrame

-- The row picked and the button that teaches it. Blizzard's OnClick is the
-- only caller of DoCraft, and it reads the selection rather than being handed a
-- row, which is why the page has to pick one before the secure click lands.
local selection = 0
_G.SelectCraft = function(index)
	selection = index
end
_G.GetCraftSelectionIndex = function()
	return selection
end

local createButton = _G.CreateFrame("Button", "CraftCreateButton", craftFrame)
createButton:SetSize(80, 22)
createButton:SetPoint("CENTER", craftFrame, "TOPLEFT", 224, -422)
createButton:Disable()
createButton:SetScript("OnClick", function()
	_G.DoCraft(_G.GetCraftSelectionIndex())
end)
_G.CraftCreateButton = createButton

-- Blizzard_CraftUI's own pick: the selection, and the button enabled for a row
-- that has no missing reagent and is not one the pet has.
_G.CraftFrame_SetSelection = function(index)
	local row = craftRows()[index]
	if not row or row.header then
		return
	end
	_G.SelectCraft(index)
	if row.kind == "used" then
		createButton:Disable()
	else
		createButton:Enable()
	end
end

_G.CloseCraft = function()
	craft = nil
	craftFrame:Hide()
	H.fire("CRAFT_CLOSE")
end

_G.GetCraftNumReagents = function(index)
	local row = craftRows()[index]
	return row and row.reagents and #row.reagents or 0
end

_G.GetCraftReagentItemLink = function(index, which)
	return reagentAt(craftRows(), index, which)
end

-- The handle a section drives all of this from. Opening a window fires the
-- event the client fires and nothing else happens on its own, which is the
-- point: the section decides when an update comes past.
H.professions = {
	TRADE = TRADE,
	CRAFTS = CRAFTS,
	open = function(name)
		trade = name
		H.fire("TRADE_SKILL_SHOW")
	end,
	update = function()
		H.fire("TRADE_SKILL_UPDATE")
	end,
	close = function()
		trade = nil
	end,
	openCraft = function(name)
		craft = name
		craftFrame:Show()
		H.fire("CRAFT_SHOW")
	end,
	updateCraft = function()
		H.fire("CRAFT_UPDATE")
	end,
	closeCraft = function()
		craft = nil
		craftFrame:Hide()
	end,
	training = training,
	craftFrame = craftFrame,
	-- Somebody else's profession, opened from a link in chat. A flag rather
	-- than a second fixture, because what the addon has to do about it is
	-- refuse to read the window at all.
	link = function(yes)
		linked = yes and true or false
	end,
}
