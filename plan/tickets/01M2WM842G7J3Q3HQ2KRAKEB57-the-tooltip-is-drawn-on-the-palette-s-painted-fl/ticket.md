---
revision: 5
id: 01M2WM842G7J3Q3HQ2KRAKEB57
type: task
status: done
title: The tooltip is drawn on the palette's painted floor
parent: 01M2WM7H2QD0KYVCRBZZ25T564
---

ns.Tip draws a flat fill (src/UI/Tip.lua). Give it the palette's floor through
UI.Backdrop(frame, { frame = false }), the way src/Buttons/Look.lua:397 and
src/UI/Gauge.lua:175 already take it, laid out whenever the tip is sized.

Floor only, no rails or corners: at 16 to 18 units thick they are sized for
the bag window and would swamp a four line tip. The palette's hairline stays as
the edge. The dark palette keeps the flat fill, which UI.Backdrop answers with
nil.

This is also the surface the purse panel slides out on, so it lands first.
