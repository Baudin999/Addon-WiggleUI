local ADDON, ns = ...

local Training = {}
ns.TalentTraining = Training

--------------------------------------------------------------------------
-- Beast training, behind one door
--
-- The anniversary client is 2.5.6 and a pet there has no talent tree. What it
-- has is Beast Training: a spell the hunter casts, which opens the craft
-- window, whose rows are the abilities the pet can be taught and whose price
-- is training points the pet earns by levelling. Blizzard_CraftUI/TBC draws
-- that session in CraftFrame, and this file is every question the talent
-- window's pet page asks of it. The calls themselves are Core's, beside the
-- reagent walk's, because a part may not probe the client for a call.
--
-- **Only while the window is open.** GetCraftInfo answers nothing about beast
-- training until the spell has been cast, and casting is protected, so the
-- list cannot be read at login and cannot be opened from ordinary Lua. The
-- page draws what the pet is and what it has to spend at any time, and the
-- abilities only while the session is up. Pet.lua carries the secure square
-- that casts the spell.
--
-- **The session is named by its title.** Enchanting uses the same window and
-- the same calls, and the difference is that beast training has no skill
-- line. GetCraftName is the spell's own name on both, so the session is beast
-- training when that title is what GetSpellInfo calls spell 5149, which is
-- right in every locale the client ships.
--
-- **Held, for the park.** The page takes the session over from CraftFrame from
-- the moment the client opens it until the moment it closes it, and Blizzard.lua
-- parks that frame for exactly that span. Parked rather than caged, because
-- hiding CraftFrame is what calls CloseCraft.
--------------------------------------------------------------------------

-- Beast Training, the same id on TBC Classic and on Classic Era. Read back off
-- Wowhead's TBC spell page by name rather than typed from memory.
Training.SPELL = 5149

-- Whether the page has the session. Set when the client opens a beast training
-- window with the talent window switched on, cleared when the client closes it.
local held = false

-- The only class this client teaches a pet this way. A warlock's demon learns
-- from a book, which is an item and not this window.
function Training.Offered()
	return ns.Class.Token() == "HUNTER"
end

function Training.Name()
	local name = GetSpellInfo(Training.SPELL)
	return name
end

-- Whether the craft window the client has open is beast training.
function Training.Open()
	local title = ns.CraftTitle()
	return title ~= nil and title == Training.Name()
end

-- The pet as a sentence needs four facts, and none of them is there without a
-- pet out.
function Training.Pet()
	if not UnitExists("pet") then
		return nil
	end
	return UnitName("pet"), UnitCreatureFamily("pet"), tonumber(UnitLevel("pet")) or 0
end

-- Points left to spend, every point earned, and how many of those are spent.
function Training.Points()
	local total, spent = ns.PetTrainingPoints()
	return math.max(0, total - spent), total, spent
end

-- What the pet already knows, off its own spell book: one entry per ability,
-- at the highest rank the book carries, which is the last one it lists.
--
-- The book is the only place this is written down. Beast training's list is
-- what the pet can still be taught and says nothing with the session shut. An
-- entry with no rank line is a command, Attack or Follow or Stay, and is left
-- out: every ability a pet is taught for points has ranks.
function Training.Known(out)
	wipe(out)
	local count = tonumber((HasPetSpells())) or 0
	local byName = {}
	for index = 1, count do
		local kind = GetSpellBookItemInfo(index, "pet")
		local name, rank = GetSpellBookItemName(index, "pet")
		if kind ~= "FUTURESPELL" and name and rank and rank ~= "" then
			local entry = byName[name]
			if not entry then
				entry = { name = name }
				byName[name] = entry
				out[#out + 1] = entry
			end
			entry.rank, entry.icon = rank, GetSpellBookItemTexture(index, "pet")
		end
	end
	return out
end

function Training.Count()
	if not Training.Open() then
		return 0
	end
	return ns.CraftCount()
end

-- One ability: name, rank line, whether the pet knows it already, the cost, the
-- pet level it needs and its icon. Nil for a header or an index the window does
-- not list, so the page walks every index and draws only what answers.
--
-- "used" is the client's word for a row the pet already has. Blizzard_CraftUI
-- greys it and disables the create button on it, which is the same claim.
function Training.Entry(index)
	local name, rank, kind, cost, level = ns.CraftEntry(index)
	if not name or kind == "header" then
		return nil
	end
	return name, rank or "", kind == "used", cost, level, ns.CraftIcon(index)
end

-- Picks a row and hands back the button that teaches it, or nil where there is
-- no session or no button. The teaching itself is a secure click on that
-- button: Pet.lua lays one over the row.
function Training.Select(index)
	if not Training.Open() or not ns.CraftSelect(index) then
		return nil
	end
	return ns.CraftCreateButton()
end

-- Ends the session if it is the page's. Enchanting is left alone: a hunter who
-- is also an enchanter closing the talent window has not closed that.
function Training.Close()
	if not held or not Training.Open() then
		return false
	end
	return ns.CraftClose()
end

--------------------------------------------------------------------------
-- The session
--------------------------------------------------------------------------

-- The client opened a craft window. Answers whether the page took it.
function Training.Opened()
	held = ns.db.talents and Training.Offered() and Training.Open() or false
	return held
end

function Training.Closed()
	local was = held
	held = false
	return was
end

-- Asked by the park in Blizzard.lua, under the name every parked window answers
-- to: whether there is a window of this addon's up over the session.
function Training.Shown()
	return held
end

function Training.Describe()
	if not Training.Offered() then
		return "no pet to train on this class"
	end
	local left, _, spent = Training.Points()
	if held then
		return ("Beast Training open, %d training points spent and %d left"):format(spent, left)
	end
	return ("%d training points spent and %d left"):format(spent, left)
end
