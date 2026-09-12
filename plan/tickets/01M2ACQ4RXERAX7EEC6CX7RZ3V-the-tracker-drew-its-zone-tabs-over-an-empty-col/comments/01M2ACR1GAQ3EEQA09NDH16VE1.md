---
revision: 5
id: 01M2ACR1GAQ3EEQA09NDH16VE1
---

Cause. src/Quests/Column.lua made body with SetWidth and no height. No rectangle, so nothing anchored inside it drew: the tally and every row. Fix. body:SetSize(WIDTH, 1) at build and body:SetHeight(told) on every paint, off the same number the frame's own height is taken from. Gate. 85-quest-column asserts the frame measures more than nothing (220.0 by 0.0 without the fix), and 89-frame-rects sweeps every visible frame on the grid that holds something, 268 of them. Also. Side:Resize sized a tab off self.size rather than the line's measured height, so the turned label had less air than written and sat against one edge; UI.TextHeight now, SIDEEDGE 4 -> 6, gated at eight units wider than the line. Landed dea5890, check.sh at zero.
