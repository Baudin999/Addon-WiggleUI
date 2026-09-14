---
revision: 5
id: 01M2GE02J6DTTWPQYK8T0A8GWE
type: bug
status: done
title: Hover boxes that wait restart the wait on a 2 px pointer drift
---

Every hover that waits for the pointer came late: bag squares at 200 ms, feed chips, glyph buttons and settings hints at Tip.HOLD.

src/UI/Tip.lua Settle restarted the wait whenever the pointer moved more than 2 physical pixels. On a 3440x1440 screen that is less than a resting hand moves, so the count kept going back to zero.
