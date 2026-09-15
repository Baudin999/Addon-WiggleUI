---
revision: 5
id: 01M2JFZRDAXDJT8RD2809SDK6S
type: feature
status: todo
title: "An ammo pill on the player block for bows, guns and thrown that runs out"
---

A hunter, a rogue or a warrior with a bow, gun or crossbow runs out of shots with nothing on screen to say so. The count lives on the paper doll's ammo slot and, if the ranged attack is on a cloned bar, on that square.

A small pill on the player block: the number of shots left, in the bottom corner of the portrait against the gauge, inside the block so it covers neither aura row nor badge.

- Bow, gun, crossbow: GetInventoryItemCount on slot 0, asked by GetInventoryItemID because the ammo slot has no link (Narcissus reads it this way on 2.5.6). Nothing in the slot is a 0, drawn in the low colour.
- Thrown that stacks (vanilla): the stack on slot 18.
- Thrown that does not stack (2.5.6, durability), a wand, a relic, nothing worn: no pill.
- Under 100 the number turns red.
- Shim ns.Ammo in Core/Core.lua beside ns.ItemKind and ns.ItemStack; UnitFrames/Paint.lua draws it.
- Harness section 10-ammo-pill: each weapon kind, the low colour, whole pixels, and no pill on the target.
