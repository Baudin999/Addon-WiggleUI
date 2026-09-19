---
revision: 5
id: 01M2WM83Z9AFFGRX657KRA7N3D
type: task
status: review
title: "A feed row's wash is the palette's painting, fading as it does now"
parent: 01M2WM7H2QD0KYVCRBZZ25T564
---

The row wash is a flat C.shadow ramp (UI.Wash, src/UI/Draw.lua:147; built in
BuildRow, src/UI/Feed.lua:320; strength in Feed:Wash, src/UI/Feed.lua:1620).

Wanted:

- under a palette with a painting (Theme/Backdrops.lua), the wash is that
  painting's Middle tile with the same left-to-right alpha ramp;
- each row samples its own band of the tile, offset by its row index, so the
  stack reads as one painting dissolving into the world rather than stripes;
- per row, never a panel behind the column: the feed stays see-through;
- the background slider still sets its strength;
- the dark palette, which has no painting, keeps the flat ramp.

Open: whether ns.Gradient's vertex colours ramp a file texture on 2.5.6. Check
an installed addon or the FrameXML before assuming it.
