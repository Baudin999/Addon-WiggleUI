---
revision: 5
id: 01M2SN1RS32Z1J6FVVYPJNJHSQ
type: task
status: done
title: "Cooldowns is one page, with which cooldowns on it"
---

Cooldowns was two sections under Fighting: Cooldowns with the switch, readings, idle check, zoom and reset, and Which cooldowns with the row editor, the add-by-id field and the class reset. Picking what is on the row and shaping the row are one job.

Fold Which cooldowns into Cooldowns in src/Cooldowns/Feature.lua, under a divider. One lede for the page that says both what the row is and how to drag onto it, inside the 160 cap. scripts/harness/sections/42-cooldown-row.lua:380 finds the editor by the old title and moves to the new one.

Trinkets stays its own section.
