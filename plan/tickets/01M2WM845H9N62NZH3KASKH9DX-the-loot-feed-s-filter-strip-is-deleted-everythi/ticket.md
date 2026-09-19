---
revision: 5
id: 01M2WM845H9N62NZH3KASKH9DX
type: task
status: review
title: The loot feed's filter strip is deleted; everything that drops shows
parent: 01M2WM7H2QD0KYVCRBZZ25T564
---

Nobody uses the filters. Delete them rather than hide them:

- the chip bars, the reset cross and Feed:Reset/PaintReset/Chip/Chipped/
  Refilter (src/UI/Feed.lua BuildChips and neighbours) if no other feed passes
  opts.chips;
- Chips, Passes, Lit, Light and the quality bitmask (src/Feeds/Loot.lua);
- ns.db.lootFeedShow and its default, with a migration that drops the key;
- the panel page's copy of the same switches (src/Feeds/Feature.lua);
- scripts/harness/sections/40-loot-strip.lua, and the chip asserts in
  40-loot-feed.lua. Lower that file's line ceiling by what it loses.

Keep the delete list control (opts.watch). It holds the strip up on its own
while something is on it; after this it is the only thing that can.
