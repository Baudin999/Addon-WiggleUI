---
revision: 5
id: 01M2WM84BV5QMBJRTSDX6AJ5C7
type: task
status: done
title: The purse slides out left of the loot feed on hover and back in
parent: 01M2WM7H2QD0KYVCRBZZ25T564
---

The three-cell footer (Instance:Dress and the status strip, src/Feeds/
Stream.lua around 290-360) goes, and with it the empty height between the last
row and the bottom edge.

Wanted:

- the strip's right end shows this session's earnings in heading gold;
- hovering it, after the hover boxes' usual short wait, slides the purse panel
  out from behind the feed's left edge: the same content The purse tooltip
  shows now, on the painted floor;
- leaving the number or the panel slides it back in behind the feed. Hover
  opens it and hover closes it; there is no click;
- the panel sits one frame level under the rows, so it comes out from behind
  the feed rather than over it;
- the motion uses the drops' easing and duration (src/Feeds/Floats.lua), not a
  second curve.

Depends on the tooltip card for the floor.
