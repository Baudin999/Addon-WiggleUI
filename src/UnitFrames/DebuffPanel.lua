local ADDON, ns = ...

local DebuffPanel = {}
ns.DebuffPanel = DebuffPanel

--------------------------------------------------------------------------
-- The debuff row, on the page
--
-- Which debuffs the row over each enemy bar watches, drawn as that row: one
-- square per debuff, in the order they draw, and an empty one at the end that
-- a drop lands on. It is what the cooldown and buff pages already do with
-- their rows, and it replaced a list of names with a remove button each and a
-- box that took a spell id.
--
-- Three ways on, because a debuff comes from three places:
--
--   a spell dragged out of the spellbook, off the client's cursor;
--   a talent dragged out of the talent window, through UI/Carry.lua, because
--   the passive ones are what PickupSpell refuses and they are the ones worth
--   watching: Deep Wounds, Blood Frenzy, Improved Hamstring;
--   a name typed into the box under the row, picked from what matches.
--
-- Every one of them goes through UnitFrames/Book.lua first, which turns what
-- you gave it into the aura that lands on the mob. So the talent watches the
-- bleed, Charge watches Charge Stun, and rank never comes into it: the row
-- matches on the name and the book hands over rank 1.
--
-- Two ways off: drag the square off the row, or right click it. A drag from
-- one square onto another moves it there, which is how the order is set.
--
-- Nothing here writes the list. EnemyBars.lua owns it; this file asks it what
-- is in which slot and tells it where a drop landed.
--------------------------------------------------------------------------

local M, C = ns.UI.Metric, ns.UI.Color

-- A square on the page, and the air between two.
local EDGE, GAP = 30, 4

-- How many matches the name box folds out at once. Past eight, the name typed
-- is too short to be the one you meant, and another letter is quicker than a
-- scroll.
local MATCHES = 8

-- The pool, built once at login, one past the most the bar tracks for the
-- empty square at the end.
local squares = {}

-- Which square a button belongs to, for the drag between two of them, which
-- nothing rides the cursor for.
local owner = {}

-- The slot being dragged, set when the drag starts and read when the button
-- comes up, which is inside one gesture and never outside one.
local pending = nil

--------------------------------------------------------------------------
-- What a drop is holding
--------------------------------------------------------------------------

-- A refusal is said once per reason rather than once per ask, the way the
-- cooldown page says its own. The hover asks as well as the drop, and a
-- sentence printed every time the pointer crossed a square would be noise.
local told = {}

local function Say(line)
	if told[line] then
		return
	end
	told[line] = true
	ns.Print(line)
end

-- The aura a spell leaves, or a refusal. A spell that lands nothing on a mob is
-- refused here rather than put on the row as a square that never lights.
local function Aura(spellID)
	local aura = ns.DebuffBook.Aura(spellID)
	if not aura then
		Say(("%s puts nothing on a mob that the row can watch.")
			:format(ns.SpellName(spellID) or ("spell " .. spellID)))
	end
	return aura
end

local function Take(kind, a, b, c)
	if kind == "spell" then
		local id = ns.SpellIdOnCursor(a, b, c)
		if id then
			return Aura(id)
		end
		Say("this client would not say which spell that was.")
		return nil
	end
	if kind then
		Say(("a %s is not something the debuff row watches. Drag a spell or a talent."):format(kind))
	end
	return nil
end

-- A talent out of the talent window.
local function Carried(held)
	if type(held) ~= "table" or not held.name then
		return nil
	end
	local aura = ns.DebuffBook.ForTalent(held.talent, held.name)
	if not aura then
		Say(("%s puts nothing on a mob that the row can watch."):format(held.name))
	end
	return aura
end

--------------------------------------------------------------------------
-- The two ends of a drag
--------------------------------------------------------------------------

local function Lift(w)
	pending = ns.EnemyBars.Spells()[w.at] and w.at or nil
end

