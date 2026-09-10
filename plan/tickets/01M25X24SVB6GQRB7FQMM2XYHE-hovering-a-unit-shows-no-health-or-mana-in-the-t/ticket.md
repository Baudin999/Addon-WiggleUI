---
revision: 5
id: 01M25X24SVB6GQRB7FQMM2XYHE
type: bug
status: todo
title: Hovering a unit shows no health or mana in the tooltip
---

Hover a player, a mob or a party member and the addon's box says who it is and
not how alive it is. The user asked for health and mana on every hover of
something that has them.

## Cause

`UI/Scan.lua` reads Blizzard's tooltip text back into the addon's box. Blizzard
draws a unit's health as `GameTooltipStatusBar`, a bar under the text, and never
draws power at all, so neither figure was ever in the text the scanner reads.

## Fix

`UnitFrames/Vitals.lua` registers two `ns.Tip` sources against the unit kind in
the body band: health as `current / max (percent)`, the percent alone where the
client answers out of 100, "dead" for a corpse; and the unit's pool as
`current / max` under its own name. A unit with no pool gets no line. Each
source has a stamp, so `UI/Fresh.lua` redraws an open box as the figures move.

## Gate

`49-world-hover.lua` asserts both lines on a mob, health on line 4 under the
client's three, health kept on a friendly unit, and the percent-only case. The
threat checks find their line by label rather than by number.
