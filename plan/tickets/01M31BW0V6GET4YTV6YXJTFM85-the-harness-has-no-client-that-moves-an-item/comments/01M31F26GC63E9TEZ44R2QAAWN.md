---
revision: 5
id: 01M31F26GC63E9TEZ44R2QAAWN
---

Landed at 119d0fc9. Fix. PickupInventoryItem in 13-character.lua is a swap: empty hands lift the worn piece and leave the slot bare, a loaded cursor equips and hands back. ClearCursor in 05-quests.lua puts a cancelled pickup back in the worn slot it came out of; a bag pickup needs nothing put back, because the stub leaves the item in the slot and the cursor holds a reference to it, which is the model PickupContainerItem already had. stow() takes a cursor with no bag behind it and refuses a bag whose family is not nought. 04-hands.lua grows H.wear, because slots 16 and 17 live on the swing table and everything else in `worn`, and one writer has to know about that seam. H.held reads the whole cursor back.

Ruled out. Firing the events where the state changed. H.fire is synchronous, so the queue runs its next operation inside the event with this call still on the stack: ITEM_LOCK_CHANGED fired from the middle of the swap handed the queue a world half moved and it stowed a copy of the piece just equipped. Both events go last now, after the cursor is settled.

Cost. A click on a gear square really moves gear, so 52-character.lua, 52-gear-page.lua and 86-sockets.lua each put the piece back. 86-sockets was the one that failed: it clicks the helmet off to prove the click is not the socket window, then shift clicks the same slot expecting a helmet in it.

Gate. 52-sets.lua has a queue block at its foot, in a bag of its own (bag 3, put up and taken down there) so no other section's count moves.
