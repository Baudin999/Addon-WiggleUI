---
revision: 5
id: 01M2WV2ZFFNQ54M98WGFZ0V7NW
type: task
status: doing
title: "The arcane floor is one starfield drawn over the window, not a tile"
---

The arcane floor was a 333x150 cut of the frame painting's slab rows, tiled. A slab grid tiled reads as hard lines, not a night sky.

`art/arcane_bg.jpeg` is a floor-only painting with no repeat. The bake takes it as the palette's `ground`: darkened whole to `dim` 0.65, baked at 1024x512, and `Backdrops.lua` marks the palette `cover = true` with the picture's source size. `Backdrop:Cover` in `src/UI/Backdrop.lua` draws it once, scaled to cover the rectangle and cropped evenly, keeping the picture's shape. Tiled palettes are unchanged.
