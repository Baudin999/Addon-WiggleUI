-- Somebody else to inspect
--
-- 13-character.lua dresses the player and 04-hands.lua answers the inventory
-- calls for "player" and nil for everybody else, which is exactly right while
-- the only sheet the addon draws is your own. The inspect sheet is the same
-- page drawn for a unit that is not you, so this file puts a second character
-- on the other end of those calls.
--
-- **One unit and it is "target".** That is the token the slash word and the
-- client's own menu entry both reach for, and it is the one token the whole
-- stub already has a name, a class, a level and a GUID for. A second inspected
-- unit would prove nothing the first does not.
--
-- **He is deliberately not a copy of the player.** Four things about him are
-- chosen so that every branch of the page has something to read:
--
--   one enchanted piece and one bare one, so both arms of the enchant tally
--   and both wordings of its badge hover are reachable. A stub where every
--   piece was enchanted would let a counter that returned its own total pass.
--
--   one piece with a hole in it and nothing in the hole, so the gem tally is
--   not nought of nought, which is the answer a reader that found no sockets
--   at all would also give.
--
--   a two hander, so the off hand that the page does not count as empty is
--   exercised on somebody other than the player.
--
--   a guild, because the line under his name carries one and the branch that
--   leaves it off is the player's own sheet.
--
-- **The inspect is a conversation and it is modelled as one.** NotifyInspect
-- writes down who was asked, nothing is answered until a section fires
-- INSPECT_READY, and the talent calls answer the inspect trees 06-log.lua
-- already carries. That is what lets the section assert the two states the
-- window has a sentence for: asked and not answered, and answered.
--
-- What this cannot prove is that the game agrees. Every call answers what this
-- file says, and a wrong field is a test that passes and a window that draws
-- the wrong number.

local H = ...
local ITEMS, itemLink, state = H.ITEMS, H.itemLink, H.state
local guids, unitName, unitClass = H.guids, H.unitName, H.unitClass

--------------------------------------------------------------------------
-- The character on the other end
--------------------------------------------------------------------------

-- Four pieces on a paladin. The helmet has a hole and no gem in it, the cloak
-- carries an enchant and the other two do not.
--
-- `rating` is the item level, which is what the fourth return of GetItemInfo
-- is and what the page averages. Four different numbers, none of them the
-- player's sixty, so a badge reading the wrong unit's gear comes out at a
-- number no assertion expects rather than at the right one by luck. They add up
-- to 464, which is 116 over four pieces: a whole number, so the section is
-- asserting an average rather than a rounding rule.
ITEMS["Lightbringer Faceguard"] = { id = 4101, classId = 4, equip = "INVTYPE_HEAD",
	icon = "Interface\\Icons\\PallyHelm", quality = 4, price = 16000,
	rating = 115, gems = {}, open = 1 }
ITEMS["Cloak of the Righteous"] = { id = 4102, classId = 4, equip = "INVTYPE_CLOAK",
	icon = "Interface\\Icons\\PallyCloak", quality = 3, price = 9000, rating = 105 }
ITEMS["Breastplate of the Dawn"] = { id = 4103, classId = 4, equip = "INVTYPE_CHEST",
	icon = "Interface\\Icons\\PallyChest", quality = 4, price = 18000, rating = 120 }
ITEMS["Grand Marshal's Sunderer"] = { id = 4104, classId = 2,
	equip = "INVTYPE_2HWEAPON", icon = "Interface\\Icons\\PallyAxe",
	quality = 4, price = 40000, rating = 124 }

-- Slot to link, for the one unit that is not the player. Five entries and one
-- of them is nil on purpose: slot 17 is the off hand, and the two hander in
-- slot 16 is what makes it a slot nobody may fill rather than an empty one.
-- The cloak carries an enchant id in its link and the other three do not, which
-- is the half Character/Worn.lua reads before it will scan anything: a piece
-- with a zero there is a bare piece and costs no tooltip. What the enchant is
-- called is the section's to seed, the way 52-gear-enchant.lua seeds the
-- player's, because the name only exists in a tooltip.
local theirs = {
	[1] = itemLink("Lightbringer Faceguard"),
	[15] = itemLink("Cloak of the Righteous", 2613),
	[5] = itemLink("Breastplate of the Dawn"),
	[16] = itemLink("Grand Marshal's Sunderer"),
}
H.theirs = theirs

