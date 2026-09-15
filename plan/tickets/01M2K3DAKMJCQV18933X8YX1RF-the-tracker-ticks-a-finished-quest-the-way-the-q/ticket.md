---
revision: 5
id: 01M2K3DAKMJCQV18933X8YX1RF
type: task
status: done
title: The tracker ticks a finished quest the way the quest log does
---

The quest log window marks a quest ready to hand in with the tick in its left column (src/Quests/Window.lua Mark, TICK). The tracker (src/Quests/Column.lua Quest) draws only the name in C.tick, so a finished quest reads as done only by colour.

Fix: TICK moves to src/Quests/Log.lua beside Label and Tint, which both drawings already read. The tracker's title row gets a glyph column that carries the same tick in C.tick.

Gate: scripts/harness/sections/85-quest-column.lua checks a finished quest's title row wears Log.TICK and an unfinished one draws nothing.
