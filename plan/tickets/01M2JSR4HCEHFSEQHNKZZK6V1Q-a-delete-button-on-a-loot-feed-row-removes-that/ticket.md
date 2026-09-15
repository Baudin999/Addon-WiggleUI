---
revision: 5
id: 01M2JSR4HCEHFSEQHNKZZK6V1Q
type: task
status: done
title: A delete button on a loot feed row removes that entry
---

A row in the loot feed has a cross that takes that one entry out of the ring.

Asked for on 2026-09-15: "a delete button which deletes that item".

Where. src/UI/Feed.lua holds the ring; Feed:Remove compacts it and keeps its own held count, because Count = min(written, cap) cannot go down once the ring has lapped. The button is opt-in on UI.Feed (opts.removable), passed through Feeds/Stream.lua, and only Feeds/Loot.lua asks for it.

Gate. scripts/harness/sections/31-feeds.lua: remove from the top, the middle, a lapped ring, a filtered feed, and a click on the row's cross.
