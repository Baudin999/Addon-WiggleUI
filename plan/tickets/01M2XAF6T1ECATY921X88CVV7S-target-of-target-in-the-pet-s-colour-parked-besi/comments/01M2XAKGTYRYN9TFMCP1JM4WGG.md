---
revision: 5
id: 01M2XAKGTYRYN9TFMCP1JM4WGG
---

Cause. Color.OfUnit found a pet's owner through a token table (pet, partypetN, raidpetN). targettarget is not in it and is not a player, so the pet fell through to reaction friendly green beside its own class-coloured pet block. Fix. OfUnit also asks UnitIsUnit(unit, "pet"). ToT spec is mirror = true, flank = "target"; Block.Flank already parks on the host's portrait side, so it lands right of the target, tops level, 3 px apart. Block.Perch, Auras.Under and the aura rows' drop past ToT are deleted: nothing sits under the target block any more. Gate. 01-unit-layer asserts the targettarget-is-pet colour; 15-skin-fit asserts the flank anchor and the 3 px at three UI scales; 14-aura-row asserts the debuff row is flush; 10 and 11 read spec.mirror instead of key == target.
