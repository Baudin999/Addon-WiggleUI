---
revision: 5
id: 01M2GG59ZYMZ7AJAM6V6VS3DHB
type: bug
status: todo
title: Clicking the bar over a mob or player does not target it
---

Clicking a bar on a nameplate does nothing. Reported 2026-09-14 on the 2.5.6 client.

Two faults, and either one alone is enough to break it.

1. `barsClickThrough` shipped `true` in 27aa945. `PlateMouse` in
   `src/UnitFrames/EnemyBars.lua` then calls `EnableMouse(false)` on every
   plate's UnitFrame, so no click reaches the button that targets. The live
   account file has it at `true`.
2. `src/UnitFrames/Plates.lua` sized plates only through
   `C_NamePlate.SetNamePlateEnemySize`. Neither 2.5.6 nor 1.15.9 has that
   call. Both document `SetNamePlateSize` (Gethe/wow-ui-source,
   `NamePlateDocumentation.lua`). `ApplySize` returned "settled" without
   writing, so the hit box stayed Blizzard's and only the middle of a bar
   twice that height would have targeted. The harness stub carried the retail
   name, so section 08's size check passed against a call that does not exist.

Blizzard's driver also re-sends its own size on `DISPLAY_SIZE_CHANGED` and on
the nameplate option CVars, which would undo ours after a window resize.
