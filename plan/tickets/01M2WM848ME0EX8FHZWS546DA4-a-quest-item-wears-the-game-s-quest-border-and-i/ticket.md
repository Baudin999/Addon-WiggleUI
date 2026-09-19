---
revision: 5
id: 01M2WM848ME0EX8FHZWS546DA4
type: task
status: done
title: A quest item wears the game's quest border and its count to go
parent: 01M2WM7H2QD0KYVCRBZZ25T564
---

Today the ring round the icon means quest (orange), a profession reagent
(green) or trash (quiet), so it reads as none of them. Reason() sets it,
src/Feeds/Loot.lua around line 612; Ringed paints it, src/UI/Feed.lua:1878.

Wanted:

- a quest item draws the border and bang the bags draw on a quest item, taken
  from the client's own textures, not a recolour of ours;
- its progress, e.g. 3/8, in the count column where the stack size goes;
- the ring keeps the reagent answer only; trash draws no ring;
- the quest chip's orange (QUEST, Loot.lua) goes if nothing else reads it.

First step: grep Gethe/wow-ui-source classic_anniversary ContainerFrame for the
quest border and bang texture names and the call that decides a starter. Do
not name a texture from memory.
