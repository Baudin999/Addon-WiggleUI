---
revision: 5
id: 01M2YZN44SJ61ZJHS46VMKWC70
---

Cause. src/Setup/Setup.lua carried HEIGHT = 400, the mode page's one row of cards and nothing over. The colours page is seven palettes in three columns, so three rows, 416 units of cards under an 84 unit header: the third row was drawn through the footer and out of the window.

Fix. d5ba60de. CardHeight and PageHeight are the card arithmetic in one place, Height takes the tallest page and adds the title bar, the footer and the pad. 494 units today; an eighth palette takes the window with it.

Gate. 00-setup.lua walks all five pages and fails when anything shown in the window hangs more than half a unit below the window's own bottom, measured off the frames. With the 400 put back it says the colours page hangs 52 units out. Half a unit of slack because the window's scale divides into every edge and comes back 1e-13 short.
