---
revision: 5
id: 01M2JT4Q9DPXYAGF4MT8CGA6F0
---

Cause. The ring counted what it held as min(written, cap), which can never go down once the ring has lapped, so an entry could not be taken out.  Fix. UI/Feed.lua keeps a held count; Feed:Remove finds the entry by identity, shifts every newer entry one slot older, parks the removed table at the end for the next Feed:Entry, and steps written and held back. Entry and Fold test held >= cap instead of written >= cap. The offset follows a removal above the view. The cross is a UI.Button per row, opt-in by opts.removable (Stream passes it, only Loot asks), shown in Feed:Enter and hidden in Leave. The row's OnLeave returns while the pointer is on its cross, and the cross's OnLeave calls Leave only once the pointer is off the row. IsMouseOver is what OPie and Titan call on the live client. The row's OnLeave reads the row as an upvalue, because 31-feeds.lua calls the script with no self.  Gate. scripts/harness/sections/40-loot-remove.lua: gap order and table reuse, a lapped ring, the filter count, the offset, and the cross hover handoff and press. The harness client gained Region:IsMouseOver on the same hit test.
