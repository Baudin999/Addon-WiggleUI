---
revision: 5
id: 01M2Z18M23S7BXJWCQS7760B5S
type: task
status: doing
title: "A parchment palette: paper ground, torn and toasted edge"
---

Dialogue UI draws its quest text on a sheet of parchment and the ask is for
that look here, as an eighth palette.

Its own art, not that addon's. `Art/Book/TextureKit-Parchment.png` in the
installed DialogueUI is Peterodox's and ships with no licence; this repository
is public and `scripts/check.sh` already gates one file for that exact reason.
So the sheet is painted here instead, by `scripts/paint-parchment.sh`, and the
painting goes through `scripts/bake-backdrops.sh` like the other six.

What the palette is:

- `art/parchment.png`, the frame painting: a torn sheet on a white margin, its
  border toasted to sepia over the outer 90 pixels.
- `art/parchment_bg.png`, the ground: the paper field alone, drawn once over
  the whole window the way every other palette's floor is now.
- `src/Theme/Parchment.lua`, on `Theme.PALETTES`, in both TOCs, and a card on
  the setup's colours page, which `PaletteCards` builds off that list.

The ground is dimmed to a mean luminance near 0.15. That is the number the
fixed colours decide, not taste: `UI.Quality[1]` is white, `[2]` is the green,
and neither is the palette's to change, so a paper left at its painted
brightness would put a white item name at 1.4 to 1 on it. Dimmed, white reads
at better than five to one and the green clears three.
