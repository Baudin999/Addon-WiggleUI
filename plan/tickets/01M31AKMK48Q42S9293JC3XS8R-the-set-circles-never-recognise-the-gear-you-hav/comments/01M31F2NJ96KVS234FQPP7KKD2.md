---
revision: 5
id: 01M31F2NJ96KVS234FQPP7KKD2
---

Landed at 119d0fc9.

Fix. Not at the call site. Sets.Entry takes the worn link as a third argument and answers a third value, whether the set's piece is what you have on, compared as keys. Standing and Wearing in the same file already compared keys, so the comparison is now in the one file that knows how an item is written down and PaintCircle reads the answer.

Why there and not a Sets.Same. scripts/trees.lua caps Character -> ns.Sets at thirteen and the cap is a ratchet: a second name would have had to be paid for. Folding the comparison into the call the page already makes costs nothing.

Gate. 52-set-page.lua writes a second link for the same helmet with uniqueId at 114514, checks it keys like the one the set saved, puts it on the doll, fires UNIT_INVENTORY_CHANGED and reads the circle back at rest. The link is written out in the section because the stub hands back one string per item, which is what let the old assertion pass.
