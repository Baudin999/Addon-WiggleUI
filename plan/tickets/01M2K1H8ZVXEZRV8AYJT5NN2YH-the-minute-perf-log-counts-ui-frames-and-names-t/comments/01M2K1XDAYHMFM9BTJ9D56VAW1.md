---
revision: 5
id: 01M2K1XDAYHMFM9BTJ9D56VAW1
---

Cause. Frames over 12 ms climb from minute ~20 after a reload while events and ours stay flat, and a /reload clears it. The minute log had no view of UI objects or of any addon but ours.  Fix. db87089. Perf/Held.lua walks EnumerateFrames 25 per frame and keeps the last whole pass (uiFrames, uiShown, uiRegions, uiTicking); once a minute it reads addon memory into grower, grew and readMs. The frame after that read is kept out of the counts and dips. First named ns.Stock, which Merchant/Stock.lua owns and overwrote at load: the harness caught it as a nil Walk.  Gate. Section 77 drives 30 stub frames and 3 addons through a minute with the collector stopped, 0.00 KB. Pre-commit green.  Next. Play past minute 30, /reload, read uiShown, uiRegions, uiTicking and grower against over12.
