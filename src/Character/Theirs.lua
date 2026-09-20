local ADDON, ns = ...

local Theirs = {}
ns.Theirs = Theirs

local UI = ns.UI
local C = UI.Color

--------------------------------------------------------------------------
-- What the sheet can honestly say about somebody else
--
-- Character/Stats.lua is this file's opposite number and the two do not
-- overlap, because almost nothing they read is the same call. Stats asks
-- UnitStat, UnitArmor, UnitAttackPower, UnitDamage and GetCombatRating, and
-- every one of those answers for the player and nil for everybody else on this
-- client. Blizzard's own inspect frame shows no numbers at all for that reason:
-- three tabs, gear, talents and honour, and not one attribute among them.
--
-- **So this file is written from the other end: what does the server actually
-- send, and what is worth saying about it.** An inspect hands over their gear
-- as twenty links and their three talent trees. Everything below is derived
-- from those two things and nothing is guessed.
--
-- **The four badges are the argument for the whole part.** Your own sheet's
-- four are item level, durability, empty slots and your miss chance. Item level
-- and empty slots carry over unchanged, because both are arithmetic on the
-- links. The other two cannot, and rather than draw "none" twice this draws the
-- two things that matter most about a character in this expansion and that no
-- window in the game will tell you at a glance: how many of their slots carry
-- an enchant, and how many of their sockets have a gem in them. That is the
-- whole of a raid gear check, and it is currently done by opening a tooltip
-- twenty times.
--
-- **An enchant is counted on eleven slots and the two rings are not among
-- them.** A ring enchant in this expansion is open to enchanters and to nobody
-- else, so counting the rings would read every other class as two short
-- forever. Character/Worn.lua marks which eleven, beside the column the slot is
-- drawn in, because which slots take an enchant is a fact about the slots.
--
-- **A socket count is what the piece says, not what it should have.** The link
-- carries how many holes are in it and ns.ItemSockets reads both halves, so a
-- character wearing nothing socketed reads nought of nought rather than reading
-- as under-gemmed.
--
-- **The talents are read through Talents/Read.lua and not out of the client
-- here.** That file is the one door to the talent API in this addon and its own
-- header says at length why: three shapes of the same answer across the two
-- clients, and the points in a tree at a different position in each. A second
-- reader here would be a second guess at which value is the points.
--
-- What is not here, said once rather than left to be asked for. There is no
-- resistance row, because UnitResistance answers for the player and the older
-- inspect frame that drew resistances read them off a packet this expansion
-- stopped sending. There is no honour tab, because this addon does not draw
-- yours either. And there is no durability, because the client's call for it
-- takes a slot and no unit at all.
--------------------------------------------------------------------------

-- The four words under the four discs, in the order they are drawn. Item level
-- and empty keep their place from your own sheet, so the badge you read first
-- and the badge you read last mean the same thing on both pages.
local LABELS = { "item level", "enchants", "gems", "empty" }

function Theirs.Labels()
	return LABELS
end

--------------------------------------------------------------------------
-- The two tallies
--------------------------------------------------------------------------

-- How many of the slots that take an enchant have one on them, and how many
-- could. Only slots with a piece in them are counted on either side: a
-- character with nothing on his back is missing a cloak rather than a cloak
-- enchant, and the empty badge is what says so.
local function Enchants(unit)
	local slots = ns.Worn.Slots()
	local on, of = 0, 0
	local bare
	for index = 1, #slots do
		local entry = slots[index]
		if entry.craft then
			local link = ns.Worn.Link(entry.slot, unit)
			if link then
				of = of + 1
				if ns.Worn.Enchant(link) then
					on = on + 1
				else
					bare = bare or entry
				end
			end
		end
	end
	return on, of, bare
end

