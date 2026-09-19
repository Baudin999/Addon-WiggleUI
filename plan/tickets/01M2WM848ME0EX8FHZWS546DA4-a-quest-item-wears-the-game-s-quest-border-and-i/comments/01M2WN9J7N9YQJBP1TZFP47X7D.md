---
revision: 5
id: 01M2WN9J7N9YQJBP1TZFP47X7D
---

Cause. The ring round a loot row's icon meant quest, reagent or trash on one frame, so it read as none of them; the quest count sat in a dim middle column.  Fix. b8bb9c7: a quest item (Need says quest, or class 12) lays TEXTURE_ITEM_QUEST_BORDER over its icon, and TEXTURE_ITEM_QUEST_BANG when its tooltip carries ITEM_STARTS_QUEST (Blizzard_FrameXMLBase/Classic/Constants.lua:334-335; Baganator sets both on this client, the stock 2.5.6 bags draw neither). A link cannot say whether the quest is already active, so every starter gets the bang. The count to go is in the number column; the middle column is gone. The ring is a reagent's only; trash draws nothing. UI/Feed.lua lays whatever texture an entry names as badge. QUEST in Loot.lua is deleted.  Gate. 40-loot-feed asserts border, bang, no ring on quest or trash, count across a fold; 31-feed-note and 69-loot-filter pass. Not yet seen in the client.
