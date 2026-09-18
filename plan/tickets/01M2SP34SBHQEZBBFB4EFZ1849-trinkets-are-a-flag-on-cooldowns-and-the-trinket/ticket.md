---
revision: 5
id: 01M2SP34SBHQEZBBFB4EFZ1849
type: task
status: done
title: "Trinkets are a flag on Cooldowns, and the Trinkets page goes"
---

The Trinkets page under Fighting changes nothing: two readings of what is in each slot. Where a trinket sits on the row was only settable by dragging each one.

Two tick boxes on Cooldowns, mutually exclusive: "trinkets in major cooldowns" puts both on the docked line with Recklessness and Death Wish, "trinkets in minor cooldowns" puts both on the rotation line. Both off takes them off the row. They write cooldownLine and cooldownWatch for trinket1 and trinket2, so no new setting. A trinket dragged on its own leaves neither box ticked until one is picked.

The line names on the page and in the code stay as they are.

Delete the Trinkets section and Cooldowns.Worn, which only it read; the square's own hover already says which slot and whether it is ready. Drop the two Worn checks in scripts/harness/sections/42-cooldown-row.lua and assert the flag instead.
