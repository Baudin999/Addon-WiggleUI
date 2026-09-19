---
revision: 5
id: 01M2WHHPSYPT0F0430JBEWNS2Y
type: task
status: done
title: Action bars wear the palette's floor under their squares
---

The action bars (and the pet bar, which paints through the same call) draw
the palette's floor tile behind their squares at the bag window's scale, in
place of the flat window colour, at the bar's own background alpha. Laid out
in Look.Paint, which runs after every Arrange.

- UI.Backdrop: SetAlpha, applied to every tile including ones made later.
- Buttons/Look.lua: build the floor once per bar frame, lay it out at the
  frame's measured size, hide the flat fill under it.
