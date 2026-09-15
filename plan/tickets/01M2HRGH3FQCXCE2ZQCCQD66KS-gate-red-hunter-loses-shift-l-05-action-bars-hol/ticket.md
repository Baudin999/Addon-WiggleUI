---
revision: 5
id: 01M2HRGH3FQCXCE2ZQCCQD66KS
type: task
status: done
title: "Gate red: HUNTER loses Shift-L, 05-action-bars holds two subjects"
---

f450625 left `./scripts/check.sh` red, which stopped `release.sh --upload --type beta`:

    harness FAIL as HUNTER: Shift-L carries ""
    harness/sections/05-action-bars.lua is 1065 lines, over its own ceiling of 1061

Cause, Shift-L. 05-pet-bar calls WarriorKitRebuildBindings, which models the
client dropping every override and firing UPDATE_BINDINGS. Core/Core.lua takes
the keys back one frame later on a one-shot OnUpdate, and the section never ran
that frame. The dungeon key is registered with ns.Rebind (Dungeons/Key.lua:129),
so the addon is right and the fixture was not. Only HUNTER stands the pet bar
up, so only HUNTER saw it.

Cause, the size. The line count was the symptom. Lines 888 to 1065 of
05-action-bars were the enemy bars on nameplates, a second subject sharing
nothing with the cloned bars but the run order.

Fix. 05-pet-bar rebuilds through a local Rebuild() that runs the frame the
rebuild booked. The plate half moves to 05-enemy-plates, listed straight after
05-action-bars so the order is unchanged, and the ceiling ratchets down to 884.
