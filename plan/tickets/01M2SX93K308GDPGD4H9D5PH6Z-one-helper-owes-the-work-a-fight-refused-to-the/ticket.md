---
revision: 5
id: 01M2SX93K308GDPGD4H9D5PH6Z
type: task
status: done
title: One helper owes the work a fight refused to the end of the fight
---

Twenty files wrote the same three halves by hand: `if InCombatLockdown() then pending = true return false end`, a flag of their own, and a `PLAYER_REGEN_ENABLED` branch in their own handler that reran the work. The copies drifted. Buttons/Bars.lua retried Apply for a refusal in Restyle, Quests/TrackerOff.lua cleared its flag on success and Artwork/Artwork.lua did not, UnitFrames/Auras.lua retried its header grid on the next aura pass rather than when the fight ended, and Core/Core.lua kept a `waiting` flag of its own.

Core/Lockdown.lua: `ns.Lockdown.Held(work)` asks and owes in one call, `ns.Lockdown.Done(work, complete)` owes or settles a pass whose refusal came back from a call (ns.Strip, Block.Place, SetCVar), `ns.Lockdown.Owed(work)` is the status lines' reader. One PLAYER_REGEN_ENABLED listener, loaded right after Core.lua, runs everything owed in the order it was owed.

Gate: check.sh fails on `RegisterEvent("PLAYER_REGEN_ENABLED")` outside Core/Lockdown.lua unless the file is on `regen_allowed` with what it does at the end of a fight, fails on a stale entry, and fails on `InCombatLockdown()` followed within eight lines by a flag set to true.
