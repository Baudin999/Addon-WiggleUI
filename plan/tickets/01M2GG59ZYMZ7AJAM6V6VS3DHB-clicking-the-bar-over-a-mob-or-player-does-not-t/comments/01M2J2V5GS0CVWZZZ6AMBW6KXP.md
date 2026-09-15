---
revision: 5
id: 01M2J2V5GS0CVWZZZ6AMBW6KXP
---

Third attempt, e654e3d. Both earlier fixes were real faults and neither was the one in the way.

Cause. The client lands a plate click on the plate's hit test points, not its size and not its mouse. Blizzard_NamePlateUnitFrame.lua ApplyFrameOptions sets them on every SetUnit, anchored to UnitFrame.healthBar and UnitFrame.name. barsStyle replace hides both through ns.Strip, so every click went to hidden regions. Source: Gethe/wow-ui-source classic_anniversary, same on classic_era.

Fix. Plates.Aim(plate, top, bottom) calls SetHitTestPoints on our bar: widget.box in replace, box top to Blizzard's healthBar bottom in attach. FrameAPINamePlateDocumentation.lua allows addon writes in combat on the tick a unit is first assigned. Attach runs on NAME_PLATE_UNIT_ADDED after the driver acquired the UnitFrame (StripPlate already depends on that order), so it is that tick. Post hook on NamePlateDriverFrame.UpdateNamePlateOptions re-aims after the driver rewrites every plate; refused writes are owed and paid in Plates.Flush. Unhost calls Plates.Unaim, which restores Blizzard's saved points and never defers a restore, because a deferred restore could land on a plate handed to another unit. The hitbox outline draws the same corners.

Gate. The harness plate carries hit test points set on name and healthBar at SetUnit, and refuses writes while plate.refusing. Section 08 checks aim on arrival, after an options pass, after a refused pass plus Flush, and Unaim restore. Removing the Aim call fails it six times. Not yet confirmed in game.
