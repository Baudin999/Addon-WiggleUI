---
revision: 5
id: 01M2GG710VQRPPSKE6WYJ4GKTM
---

Cause. barsClickThrough shipped true and took the mouse off every plate's UnitFrame. Under it, Plates.lua only ever looked for SetNamePlateEnemySize, which 2.5.6 and 1.15.9 do not have, so the hit box was never sized to the bar.

Fix. The setting is barsMouseThrough, default false, and barsClickThrough is in RETIRED so the shipped true is wiped from saved files. barsCamera stays right, so a right drag still turns the camera over a bar. Plates.lua resolves SetNamePlateSize first and post-hooks NamePlateDriverFrame.UpdateNamePlateSize to put our size back after the driver sends its own.

Gate. The harness stub is SetNamePlateSize now. Section 08 checks the default, that nameplate1's UnitFrame keeps the mouse, and that the size survives a driver reset.
