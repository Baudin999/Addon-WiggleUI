---
revision: 5
id: 01M2JF56X5F82QCTTPTNYMEX7T
---

Built. Bags/Belt.lua draws four squares along the foot of the bag window, above the footer: bags 1 to 4, no backpack. A click or a drop with an item in hand calls PutItemInBag on that bag's worn slot. A click with nothing in hand, or a drag, calls PickupBagFromSlot. Each square shows the bag's picture, its grade on the rim and its size in slots, and dims while the bag is on the cursor. The shims ns.BagSlot, ns.PutInBagSlot, ns.PickupBagSlot and ns.InventoryLocked sit in Core/Core.lua beside ns.Stow, and Stow now uses the first two. Window.lua adds the row's height to the fit, and 55-bags and 65-bag-piles add it to their body checks. Gate: harness section 67-bag-belt. Not yet seen in the client: a real bag swap, and whether BAG_UPDATE alone redraws the row when a bag goes on.
