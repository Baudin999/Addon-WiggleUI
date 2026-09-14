---
revision: 5
id: 01M2GJFFWMRPSZZ4QGKZ5HVVAP
type: bug
status: todo
title: The pet block draws no buffs or debuffs
---

The pet block from 09a4704 draws no auras. Mend Pet on the pet is not on the screen anywhere, because PetFrame is hidden whole and src/UnitFrames/Auras.lua ROWS has player and target only.

Add a pet pair to ROWS: debuffs under the pet block, buffs over it, from its gauge end. No client buttons to sweep, since PetFrame's are children of a frame already down.
