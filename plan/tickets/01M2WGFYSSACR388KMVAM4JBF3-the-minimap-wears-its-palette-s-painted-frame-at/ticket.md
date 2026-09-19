---
revision: 5
id: 01M2WGFYSSACR388KMVAM4JBF3
type: task
status: doing
title: "The minimap wears its palette's painted frame, at half scale"
---

Minimap/Shape.lua draws a 3 px bezel round the square map. When the drawn
palette has a painting, draw its rails and corners round the map instead, with
no floor (the map is the floor), at half the bag window's scale so the corners
reach about 20 px into the map rather than 40. The clock tab moves down by the
bottom rail's thickness so it hangs under the painted edge.

- UI.Backdrop(frame, { scale, floor = false }); Backdrop:Thickness(side).
- Shape.lua: no bands, no hairline and no pad when painted; Layout on Apply.
- Clock.lua: offset by the bottom thickness.
- 88-theme-backdrop: the half-scale, floorless layout.
