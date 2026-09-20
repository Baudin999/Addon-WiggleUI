local ADDON, ns = ...

local Themes = ns.Themes

--------------------------------------------------------------------------
-- Themes you make yourself
--
-- The three the addon ships are one decision taken for twenty-three elements
-- at once, and that is their whole value: you pick a word and the screen
-- agrees with itself. It is also their whole limit. Somebody who wants the
-- quest tracker at a fifth, the chat window under the pointer and the action
-- bars gone the moment a fight ends has nothing to pick, because no word on
-- the list is that sentence.
--
-- So a theme of your own is the same table with its cells written by hand.
-- Every element is named, the way the shipped three are, and each cell carries
-- the three dials Themes.Cell reads: the fraction it is drawn at, whether the
-- pointer brings it to full, and the fraction it is drawn at in a fight.
--
-- It lives in the account's saved variables rather than in a file, and it is a
-- record rather than a setting: Core keeps it out of the reset, because a
-- button about the screen's layout has no business deleting a theme somebody
-- spent an evening on.
--
-- Nothing here draws anything. Theme/Theme.lua applies whichever theme is
-- chosen and does not care which of the two kinds it is; Theme/Creator.lua is
-- the page that writes these cells. This file is the list, the names and the
-- one shape a cell is allowed to have.
--------------------------------------------------------------------------

-- Eight is not a technical limit. It is the number past which a dropdown of
-- themes stops being a list you read and starts being one you search, and
-- nobody wants nine answers to "how much of the addon is on the screen".
Themes.MAX_OWN = 8

-- The longest name, which is what the field on the page accepts. A theme name
-- is read in a dropdown next to `informational`, so it has that much room.
local MAX_NAME = 24

-- The word the wiggle uses for no target, which is therefore not a name a
-- theme may take: a theme called `none` could never be wiggled to.
local RESERVED = { none = true }

-- Whether a word is one of the two ways the experience rail is drawn.
local function Rail(style)
	for _, known in ipairs(Themes.RAILS) do
		if style == known then
			return true
		end
	end
	return false
end

local function Clamp(value)
	if value < 0 then
		return 0
	elseif value > 1 then
		return 1
	end
	return value
end

--------------------------------------------------------------------------
-- The list
--------------------------------------------------------------------------

-- The themes on this profile, in the order they were made. The table itself,
-- not a copy: the page edits cells in place and the theme being drawn is this
-- same table, which is what makes an edit show up on the screen as it is made.
function Themes.Own()
	return ns.db.themes
end

-- The index and the record of the theme by that name, or nil. Names are
-- compared without case, because two themes called `Raid` and `raid` are one
-- theme somebody typed twice.
function Themes.Find(name)
	if type(name) ~= "string" then
		return nil
	end
	local wanted = name:lower()
	for index, theme in ipairs(ns.db.themes) do
		if theme.name:lower() == wanted then
			return index, theme
		end
	end
	return nil
end

-- The cell table behind a name, shipped or yours, or nil where no theme goes
-- by it. This is what Theme/Theme.lua dresses the screen from, and it is the
-- one place that knows there are two kinds.
function Themes.Named(name)
	if type(name) ~= "string" then
		return nil
	end
	if Themes.LABEL[name] then
		return Themes[name]
	end
	local _, theme = Themes.Find(name)
	return theme and theme.elements or nil
end

-- How a theme draws the experience rail, or nil where it leaves it to the
-- setting. The one element with a second question after how visible it is: the
-- minimal rail is a different drawing rather than a fainter one, so a theme
-- that only said an alpha could not ask for the hairline along the bottom
-- edge. The shipped three answer it in Themes.RAIL and yours on its record.
function Themes.RailOf(name)
	if Themes.LABEL[name] then
		return Themes.RAIL[name]
	end
	local _, own = Themes.Find(name)
	return own and own.rail or nil
end

