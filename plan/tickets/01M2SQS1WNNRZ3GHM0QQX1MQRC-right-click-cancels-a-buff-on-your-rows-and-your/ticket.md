---
revision: 5
id: 01M2SQS1WNNRZ3GHM0QQX1MQRC
type: task
status: doing
title: Right click cancels a buff on your rows and your pet's
---

Right click on a buff square in your own or your pet's buff row cancels it, the way the client's BuffButton does. Out of combat only, because CancelUnitBuff is protected in combat.

src/UnitFrames/Auras.lua Hover: OnMouseUp on HELPFUL rows for player and pet. Weapon enchants go through CancelItemTempEnchantment.
