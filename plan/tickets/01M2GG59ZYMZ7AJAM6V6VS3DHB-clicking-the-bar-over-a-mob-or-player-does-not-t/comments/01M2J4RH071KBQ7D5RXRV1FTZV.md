---
revision: 5
id: 01M2J4RH071KBQ7D5RXRV1FTZV
---

Fourth pass, 0708380. A taint fault in e654e3d, not a new cause for the click.

Cause. Plates.Aim and the UpdateNamePlateOptions hook read Blizzard's points with GetHitTestPoints so Unaim could hand them back. The read is a measurement and a plate is a restricted region. In game the first plate of a pull raised 'NamePlate1:GetHitTestPoints(): Can't measure restricted regions', Lua Taint: WarriorKit, from Plates.lua:247 through EnemyBars AimPlate.

Fix. Nothing reads the plate. Unaim rebuilds Blizzard's anchors from NamePlateSetupOptions (healthBarHeight, unitNameAnchorStyle), the table Blizzard_NamePlateUnitFrame.lua ApplyFrameOptions reads: the bar ten out and half its height when the name is inside it, else the name's top left fourteen out down to the bar's bottom right. The prior table is gone.

Gate. The harness plate's GetHitTestPoints goes through H.refused, the same refusal GetPoint uses, so addon code gets the client's message and harness checks still read it. With the read put back, the run to 08-bars-zoom fails at Plates.lua:250. Not yet confirmed in game.
