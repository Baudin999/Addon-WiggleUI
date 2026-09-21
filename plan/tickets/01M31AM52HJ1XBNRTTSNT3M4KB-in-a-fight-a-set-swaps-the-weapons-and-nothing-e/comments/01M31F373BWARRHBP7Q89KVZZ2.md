---
revision: 5
id: 01M31F373BWARRHBP7Q89KVZZ2
---

Landed at 119d0fc9.

Fix. Allowed is a filter over plan.ops rather than a refusal over the whole run, and it runs inside Sets.Plan before Room, Touched and short, which is what the card asked for. Whole gestures are dropped and never single operations: a grab whose drop went would leave a piece on the cursor, and a drop whose grab went is a pickup that would take the piece out of the slot the set was filling. The refusal in Sets.Wear is gone and the line says nothing about what was dropped.

Ruled out. Keeping the refusal for a client with no PickupInventoryItem at all. Worn.Free answers false for that too, so on such a client every operation is dropped and the run reports nothing changed rather than saying why. Both clients this addon runs on have the call; noting it here rather than adding a branch nobody can reach.

Gate. 52-sets.lua plans the same set twice, once out of a fight and once in one: "lift 15, stow, grab, drop 16, stow" asking for one bag slot becomes "grab, drop 16, stow" asking for none, and with the bags shut the weapon swap is not refused for the room the armour wanted. The queue block at the foot presses it for real and reads the two hander on and the cloak still on.