-- Every theme's name, the shipped three first and yours in the order you made
-- them. What the dropdown on the page lists and what the slash word accepts.
function Themes.Names()
	local names = {}
	for index, name in ipairs(Themes.ORDER) do
		names[index] = name
	end
	for _, theme in ipairs(ns.db.themes) do
		names[#names + 1] = theme.name
	end
	return names
end

--------------------------------------------------------------------------
-- One cell, and a theme's worth of them
--------------------------------------------------------------------------

-- A cell written from the four answers Themes.Cell gives back, which is how a
-- theme of yours is made out of one that ships: the words come apart into
-- dials and the dials go back together into the same picture.
--
-- `hidden` becomes an alpha of nothing rather than a flag of its own, and
-- Themes.Cell reads it back as hidden, so the round trip holds. There is no
-- third state to keep in step because there is no third field.
local function CellFrom(theme, key)
	local alpha, hover, hidden, combat = Themes.Cell(theme, key)
	return { alpha = hidden and 0 or alpha, hover = hover, combat = combat }
end

-- Every element named, whatever the table arrived holding. A saved variables
-- file is the one input this addon cannot check at the compiler: it carries
-- whatever the last version wrote, whatever another addon's bug wrote over it,
-- and whatever a player edited by hand. So a theme is rebuilt from the element
-- list rather than trusted: every key on the list gets a cell, and a key that
-- is not on the list is dropped.
local function Sane(held)
	local out = {}
	for _, element in ipairs(Themes.ELEMENTS) do
		local cell = type(held) == "table" and held[element.key] or nil
		local alpha = tonumber(type(cell) == "table" and cell.alpha)
		local combat = tonumber(type(cell) == "table" and cell.combat)
		out[element.key] = {
			alpha = Clamp(alpha or 1),
			hover = type(cell) == "table" and cell.hover == true or false,
			combat = combat and Clamp(combat) or nil,
		}
	end
	return out
end

--------------------------------------------------------------------------
-- Making, naming and dropping one
--------------------------------------------------------------------------

-- Why this name cannot be used, or nil when it can. `mine` is the index of the
-- theme being renamed, which is allowed to keep the name it already has.
function Themes.NameTaken(name, mine)
	if type(name) ~= "string" then
		return "a theme needs a name."
	end
	local clean = name:gsub("^%s+", ""):gsub("%s+$", "")
	if clean == "" then
		return "a theme needs a name."
	end
	if #clean > MAX_NAME then
		return ("a theme's name is %d letters at most."):format(MAX_NAME)
	end
	if Themes.LABEL[clean:lower()] or RESERVED[clean:lower()] then
		return ("%s is the addon's own word; call it something else."):format(clean)
	end
	local index = Themes.Find(clean)
	if index and index ~= mine then
		return ("you already have a theme called %s."):format(clean)
	end
	return nil
end

-- Make one, copied from a theme that already exists so that every element is
-- decided from the first moment. `from` is a theme name and informational is
-- the default, which is every element as its part draws it: a blank page to
-- start dimming rather than a screen that has gone dark before you have chosen
-- anything.
--
-- Answers the index, or nil and why not.
function Themes.Make(name, from)
	if #ns.db.themes >= Themes.MAX_OWN then
		return nil, ("%d themes of your own is the limit."):format(Themes.MAX_OWN)
	end
	local why = Themes.NameTaken(name)
	if why then
		return nil, why
	end
	local source = Themes.Named(from) or Themes.informational
	local elements = {}
	for _, element in ipairs(Themes.ELEMENTS) do
		elements[element.key] = CellFrom(source, element.key)
	end
	local list = ns.db.themes
	list[#list + 1] = {
		name = (name:gsub("^%s+", ""):gsub("%s+$", "")),
		elements = elements,
	}
	return #list
end

function Themes.Rename(index, name)
	local theme = ns.db.themes[index]
	if not theme then
		return false, "no such theme."
	end
	local why = Themes.NameTaken(name, index)
	if why then
		return false, why
	end
	local was = theme.name
	theme.name = (name:gsub("^%s+", ""):gsub("%s+$", ""))
	-- The setting holding the chosen theme and the ones holding each theme's
	-- wiggle target all name a theme by its name, so a rename that only wrote
	-- the record would leave whichever of them pointed here pointing at
	-- nothing, and the next login would fall back to informational without
	-- saying why.
	ns.Theme.Renamed(was, theme.name)
	return true
end

-- Drop one. The settings that named it are put back to what they would have
-- been had it never existed, for the reason the rename gives.
function Themes.Drop(index)
	local theme = ns.db.themes[index]
	if not theme then
		return false
	end
	table.remove(ns.db.themes, index)
	ns.Theme.Renamed(theme.name, nil)
	return true
end

--------------------------------------------------------------------------
-- The load
--
-- Called by Theme/Theme.lua at ADDON_LOADED, before it reads which theme to
-- draw, because the answer to that question may be one of these.
--------------------------------------------------------------------------

function Themes.Load()
	local list = ns.db.themes
	if type(list) ~= "table" then
		ns.db.themes = {}
		return
	end
	for index = #list, 1, -1 do
		local theme = list[index]
		if type(theme) ~= "table" or type(theme.name) ~= "string"
			or theme.name:gsub("%s", "") == "" then
			table.remove(list, index)
		else
			theme.elements = Sane(theme.elements)
			if theme.rail ~= nil and not Rail(theme.rail) then
				theme.rail = nil
			end
			if type(theme.wiggle) ~= "string" then
				theme.wiggle = "none"
			end
		end
	end
	-- Two themes that arrived under the same name are one theme as far as
	-- every lookup here is concerned, so the second is the one nothing can
	-- reach and it is given a name that can be.
	local seen = {}
	for _, theme in ipairs(list) do
		local stem, at = theme.name, 1
		while seen[theme.name:lower()] do
			at = at + 1
			theme.name = ("%s %d"):format(stem:sub(1, MAX_NAME - 3), at)
		end
		seen[theme.name:lower()] = true
	end
end
