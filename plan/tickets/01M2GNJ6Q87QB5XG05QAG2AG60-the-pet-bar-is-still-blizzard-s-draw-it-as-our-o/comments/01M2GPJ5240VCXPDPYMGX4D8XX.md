---
revision: 5
id: 01M2GPJ5240VCXPDPYMGX4D8XX
---

Cause. Nothing cloned PetActionBar, so with a pet out Blizzard's bar drew in its own art beside our bars.  Fix. 96afe9a adds src/Buttons/Pet.lua: ten squares under actionBars. Left press is type pet, right press is type2 click on PetActionButtonN (Baganator uses clickbutton the same way), keys stay on BONUSACTIONBUTTON. PetActionBar is caged by Attic.Take only, never ns.Strip. Visibility is a [pet] state driver; placed by UI.Placeable, default BOTTOM 0,184 (petBarPoint). Autocast is a gold corner. Not verified in game yet: that a right click on the caged Blizzard button toggles autocast, and that GetPetActionInfo returns nine values on 2.5.6 as Shared/PetActionBar.lua reads it.  Gate. Harness section 05-pet-bar; check.sh 0/0. HEAD was red from f3b5055, dc3347f and 89566ee, fixed first in 3d82e0e.
