---
revision: 5
id: 01M2WVYF6DQBTYHRM7S7DK5598
type: task
status: done
title: "The alliance floor is one painting drawn over the window, not a tile"
---

Same as arcane (7dcfb13) and forest (022aee4): `art/alliance_bg.jpeg` is the alliance palette's `ground` in `scripts/bake-backdrops.sh`, drawn once by `Backdrop:Cover`. `dim` is 0.50, the lowest of the three, because the picture is a scene whose brightest part, a glowing portal, is at the centre the crop keeps, which is behind the bag grid.
