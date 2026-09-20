local ADDON, ns = ...

local Hand = {}
ns.Handback = Hand

--------------------------------------------------------------------------
-- The client's own bottom bar, handed back in one press
--
-- Every piece of this already had a switch and that was the bug. Putting the
-- 2007 bar back took five of them, on two pages, under four different labels:
-- `actionBars` off on the Action bars page, `blizzArt` on under it, then
-- `hideBlizzMicroMenu`, `hideBlizzBagBar` and `hideBlizzXP` unticked on the
-- Frames page, which is a page about unit frames. Somebody who wanted the
-- gryphons back found the first switch, got twelve grey buttons standing on
-- nothing with no metal behind them, and stopped looking. That is not five
-- switches working; that is one question nobody can answer.
--
-- So this is a sixth control over the five, and it holds no setting of its own.
-- What it reads and what it writes are the same five booleans the five switches
-- read and write, which is the whole design: ticking it here and unticking the
-- five by hand leave the screen in the same state, and the five rows keep
-- saying exactly what they always said. Core/BlizzHide.lua's header calls a
-- switch whose effect you cannot predict from its label the failure worth
-- rewriting a file over, and a saved `blizzBars` that quietly overrode the
-- others would be precisely that.
--
-- **A part signs in, this file names nobody.** Core is the floor of the tree
-- and scripts/trees.lua refuses a floor that reaches up into a feature, which
-- is right: a list here naming ns.Bars, ns.Artwork and ns.Rails would make
-- every part of the addon depend on those three through the floor with nothing
-- recording it. A part registers `handback` on the table it already hands
-- ns.Register, the same way it registers `switch`, `reset` and `lock`, and this
-- file walks the registry.
--
-- An entry is three fields.
--
--   what   what the player loses and gains, in the words the panel prints.
--          "the bag bar", not "hideBlizzBagBar"
--   ours   true while this part is standing over the client's copy
--   hand   true to give the client's back, false to take ours again. Returns
--          false where combat refused part of the work, which is the contract
--          every Apply in the addon has
--
-- **What is not in here is as decided as what is.** The action slots are not:
-- what is written in slot 37 is the loadout's business and the loadout page has
-- its own two buttons for it, so this control moves frames and never a spell.
-- Neither is the character sheet, the quest log, the map or the bags, which are
-- windows rather than bars and each already has the one switch it needs. The
-- line is the client's bottom bar and its art, because that is one thing a
-- person can point at.
--------------------------------------------------------------------------

local NONE = {}

-- Every part that takes a piece of the client's bottom bar, in feature order.
--
-- Walked on each call rather than cached. It is one pass over forty tables on a
-- panel refresh, it never runs on a tick, and a cache built at login would be
-- filled before the last feature had registered, which is the one failure mode
-- that costs an entry nobody can find again.
local function Parts()
	local out = {}
	for _, feature in ipairs(ns.features) do
		local entries = feature.handback or NONE
		for index = 1, #entries do
			local entry = entries[index]
			assert(type(entry.what) == "string" and type(entry.ours) == "function"
				and type(entry.hand) == "function",
				("%s registered a handback entry without what, ours and hand")
					:format(feature.name))
			out[#out + 1] = entry
		end
	end
	return out
end

Hand.Parts = Parts

-- Whether the client's bottom bar is back, which is every part saying it is not
-- standing over one. Computed rather than saved, so the tick box agrees with
-- the five switches however they were last moved.
function Hand.Given()
	local parts = Parts()
	for index = 1, #parts do
		if parts[index].ours() then
			return false
		end
	end
	return true
end

-- Blizzard's back, or ours again. False where combat refused part of the work.
function Hand.Set(back)
	local parts, complete = Parts(), true
	back = back and true or false
	for index = 1, #parts do
		if parts[index].hand(back) == false then
			complete = false
		end
	end
	return complete
end

function Hand.Describe()
	local parts, mine = Parts(), {}
	for index = 1, #parts do
		if parts[index].ours() then
			mine[#mine + 1] = parts[index].what
		end
	end
	if #mine == 0 then
		return "all of it Blizzard's own"
	end
	if #mine == #parts then
		return "all of it ours"
	end
	return ("ours: %s"):format(table.concat(mine, ", "))
end

-- One line per piece, for the slash word. A summary says how many are ours and
-- this says which, which is the question somebody asks once the summary has
-- told them the two sides disagree.
function Hand.Rows()
	local parts, rows = Parts(), {}
	for index = 1, #parts do
		local entry = parts[index]
		rows[#rows + 1] = ("  %s: %s"):format(entry.what,
			entry.ours() and "ours" or "Blizzard's")
	end
	return rows
end
