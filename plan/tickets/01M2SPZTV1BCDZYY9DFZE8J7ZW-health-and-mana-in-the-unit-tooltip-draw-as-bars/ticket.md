---
revision: 5
id: 01M2SPZTV1BCDZYY9DFZE8J7ZW
type: feature
status: done
title: Health and mana in the unit tooltip draw as bars
---

The Health and pool lines on a unit hover were text only. The user wants them
drawn as bars: health in the class colour, the pool in its power colour.

## Fix

`UI/Tooltip.lua` takes `bar = fraction, fill = colour` on a paired line and
draws a gauge behind it: a track through `Gauge.Paint`, a fill that far across,
the text inset 3 units and drawn on top. `UnitFrames/Vitals.lua` hands health
over in `Color.OfUnit`, which is the class for a player and the reaction for
anything else, and the pool in `Color.power`.

## Gate

`49-world-hover.lua` asserts both gauges on the mob: fraction and colour.