-- Who has been asked about and whether the server has answered. `asked` is the
-- unit token NotifyInspect was handed, which a section reads back to prove the
-- request went to the right person; `answered` is what the inventory and
-- talent calls gate on, so a page painted before the answer draws the empty
-- state the window has a sentence for.
local inspect = { asked = nil, answered = false }
H.inspect = inspect

--------------------------------------------------------------------------
-- The client
--------------------------------------------------------------------------

-- The target is a real player with a name, a class, a race and a guild. Written
-- into the tables 02-text.lua keeps rather than by replacing its stubs, for the
-- reason its own comment gives: every module localises these globals as it
-- loads, so a file that swapped one afterwards would swap nothing.
guids.target = guids.target or "Player-4-00000042"
unitName.target = "Lightsworn"
unitClass.target = "Paladin"

-- UnitIsPlayer is table driven in 03-player.lua and the table is a file local,
-- so the one way to add anybody to it from here is to wrap the call.
--
-- Two units answer true and the second is the player, which is a repair to the
-- fixture rather than a convenience. client/09-group.lua writes the player into
-- that table when a section sets a group and wipes it again when that section
-- takes the group down, so by the foot of the suite the stub has a player who
-- is not a player. The real client never does, and the inspect sheet's refusal
-- for "that is you" is the first thing in the addon to ask.
local wasPlayer = _G.UnitIsPlayer
_G.UnitIsPlayer = function(unit)
	if unit == "target" or unit == "player" then
		return true
	end
	return wasPlayer(unit)
end

-- The race, which 03-player.lua answers for the player alone. Same shape: a
-- localised name first and a token second, spelled differently so a reader that
-- takes the wrong return finds nothing.
local wasRace = _G.UnitRace
_G.UnitRace = function(unit)
	if unit == "target" then
		return "Human", "HUMAN"
	end
	return wasRace(unit)
end

_G.GetGuildInfo = function(unit)
	if unit == "target" then
		return "The Silver Hand", "Champion", 1
	end
	return nil
end

-- Whether the server will discuss this unit. Two arguments, the way FrameXML
-- calls it, and the second is ignored here the way the client ignores it for
-- anybody in range.
_G.CanInspect = function(unit)
	return unit == "target"
end

_G.NotifyInspect = function(unit)
	inspect.asked = unit
	state.inspecting = unit
end

local wasClear = _G.ClearInspectPlayer
_G.ClearInspectPlayer = function()
	inspect.asked = nil
	inspect.answered = false
	if wasClear then
		wasClear()
	end
end

-- The four inventory calls, for the one unit that is not the player.
--
-- Each wraps what 04-hands.lua and 13-character.lua left rather than replacing
-- it, so every section above this one reads exactly the client it read before.
-- All four answer nothing until the inspect has been answered, which is the
-- state the server actually leaves you in between the request and the reply.
local function Sent(unit)
	return unit == "target" and inspect.answered
end

local wasLink = _G.GetInventoryItemLink
_G.GetInventoryItemLink = function(unit, slot)
	if Sent(unit) then
		return theirs[slot]
	end
	return wasLink(unit, slot)
end

local wasTexture = _G.GetInventoryItemTexture
_G.GetInventoryItemTexture = function(unit, slot)
	if Sent(unit) then
		return theirs[slot] and ("their" .. slot) or nil
	end
	return wasTexture(unit, slot)
end

local wasCount = _G.GetInventoryItemCount
_G.GetInventoryItemCount = function(unit, slot)
	if Sent(unit) then
		return theirs[slot] and 1 or 0
	end
	return wasCount(unit, slot)
end

local wasId = _G.GetInventoryItemID
_G.GetInventoryItemID = function(unit, slot)
	if Sent(unit) then
		local link = theirs[slot]
		local name = link and link:match("%[(.-)%]")
		local item = name and ITEMS[name]
		return item and item.id or nil
	end
	return wasId(unit, slot)
end

-- Shift over a piece to link it. Counted rather than performed: what the page
-- is answerable for is that a click on an inspect square reaches this call with
-- the right link, and a stub that pushed text into a chat frame would be
-- modelling the client's edit box.
local wasHandle = _G.HandleModifiedItemClick
local linked = {}
H.linked = linked
_G.HandleModifiedItemClick = function(link)
	linked[#linked + 1] = link
	if wasHandle then
		return wasHandle(link)
	end
	return false
end
