---
revision: 5
id: 01M2DP66Y3D8EW3D06ACX2GR7K
type: task
status: doing
title: The quest log and tracker show each party member's progress
---

Asked for on 2026-09-13: in the quest log, show which quests the party also
has, the way Questie does, in both the quest window and the tracker over the
world, off one data source.

What was there. `src/Quests/Party.lua` already merged the client's
`IsUnitOnQuest(index, unit)` with `QuestieComms:GetQuest(questId)` into a list
of names. The window drew the count on the row and the names on its hover. The
tracker drew nothing, and neither view showed how far along anyone was.

What Questie shows. Per objective, per member, the member's own count in their
class colour (`Modules/Tooltips/Tooltip.lua`, installed v11.37.1).

The work.

- `Party.lua` answers members rather than names: name, class, and the
  per-objective `fulfilled`/`required`/`finished` Questie stores in
  `QuestieComms.remoteQuestLogs[questId][name]`
  (`Modules/Network/QuestieComms.lua:343`).
- Only people in the group count. Questie's remote logs also hold players it
  heard over YELL, marked "Nearby" in its own tooltip, and the old merge
  counted them as party.
- `Log.Read` stores the members on each quest. The window's objectives and the
  tracker's objectives draw a line per member under each one.
- A packet landing from a party member repaints both, off
  `QuestiePartyObjectives:ScheduleUpdate`
  (`Modules/Network/QuestiePartyObjectives.lua:511`).

Verified. `IsUnitOnQuest(questIndex, "party"..j)` is the 2.5.6 signature
(`Blizzard_UIPanels_Game/TBC/QuestLogFrame.lua:180`, wow-ui-source
classic_anniversary).