-- Onto another square of the row, it moves there. Anywhere else, it comes off.
local function Landed()
	local from = pending
	pending = nil
	if not from then
		return
	end
	local focus = ns.MouseFocus()
	local w = focus and owner[focus] or nil
	if w then
		ns.EnemyBars.MoveSpell(from, w.at)
		return
	end
	ns.EnemyBars.RemoveSpell(ns.EnemyBars.Spells()[from])
end

-- A drop on a square goes in at that square, pushing the rest along, so a
-- drop on the empty one at the end goes on the end. A right click is nil and
-- takes the square's own debuff off.
local function Drop(w, spellID)
	if spellID == nil then
		local id = ns.EnemyBars.Spells()[w.at]
		return id ~= nil and ns.EnemyBars.RemoveSpell(id)
	end
	local ok, message = ns.EnemyBars.AddSpell(spellID, w.at)
	if not ok then
		ns.Print(message)
	end
	return ok
end

--------------------------------------------------------------------------
-- One square
--------------------------------------------------------------------------

local function Says(w)
	local id = ns.EnemyBars.Spells()[w.at]
	if not id then
		return { kind = "note", title = "an empty square",
			lines = { "Drag a spell here out of your spellbook, or a talent out of"
				.. " the talent window, or type its name in the box below." } }
	end
	return { kind = "note", title = ns.SpellName(id) or ("spell " .. id),
		lines = { "Drag it onto another square to move it there.",
			"Drag it off the row, or right click, to stop watching it." } }
end

local function Square(frame, at)
	local w
	w = ns.UI.DropSquare(frame, EDGE, function()
		local id = ns.EnemyBars.Spells()[w.at]
		return id and ns.SpellTexture(id), id and ns.SpellName(id)
	end, function(spellID)
		return Drop(w, spellID)
	end, {
		take = Take,
		carried = Carried,
		after = ns.Options.Refresh,
		drag = function() Lift(w) end,
		landed = Landed,
		describe = function() return Says(w) end,
	})
	w.at = at
	owner[w.button] = w
	return w
end

-- The row laid out at the page's width, wrapped, and how tall it came out.
-- Every used square and the empty one after them, which is not drawn once the
-- bar is full, because a square that refuses every drop is not an invitation.
local function Lay(width)
	local count = #ns.EnemyBars.Spells()
	local shown = math.min(count + 1, ns.EnemyBars.MaxSpells())
	local across = math.max(1, math.floor((width + GAP) / (EDGE + GAP)))
	for index, w in ipairs(squares) do
		if index <= shown then
			local column, row = (index - 1) % across, math.floor((index - 1) / across)
			w:ClearAllPoints()
			w:SetPoint("TOPLEFT", column * (EDGE + GAP), -row * (EDGE + GAP))
			w:Show()
			w.Refresh()
		else
			w:Hide()
		end
	end
	local rows = math.floor((shown - 1) / across) + 1
	return rows * (EDGE + GAP) - GAP
end

local function Row(ui)
	ui.Custom(function(frame)
		for index = 1, ns.EnemyBars.MaxSpells() do
			squares[index] = Square(frame, index)
		end
		return function()
			return Lay(frame:GetWidth())
		end
	end, { height = EDGE, label = "the debuffs the row over each bar watches" })
end

--------------------------------------------------------------------------
-- The name box
--
-- Type part of a name and the matches fold out under it, with their icons,
-- names that start with what you typed first. A click on one puts it on the
-- row; enter puts the top one on. The box empties once something went on, so
-- the next name starts from nothing.
--
-- What is already on the row is left out of the matches, because offering it
-- only to refuse it is a question with one wrong answer.
--------------------------------------------------------------------------

local function Tracked(id)
	return ns.EnemyBars.Slot(id) ~= nil
end

