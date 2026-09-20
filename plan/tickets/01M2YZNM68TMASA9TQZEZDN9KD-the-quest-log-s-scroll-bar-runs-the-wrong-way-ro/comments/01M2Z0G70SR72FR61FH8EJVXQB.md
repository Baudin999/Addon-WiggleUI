---
revision: 5
id: 01M2Z0G70SR72FR61FH8EJVXQB
---

Cause. A vertical Slider on 2.5.6 has its minimum at the bottom of the track, so a drag downward reports a smaller value. UI/Scroll.lua counted the offset from the top and wrote it into the slider unchanged, so the bar ran backwards: thumb at the bottom while the page was at the top, and a drag that moved the page against the hand. Confirmed from the game: the wheel scrolled correctly on the same list at the same time, because the wheel never goes through the slider.

Ruled out on the way, so nobody re-derives it: the clipping path is the one this client takes, the canvas moves the right way, and the wheel handler's sign is right. What the earlier reading of LibQTip and AceGUI proved was the direction of SetVerticalScroll, not which end of a vertical track the minimum sits at. Those two libraries have the same inversion in their own bars; nobody drags a tooltip's.

Fix. 30958cfa. UI.ScrollSpan and UI.ScrollAt in UI/Scroll.lua are the mirror, and the three files that own a bar (the view, UI/Log.lua, UI/Feed.lua) go through them. Both helpers compare against the widget before writing, which is also where the per-line guard the log and the feed each kept belongs. UI.ScrollWhere was written and then had no callers left; it is not in the commit. The ScrollFrame fallback's SetVerticalScroll(-offset) is positive now, unreached on either client.

Gate. scripts/harness/sections/02-scroll-bar.lua, beside 02-layout-engine. It writes the slider from the client's end the way a drag does and checks the page went with the hand; put the mirror back and four lines fail. 29-social reads the bar's range as well as its value writes now: at the newest line the value is already right and only the range moves, so the old proxy read a correct return as no work done.