-- How many holes across everything they are wearing, and how many have a gem
-- in. Every slot, not the eleven above: a socket is a property of the piece
-- and a two hander carries three of them.
local function Gems(unit)
	local slots = ns.Worn.Slots()
	local on, of = 0, 0
	local bare
	for index = 1, #slots do
		local entry = slots[index]
		local link = ns.Worn.Link(entry.slot, unit)
		if link then
			local filled, open = ns.ItemSockets(link)
			local count = (filled and #filled or 0)
			on, of = on + count, of + count + (open or 0)
			if (open or 0) > 0 then
				bare = bare or entry
			end
		end
	end
	return on, of, bare
end

-- Green when everything is on, red when something is not. One rule for both
-- tallies, because they are the same question asked of two kinds of hole and a
-- reader glancing at the pair wants one rule rather than two.
local function Tone(on, of)
	if of == 0 or on >= of then
		return C.tick
	end
	return C.loss
end

--------------------------------------------------------------------------
-- The head of the column
--------------------------------------------------------------------------

-- The line under their name: what they are, and who they run with.
--
-- The guild is on the line because it is the one thing about somebody an
-- inspect is as often opened for as their gear, and because the client answers
-- it for any player without an inspect at all.
function Theirs.Line(unit)
	if not unit or not UnitExists(unit) then
		return "nobody is being inspected"
	end
	-- Minus one is the client's word for somebody too far above you to read,
	-- and it prints as two question marks the way it does on a unit frame.
	local level = UnitLevel(unit) or 0
	local what = UnitRace(unit) and ("%s %s"):format(UnitRace(unit), UnitClass(unit) or "")
		or UnitClass(unit) or "adventurer"
	local line = ("level %s %s"):format(level > 0 and level or "??", what)
	local guild = type(GetGuildInfo) == "function" and GetGuildInfo(unit) or nil
	if guild then
		return ("%s, %s"):format(line, guild)
	end
	return line
end

function Theirs.Readings(unit)
	local level, empty = ns.Worn.Level(unit)
	local enchanted, enchantable, bareSlot = Enchants(unit)
	local gems, sockets, bareSocket = Gems(unit)
	local read = {}

	read[1] = {
		value = level and ("%.1f"):format(level) or "none",
		note = "Averaged over what they are wearing. Shirt, tabard and ammo are left out, because none of the three carries a level worth counting.",
	}

	read[2] = {
		value = ("%d/%d"):format(enchanted, enchantable),
		tone = Tone(enchanted, enchantable),
		note = bareSlot
			and ("Their %s has nothing on it. Rings are not counted: a ring enchant is an enchanter's own and nobody else may have one.")
				:format(bareSlot.label)
			or "Every slot that takes an enchant has one. Rings are not counted: a ring enchant is an enchanter's own and nobody else may have one.",
	}

	read[3] = {
		value = ("%d/%d"):format(gems, sockets),
		tone = Tone(gems, sockets),
		note = bareSocket
			and ("Their %s has an empty socket in it."):format(bareSocket.label)
			or (sockets > 0 and "Every socket they are wearing has a gem in it."
				or "Nothing they are wearing has a socket in it."),
	}

	read[4] = {
		value = ("%d"):format(empty or 0),
		note = "Shirt, tabard and ammo are not counted, and neither is an off hand their two hander already fills.",
	}

	return read
end

--------------------------------------------------------------------------
-- The gear tab
--------------------------------------------------------------------------

-- The colour an item's name is printed in, which is the one the client gives
-- its quality. Written as the escape rather than set on the font string,
-- because these rows are a list handed to Character/Readout.lua and a row
-- carries a string rather than a colour.
local function Named(link, fallback)
	local name = link and (ns.ItemInfo(link)) or nil
	if not name then
		return fallback
	end
	local quality = ns.ItemValue(link)
	local tone = quality and UI.Quality[quality]
	if not tone then
		return name
	end
	return ("|cff%02x%02x%02x%s|r"):format(
		math.floor(tone[1] * 255), math.floor(tone[2] * 255), math.floor(tone[3] * 255),
		name)
end

-- What is on one piece, as the value beside its slot. The enchant's name where
-- there is one, the word for what is missing where there is not.
local function Onto(link, craft)
	local enchant = link and ns.Worn.Enchant(link)
	if enchant then
		return enchant
	end
	return craft and "nothing on it" or "-"
end

-- Every slot that takes an enchant, in the page's own order, with what is on
-- it. The bare ones are the point of the list, so the note under a bare row
-- says the slot is worth an enchant rather than the row being silent.
local function Enchanting(unit)
	local slots = ns.Worn.Slots()
	local rows = {}
	for index = 1, #slots do
		local entry = slots[index]
		if entry.craft then
			local link = ns.Worn.Link(entry.slot, unit)
			if link then
				rows[#rows + 1] = {
					label = entry.label,
					value = Onto(link, true),
					note = Named(link, entry.label),
				}
			end
		end
	end
	return rows
end

-- Every piece with a hole in it and what is in each hole. A piece with no
-- sockets is not a row: the list is what to look at, and twenty rows saying
-- "no sockets" is a list you stop reading.
local function Socketing(unit)
	local slots = ns.Worn.Slots()
	local rows = {}
	for index = 1, #slots do
		local entry = slots[index]
		local link = ns.Worn.Link(entry.slot, unit)
		if link then
			-- Both returns, and the call is not folded behind an `and`: that
			-- truncates to one value, so the empty half would always read nought
			-- and every piece would look fully gemmed.
			local filled, open = ns.ItemSockets(link)
			local count = filled and #filled or 0
			local holes = count + (open or 0)
			if holes > 0 then
				rows[#rows + 1] = {
					label = entry.label,
					value = ("%d of %d"):format(count, holes),
					fraction = count / holes,
					note = Named(link, entry.label),
				}
			end
		end
	end
	return rows
end

-- Their gear, as the two questions the twenty squares cannot answer at a
-- glance. The squares already say what every piece is; what a column can add is
-- the pass over all of them at once.
function Theirs.Gear(unit)
	if not unit or not UnitExists(unit) then
		return {}
	end
	local groups = {}
	local enchants = Enchanting(unit)
	if #enchants > 0 then
		groups[#groups + 1] = { title = "What is enchanted", rows = enchants }
	end
	local sockets = Socketing(unit)
	if #sockets > 0 then
		groups[#groups + 1] = { title = "What is socketed", rows = sockets }
	end
	if #groups == 0 then
		groups[1] = { title = "What is enchanted", rows = { {
			label = "nothing yet",
			value = "-",
			note = "The server has not sent their gear. Stand closer and open this again.",
		} } }
	end
	return groups
end

--------------------------------------------------------------------------
-- The talents tab
--------------------------------------------------------------------------

-- Three trees and the points in each, read with the inspect flag set.
--
-- The flag is the whole of the difference from your own window: the client
-- keeps one set of talent tables and answers them about whoever was last
-- inspected when it is asked to. That is why Character/Inspect.lua does not
-- hand the inspect back the moment the answer arrives, the way Unit/Spec.lua
-- does: the meter's icon reads its three numbers and is done, and this page is
-- read for as long as the window is open.
function Theirs.Talents(unit)
	if not unit or not UnitExists(unit) then
		return {}
	end
	local rows = {}
	local best, bestPoints, total = nil, 0, 0
	for tab = 1, ns.TalentRead.Tabs(true) do
		local name, _, points = ns.TalentRead.Tree(tab, 1, true)
		if name then
			points = points or 0
			total = total + points
			if points > bestPoints then
				best, bestPoints = name, points
			end
			rows[#rows + 1] = { label = name, value = ("%d"):format(points) }
		end
	end

	if #rows == 0 or total == 0 then
		return { { title = "Talents", rows = { {
			label = "nothing yet",
			value = "-",
			note = "Either they have spent no points, or the server has not sent their trees. Stand closer and open this again.",
		} } } }
	end

	-- The share is on the row rather than in a sentence under it, because three
	-- bars against each other is the shape of a spec and three percentages is
	-- arithmetic the reader has to do.
	for index = 1, #rows do
		rows[index].fraction = tonumber(rows[index].value) / total
	end

	table.insert(rows, 1, {
		label = "spec",
		value = best or "none",
		note = ("%d points spent."):format(total),
	})
	return { { title = "Talents", rows = rows } }
end

--------------------------------------------------------------------------

function Theirs.Describe(unit)
	if not unit or not UnitExists(unit) then
		return "nobody"
	end
	local level = ns.Worn.Level(unit)
	local enchanted, enchantable = Enchants(unit)
	local gems, sockets = Gems(unit)
	if not level then
		return ("%s, and the server has sent none of their gear yet")
			:format(UnitName(unit) or "somebody")
	end
	return ("%s, item level %.1f, %d of %d enchants, %d of %d gems")
		:format(UnitName(unit) or "somebody", level, enchanted, enchantable, gems, sockets)
end
