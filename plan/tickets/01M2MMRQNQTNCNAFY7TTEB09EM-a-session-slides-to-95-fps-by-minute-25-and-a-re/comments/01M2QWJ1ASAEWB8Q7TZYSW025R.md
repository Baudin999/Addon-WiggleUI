---
revision: 5
id: 01M2QWJ1ASAEWB8Q7TZYSW025R
---

Cause. Quests/Client.lua Client.Open called ExpandQuestHeader(0) on every read of the log. The client answers that with QUEST_LOG_UPDATE whether or not anything opened, and Quests/Column.lua reads the log on QUEST_LOG_UPDATE, so the tracker read the whole log every frame. The sweep log of 15:36 to 16:24 on 17 September shows it twice: events is 6000 a minute in an idle minute and qQueued is 5999, 6004, 6005, both the frame count. Questie queues a tracker update behind each event and QuestieCombatQueue.lua:17 drains 3600 a minute at best and none in a fight, with tremove(list, 1). The backlog is the 1.6 MB a minute leak, Questie's column going 45 to 113 MB, and the shifting is the ten a second stall that grew to 21 ms.

Fix, uncommitted. Client.Open walks the rows with GetQuestLogTitle and fires ExpandQuestHeader only when a header is shut.

Gate. The harness stub can now shut a header. 47-quest-log asserts no ask with every header open, one ask with one shut, none on the read after. 47-questie-api used the expand count as its read probe and now shuts a header first. Sections 47-questie-api, 47-quest-log, 47-quest-map, 47-quest-pin, 85-quest-column, 77-frame-trace ok. luacheck Perf and Quests 0 and 0. Static half of check.sh status 0. Full check.sh not run.

Sweep result. No feature of the eight owns the garbage: alloc 560 MB on both baselines, 406 to 575 with each one off, following activity and not the step. The quest column was not on the list, which is where the loop was.

Also added. topEvent, topEvents, nextEvent, nextEvents a minute from Perf/Census.lua, so the next log names the event. A held sweep step now says so, and a part raising while being switched stops the sweep instead of breaking the roll.

To confirm in the next session: topEvent is not QUEST_LOG_UPDATE at the frame count, qQueued in the tens, Questie flat, no plateau by minute 35.
