---
revision: 5
id: 01M2J03VBVEKB80XYKW52VT5RN
type: task
status: todo
title: "A hunter cannot train the pet: Beast Training has no page on N"
---

The anniversary client is 2.5.6 and has no pet talent trees. A hunter's pet
learns through Beast Training, spell 5149, which opens a craft session and
Blizzard_CraftUI/TBC draws it in CraftFrame with training points.

The talent window takes N and shows three trees and nothing for the pet.

Fix. A Pet tab on the talent window for a hunter. The page reads the craft
session through Core shims (GetCraftName, GetCraftInfo's cost and level,
GetCraftIcon, DoCraft, CloseCraft, GetPetTrainingPoints). Casting Beast
Training takes a secure square, parented to UIParent and hidden in a fight by
a state driver, so the talent window stays insecure and still opens in
combat. CraftFrame is parked by BlizzAdapter.Park while the page holds the
session, because hiding it calls CloseCraft.

Gate. A harness section drives the session, the rims, a press reaching
DoCraft, the park and the secure square's attributes.
