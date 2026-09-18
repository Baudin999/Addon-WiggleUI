local ADDON, ns = ...

local Lockdown = {}
ns.Lockdown = Lockdown

--------------------------------------------------------------------------
-- Work combat refused, run once when the fight ends
--
-- In a fight the client refuses every protected write an addon makes: a key
-- bound, a secure button moved, sized, shown or hidden, a protected region
-- stripped. It does not queue the write and it does not say so later. The
-- write is gone, and a part that asked at the wrong moment stays wrong until
-- something happens to ask again.
--
-- So every part that makes such a write answers the refusal the same way:
-- remember that it was refused, and do it again at PLAYER_REGEN_ENABLED, which
-- is the moment the client lets go. Twenty files wrote that by hand, each with
-- a flag of its own and a branch of its own in its own event handler, and the
-- flags drifted: one cleared on success and another did not, one retried a
-- different function from the one that refused, and a new part had to know to
-- write all three halves or it shipped a switch that only answered out of
-- combat.
--
-- This file is the three halves once. Lockdown.Held asks and remembers in one
-- call, Lockdown.Done remembers a refusal a call came back with, and the one
-- listener below runs everything owed, in the order it was owed, when the
-- fight ends. check.sh holds the rest of the tree to it: a file that listens
-- for PLAYER_REGEN_ENABLED is on a list with its reason, and InCombatLockdown()
-- followed by a flag set to true is refused everywhere but here.
--
-- Owed work is keyed by the function, so a function refused ten times in one
-- fight runs once after it. Hand over a function that is kept, never one built
-- on the spot: a fresh closure is a fresh key, and ten of them run ten times.
--------------------------------------------------------------------------

local owed = {}  -- work -> true, for the ones still owed
local order = {} -- the same work, first refused first

-- How a pass at `work` came out. Incomplete owes `work` to the end of the
-- fight, once however often it is said; complete drops a copy still owed,
-- because the pass that was owed has just been done. Answers `complete`, so a
-- pass can end on `return Lockdown.Done(Pass, complete)`.
function Lockdown.Done(work, complete)
	if not complete and not owed[work] then
		order[#order + 1] = work
		owed[work] = true
	elseif complete and owed[work] then
		owed[work] = nil
		for index = 1, #order do
			if order[index] == work then
				table.remove(order, index)
				break
			end
		end
	end
	return complete
end

-- True while combat refuses protected writes, and `work` is then owed. False
-- out of combat, and a copy of `work` still owed is dropped, because whoever
-- asked is about to do it now. So `work` is the function asking, or the one
-- that does all of what it does.
function Lockdown.Held(work)
	return not Lockdown.Done(work, not InCombatLockdown())
end

-- Whether `work` is waiting on the end of a fight.
function Lockdown.Owed(work)
	return owed[work] == true
end

-- Everything owed, run in the order it was owed. The list is taken before any
-- of it runs, so work that is refused again owes itself afresh rather than
-- running twice, and one that throws does not cost the others their turn: its
-- error is raised after the rest have run, where the client reports it.
function Lockdown.Settle()
	if #order == 0 then
		return
	end
	local due = order
	order, owed = {}, {}
	local failed
	for index = 1, #due do
		local ok, why = pcall(due[index])
		if not ok and not failed then
			failed = why
		end
	end
	if failed then
		error(failed, 0)
	end
end

-- Loaded straight after Core.lua, so this is the first listener every part's
-- own PLAYER_REGEN_ENABLED branch runs after, and a part that repaints at the
-- end of a fight repaints what the owed work has just put right.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", Lockdown.Settle)