local function Matches(text)
	local options = {}
	for _, id in ipairs(ns.DebuffBook.Search(text, MATCHES, Tracked)) do
		options[#options + 1] = { value = id, text = ns.SpellName(id), icon = ns.SpellTexture(id) }
	end
	return options
end

local function Put(edit, id)
	local ok, message = ns.EnemyBars.AddSpell(id)
	if not ok then
		ns.Print(message)
		return
	end
	edit:SetText("")
	ns.Options.Refresh()
end

local function NameBox(frame, popup)
	local label = ns.UI.Label(frame, M.font, C.text, "LEFT", ns.UI.FLAT)
	label:SetPoint("LEFT")
	label:SetText("add by name")

	local box = ns.UI.Box(frame, C.sunken, C.edge)
	box:SetSize(168, M.control)
	box:SetPoint("TOPRIGHT")

	local edit = CreateFrame("EditBox", nil, box)
	edit:SetPoint("TOPLEFT", 4, 0)
	edit:SetPoint("BOTTOMRIGHT", -4, 0)
	edit:SetFontObject(ns.UI.Font(M.font, ns.UI.FLAT))
	edit:SetTextColor(C.text[1], C.text[2], C.text[3])
	edit:SetAutoFocus(false)
	edit:SetMaxLetters(40)

	local function Fold()
		local options = Matches(edit:GetText())
		if #options == 0 then
			ns.UI.CloseDropdown()
			return
		end
		ns.UI.OpenDropdown(popup(), box, options, function(id) Put(edit, id) end)
	end

	edit:SetScript("OnTextChanged", Fold)
	edit:SetScript("OnEnterPressed", function(self)
		local first = Matches(self:GetText())[1]
		ns.UI.CloseDropdown()
		if first then
			Put(self, first.value)
		end
	end)
	edit:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		ns.UI.CloseDropdown()
		self:ClearFocus()
	end)
	edit:SetScript("OnEditFocusGained", function(self)
		ns.UI.StopCapture()
		ns.UI.Typing(self)
		ns.UI.Tint(box.bg, C.selected)
		Fold()
	end)
	-- The list stays up when the box loses the keyboard, because a click on a
	-- match is what takes the keyboard away, and closing the list there would
	-- eat the click it was for.
	edit:SetScript("OnEditFocusLost", function()
		ns.UI.StopTyping()
		ns.UI.Tint(box.bg, C.sunken)
	end)
	edit:SetScript("OnHide", function(self)
		self:ClearFocus()
		ns.UI.CloseDropdown()
	end)
end

--------------------------------------------------------------------------
-- The section
--------------------------------------------------------------------------

function DebuffPanel.Draw(ui)
	ui.Section("Debuffs on the bar", "Frames")
	ui.Lede("A row of icons over each bar: bright is yours, grey is somebody else's, faint is nobody's.")

	Row(ui)

	ui.Custom(function(frame, popup)
		NameBox(frame, popup)
	end, { height = M.control, label = "add a debuff by name" })
	ui.Hint("Drag a spell or a talent onto the row, or type part of a name. Drag a square to move it, off the row or right click to remove it. A talent watches the debuff it leaves; every rank counts.")

	-- One pixel a step. It used to be two, which stepped straight over the
	-- sizes that draw sharp, on a range that stopped short of the biggest of
	-- them.
	local iconLow, iconHigh = ns.EnemyBars.IconRange()
	ui.Slider("icon size", iconLow, iconHigh, 1,
		function() return ns.db.barsIconSize end,
		function(value)
			ns.db.barsIconSize = value
			ns.EnemyBars.ApplyLayout()
			ns.EnemyBars.Rebuild()
		end,
		function(value) return value .. "px" end)
	ui.Hint("The row packs against the right end of the gauge and wraps upwards, so a long list on a narrow bar becomes two rows rather than icons hanging off the left edge.")

	ui.Action(function() return "back to the ones your spec ships with" end, function()
		ns.EnemyBars.ResetSpells()
		ns.Options.Refresh()
	end)

	ui.Reading("slots used", function()
		local spells = ns.EnemyBars.Spells()
		local unknown = ns.EnemyBars.Unresolved()
		if #unknown > 0 then
			return ("%d of %d, and this client cannot name %s")
				:format(#spells, ns.EnemyBars.MaxSpells(), table.concat(unknown, ", "))
		end
		return ("%d of %d"):format(#spells, ns.EnemyBars.MaxSpells())
	end)
	ui.Reading("icons", ns.EnemyBars.DescribeIcon)
end
