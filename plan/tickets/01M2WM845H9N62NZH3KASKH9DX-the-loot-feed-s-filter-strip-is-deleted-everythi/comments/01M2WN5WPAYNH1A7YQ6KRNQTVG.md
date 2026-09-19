---
revision: 5
id: 01M2WN5WPAYNH1A7YQ6KRNQTVG
---

Cause. Nobody used the chips, and they carried a filter through the whole feed core: a cached match count in Entry, Push, Fold and Sweep, a walking At and Window, eight saved keys, a panel block, slash words and two harness sections.  Fix. ee68b2a: UI/Feed.lua loses the strip and the filter (BuildChips through Refilter, Shown, At, Window); Chrome takes the title alone and the delete list control sits at the inset. Feeds/Loot.lua loses Chips, Passes, Lit, Light, the glyph constants, ns.QualityWord and entry.quality. lootFeedShow, lootFeedQuest, lootFeedReason, lootFeedMoney, lootFeedFilters and combatFeedFilters are in Core's RETIRED list. The gem glyph (*) in bake-glyphs.sh has no reader now; the font is untouched.  Gate. 40-loot-strip deleted; 40-loot-feed asserts a grey and an epic both get a row. 31-feeds, 31-feed-note, 40-loot-remove, 40-loot-watch, 69-loot-filter pass.
