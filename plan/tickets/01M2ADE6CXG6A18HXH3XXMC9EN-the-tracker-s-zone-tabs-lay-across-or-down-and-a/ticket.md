---
revision: 5
id: 01M2ADE6CXG6A18HXH3XXMC9EN
type: task
status: todo
title: "The tracker's zone tabs lay across or down, and across ships"
---

The tracker drew one tab per zone down its left edge, turned a quarter turn.
That is the cheap strip and it is not the legible one: every tab is a word the
reader tilts their head for, on the one frame in the addon that is read a
hundred times a night.

So the strip runs either way and a setting says which. Across is the harmonica:
a row of upright tabs over the quests, each as wide as its own zone name, packed
left to right and folded onto another line when the tracker's width runs out.
Down is the strip that was there. Across ships.

- `src/UI/Window.lua` UI.SideTabs takes `across`, and `Side:Across(on)` moves a
  strip that is already built: the tabs are pooled, so every label is turned
  back and every accent mark moved to the edge the strip is now attached to.
  `Side:Resize(longest, room)` lays down a column or across a folding row.
- `src/Quests/Column.lua` reads the setting, and `Strip()` hands the paint how
  far right the words start, how far down they start and how tall the strip is.
- `src/Quests/Feature.lua` `questsTabs`, "across" or "down", on the Quests page.
- `scripts/harness/sections/85-quest-column.lua` asserts both directions,
  including that the strip and the words never overlap either way round.
