---
revision: 5
id: 01M2JV446D6ZEZXAM6ZWF28RPC
---

Fix. Feeds/Loot.lua keeps the list in ns.dbc.lootFeedDelete, item id to link, and OnLoot refuses a listed item before AddItem and counts it; Floats.OnLoot asks LootFeed.Listed too. UI/Feed.lua takes opts.watch {can, add, count, subject, clear, row}: a trash can per row (RowButton, beside the cross) and a danger-red strip control with the count. Chrome holds the strip up while the list is non-empty even with chips and title off, and Stream passes onLayout = Apply so the frame height follows. Feed:Remove is now Feed:Sweep(match), one walk that writes the kept entries back oldest first and the removed tables after them for Feed:Entry to reuse. UI.Feed went to 105 lines, so the scroll bar moved into BuildBar rather than onto an allow-list.  Gate. scripts/harness/sections/40-loot-watch.lua: the can sweeps every row of the item and keeps other items' rows, the hover handoff, a listed drop makes no row and no float, the strip stays up with chips and title off, and pressing the control empties the list and lets the item back in. The harness stub gives every link item id 1, so the section writes its own links.
