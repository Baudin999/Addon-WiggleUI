---
revision: 5
id: 01M2XAF6T1ECATY921X88CVV7S
type: task
status: done
title: "Target of target in the pet's colour, parked beside the target"
---

Target of target draws your pet in friendly green instead of your class fill, because Color.OfUnit (src/Unit/Color.lua) resolves a pet's owner by token and "targettarget" is not in OWNER. It also sits under the target block, where it pushes the target's debuff row down.

Change: OfUnit resolves any token that is your pet to the player. Target of target is parked beside the target block the way the pet is beside the player, mirrored: target gauge, target square, tot gauge, tot square, top edges on one line, PARK_GAP apart.
