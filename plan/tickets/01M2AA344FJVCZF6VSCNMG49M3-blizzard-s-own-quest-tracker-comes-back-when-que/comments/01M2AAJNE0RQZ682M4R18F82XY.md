---
revision: 5
id: 01M2AAJNE0RQZ682M4R18F82XY
---

Cause. Questie is what used to hide Blizzard's QuestWatchFrame, and only while its own tracker is enabled: QuestieInit:Init and Questie:OnEnable both sit behind Questie.db.profile.trackerEnabled. Quests/TrackerOff.lua switches that off, so ticking the box handed the client's tracker back to the client. It arrives partway through an evening rather than at login because autoQuestWatch is what puts a quest on the client's watch list.

Fix. Quests/Blizzard.lua grows a second cage, ns.QuestWatchBlizzard, over QuestWatchFrame and QuestTimerFrame on the quests and questsTrackerOff pair. Core/BlizzAdapter.lua's cage now takes a descriptor with no global: a watch frame has no toggle and no key to swap, so TakeKey, GiveKey, Caged and Describe all branch on whether the part is keyed.

Watch for. The client's UIParentManagedFrameMixin:OnShow re-parents the frame through AddManagedFrame, so the cage only holds because Core/Attic.lua hooks SetParent and re-cages. That is asserted in the section rather than left to reading.

Gate. 84-questie-tracker.lua carries the block; the stub in client/12-questlog.lua now builds both frames and shows the watch frame. check.sh at zero.
