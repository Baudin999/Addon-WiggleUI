---
revision: 5
id: 01M2JEY27XNYWRAG2FXH7XZV9D
type: feature
status: todo
title: A bag row at the foot of the bag window to put bags on and swap them
assignee: ck
---

The bag window has no way to put a bag on or take one off. Blizzard's bag bar is hidden (hideBlizzBagBar) and the nine bag calls open this window, so a new bag cannot be equipped and an old one cannot be swapped.

A row along the bottom of the bag window, above the footer: four squares for bags 1 to 4. The backpack is fixed and gets no square.

- Drop or click an item onto a square: PutItemInBag(ContainerIDToInventoryID(bag)). A bag equips or swaps; anything else goes into that bag.
- Click with nothing held, or drag: PickupBagFromSlot. The bag lands in the grid only while it is empty, which the client enforces.
- Both calls are the ones Baganator makes on this client (ItemViewCommon/ContainerSlots.lua).
- Shims in Core/Core.lua beside ns.Stow, so Bags/ does not probe the client.
- Harness section 67-bag-belt: the aim of each square, a press with an item in hand, a press and a drag with nothing in hand.
