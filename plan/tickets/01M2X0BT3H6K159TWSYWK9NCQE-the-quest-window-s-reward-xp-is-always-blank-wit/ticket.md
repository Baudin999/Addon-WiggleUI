---
revision: 5
id: 01M2X0BT3H6K159TWSYWK9NCQE
type: bug
status: todo
title: The quest window's reward XP is always blank with Questie v11
---

`Quests/Client.lua` Rewards() reads `xp` from a global
`GetQuestLogRewardXP`, on the belief that Questie's LibQuestXP writes one.
Questie v11, the live install, writes no such global; the call lives on its
QuestXP module (`QuestXP:GetQuestLogRewardXP(questId)`). So the field is nil
on every quest. `Progress.Handin` (bc0d81b) reads it through
`ns.Questie("QuestXP", "GetQuestLogRewardXP")`; Client should do the same,
and the comments at Client.lua:33 and client/12-questlog.lua:304 need fixing.
