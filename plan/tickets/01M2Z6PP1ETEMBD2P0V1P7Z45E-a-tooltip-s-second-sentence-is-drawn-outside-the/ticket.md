---
revision: 5
id: 01M2Z6PP1ETEMBD2P0V1P7Z45E
type: bug
status: done
title: A tooltip's second sentence is drawn outside the box
---

Hovering the empty square in the middle of the ad-hoc ring drew its second
sentence starting well left of the tooltip, white text straight over the world,
with the first sentence missing entirely. Screenshot on the card.

**Cause.** `UI/Tip.lua:Pour` reads a list whose first entry is not a table as a
single line spec. That shorthand is for a source's `fill`, which may answer one
spec without the outer brackets. A subject's `lines` went through the same door,
so

    lines = { "Drag a spell out of your book...", "It goes on the end..." }

was one line whose label was the first sentence and whose value was the second.
A value is a number or a word held against the right edge: `UI/Tooltip.lua`
gives it no width and no wrapping, and the box is capped at `MAX = 266`, so it
grew leftwards out of the frame. The label was sized `content - COLUMN - value`,
clamped to one unit, and drew as nothing.

Six call sites were written that way and every one reads as obviously correct:
`AdHoc/Panel.lua:153` and `:157`, `AdHoc/Bars.lua:330`, `Buffs/Panel.lua:181`
and `:199`, `Cooldowns/Panel.lua:225` and `:236`,
`UnitFrames/DebuffPanel.lua:163`, `Buffs/Nag.lua:379`. `Feeds/Loot.lua`
had both halves of it: its bare-string entries drew as blank lines while the
list had items in it, and as an overhanging pair when it was empty.
