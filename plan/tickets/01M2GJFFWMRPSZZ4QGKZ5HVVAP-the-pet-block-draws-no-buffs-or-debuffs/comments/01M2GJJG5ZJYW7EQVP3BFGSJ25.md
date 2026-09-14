---
revision: 5
id: 01M2GJJG5ZJYW7EQVP3BFGSJ25
---

Cause. src/UnitFrames/Auras.lua ROWS had player and target only, and PetFrame, which drew the pet's debuffs, is hidden whole.  Fix. a12f884 adds a pet pair: debuffs under the pet block, buffs over it, from its right edge, as wide as the pet block. head and hides are optional on a row, since the pet has no client buttons to sweep.  Gate. pre-commit check.sh passed; harness section 14 asserts the anchors, the width, Mend Pet drawn as yours and the squares clearing.
