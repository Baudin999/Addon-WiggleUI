---
revision: 5
id: 01M2GF3VRGTYBHWZ5ZRAAQK3DS
---

Cause. Each chip was its own dark square with a hairline and a 14 unit mark, eight in a row with 3 units between them and 10 at the break, so the break read like one more gap and the strip read as emoji. The reason chip was the circle glyph, a filled white disc at that size. Nothing turned the chips back on except clicking each one.

Fix. UI/Feed.lua draws each run of chips as one bar (UI.Box, control fill, edge hairline) with flush 16 unit cells parented to it, marks at 11, a hover inset one pixel, 6 units between bars and off at 0.25. A spec with ring = true draws a 10 unit hollow square; Feeds/Loot.lua's reason chip uses it. Feed:Reset sets every chip on, and a cross after the last bar calls it. It is the addon's own button with the xmark, shown by Feed:PaintReset while the strip is up and a chip is off. Chipped, Chrome and a chip click all repaint it, and MouseRows takes its mouse with the chips'.

Gate. scripts/harness/sections/40-loot-strip.lua, after 40-loot-feed, which is at its 908 line ceiling: bar edges against the chips, the ring is a frame, and the reset shows, hides with the strip, restores both chips, hides again and follows the mouse setting. The first run failed the font audit on the seven glyph marks: a chip had no painted parent. Parenting the chips to the bar fixed that.
