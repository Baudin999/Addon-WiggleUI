---
revision: 5
id: 01M2GHRV0P20TPXTHQQ5A5SKZB
type: bug
status: todo
title: A pet has no row in the threat meter
---

Threat.lua samples `Roster.Units()`, and Unit/Roster.lua puts pets into `units` and `owners` but never into `order`, so a pet is never asked for its threat and never gets a row.

Fix. Roster keeps a second array, members and their pets, player first, and the threat meter walks that one. `Units()` stays members only: the party frames, the quest party and the enemy bars all walk it and a pet there would be a party tile.

Gate. 25-meters gives partypet1 threat and checks it is ranked with the pet's name and its owner's class.
