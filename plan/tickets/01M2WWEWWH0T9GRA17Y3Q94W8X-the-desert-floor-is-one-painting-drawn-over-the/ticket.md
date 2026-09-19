---
revision: 5
id: 01M2WWEWWH0T9GRA17Y3Q94W8X
type: task
status: doing
title: "The desert floor is one painting drawn over the window, not a tile"
---

`art/desert_bg.jpeg` is the desert palette's `ground` in `scripts/bake-backdrops.sh`, drawn once by `Backdrop:Cover`, `dim` 0.45 because pale sand is the brightest of the five. Desert was the last tiled palette, so the backdrop harness section now checks tile arithmetic on a copy of desert's table with its old 100x104 tile.
