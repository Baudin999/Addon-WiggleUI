---
revision: 5
id: 01M2YZQMZHQAPSVM64VTWVEWVC
type: task
status: done
title: "A ring is drawn at the big sharp size, not the small one"
---

An ad hoc ring drew its squares at 27 units, the small sharp size, which is
the size a bar you read all night is drawn at. A ring is up for the second
your thumb is on its key and has to be read in one look.

The zoom was meant to cover that. `AdHoc/Feature.lua` defaulted `adhocZoom` to
1.4, which is 27 times 1.4 is 38, and 38 is neither of the two sizes where a
stored texel lands on a pixel, so every icon on the ring was resampled. Worse,
a default only reaches a player who has never touched the setting: a saved 1
overrides it in silence, and `Core/Shipped.lua` ships a captured 1, so the
ring nobody had ever typed `adhoc zoom` at came up at 27 pixels in the middle
of a 3440 by 1440 screen.

Fix. `SIZE` is 54, the other size `UI.IconSizes` answers, and the circle, the
gap between two squares and the name in the middle are written as a share of
it rather than as three more numbers that would be left behind the next time
the square moves. The zoom default goes back to 1, so the row on the zoom page
is what it says it is.

Scale. The ring was already on the pixel grid and already followed the general
size; nothing proved it. `76-adhoc.lua` now asserts the square is 54 units,
that the ring's own zoom and `Everything` each double what reaches the screen,
and that neither is spent on the square's units instead of the frame's scale,
which is the way the enemy bars made their size slider inert.

Gate. `./scripts/check.sh`, 0 warnings / 0 errors in 307 files.
