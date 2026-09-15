---
revision: 5
id: 01M2JG8RD7K5YNYN57DMJ4FQ70
---

Built in 8f6a448. The pill sits in the player portrait's bottom corner on the gauge side, inside the block, with the shots left. ns.Ammo in Core/Core.lua gives the count: ammo slot 0 by GetInventoryItemID for bow, gun and crossbow (subclasses 2, 3, 18); the slot 18 stack for a thrown weapon whose stack size is over 1; nil for durable thrown, wand, relic or nothing worn. An empty ammo slot shows a red 0, under 100 is red, and the display caps at 9999 because the pill is sized for four digits. BAG_UPDATE and UNIT_INVENTORY_CHANGED mark the block, and the one second read catches anything they miss. Block.Place lost its badge loop to PlaceBadges and its shape ceiling drops 147 to 136. Gate: harness section 10-ammo-pill. Not yet seen in the client: whether BAG_UPDATE fires on every auto shot, and the pill's look over a real portrait.
