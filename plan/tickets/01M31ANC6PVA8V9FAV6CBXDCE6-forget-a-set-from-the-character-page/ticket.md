---
revision: 5
id: 01M31ANC6PVA8V9FAV6CBXDCE6
type: task
status: done
title: Forget a set from the character page
parent: 01M1Y4JDFMVHEB87QK9R1KP4BJ
---

A set can be made from the page and it cannot be dropped from the page. The
only way to lose one is `/wui set forget <name>`, a command nothing on the page
mentions, which is the same hole the empty toggle was made to close at
`76822054`.

## What lands

A gesture on a toggle that forgets that set, and a confirm in front of it.

`Sets.Remove` (`Sets.lua:296`) already does the work and already takes a
`Remember()` snapshot, so `/wui set undo` puts the set back. The confirm says
so, which is what makes it a light confirm rather than a scary one.

## The gesture

Left click wears the set and right click re-takes it, so the two obvious
buttons are spent. The proposal is shift and right click, with `UI.Ask` in
front of it naming the set, because shift is already the modifier this page
uses for a second reading on a hover.

The alternative is a dropdown on the toggle, which buys room for rename and
"follow this spec" as well. That is more window than this needs today, but it
is the shape to reach for the moment a third thing wants a home on a toggle.
Say which at the start rather than writing the shift gesture and then throwing
it away.

## What has to follow the set out

A forgotten set takes its row of circles with it, which `SetRow.Paint` and
`SetRow.Band` already handle through `Listed`. Dropping the last set has to
take the whole line off every row and put the page back to the pixel, which
`52-set-page.lua` asserts at its foot today.

A square on an ad hoc bar pointing at a forgotten set is the other loose end,
and `01M31AMXD1Q58CE4BJ8Q1M8FHP` owns it.

## Testing it in game

Make a set, forget it, and confirm the rows shrink back. Then `/wui set undo`
and confirm it comes back with its slots intact.

## The gate

Extends `52-set-page.lua`. The gesture goes through the pointer with the
buttons named, the confirm is in front of the write, and forgetting the last
set returns the row to the height the page shipped with.
