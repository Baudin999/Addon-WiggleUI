---
revision: 5
id: 01M2WWMZRMETARD9353TH3GFJ3
type: feature
status: todo
title: "A fire palette: the dark stone frame with horde sigils, on horde's floor"
---

`art/fire.jpeg` becomes a seventh palette, `fire`, on `Theme.PALETTES`, in both TOCs, `/wk palette` and the setup page's palette cards.

Frame: measured in `scripts/bake-backdrops.sh`. Inset 98/100/95/83, corner square 300. The rails repeat plaque start to plaque start, 465 across (skull on top, swirl at the foot) and 260 down (dragon and wolf's head). `clear` now takes an across and a down value because the side rail starts 105 above the corner square's end, so its dragon is whole.

Corners: new `block` bake field. The corner blocks are not square (top 215x190, bottom an L of 200x200 plus spikes 285x105), so the painting's own stone floor inside the corner square and outside the block is cut to alpha, and no slab patch sits over the ground. The wolf painted on that floor goes with it.

Floor: `art/horde_bg.jpeg`, the same ground as horde, for now, dim 0.50.

Colours in `src/Theme/Fire.lua`: charcoal surfaces greyer than horde's clay, ember accent from the corner crystals, ash-white text, flame-gold headings.
