---
revision: 5
id: 01M2X01ZZXTT04HE92GQVRY02D
type: feature
status: done
title: The XP bar marks where handing in your ready quests lands you
---

On the expressive rail, a lighter section from the fill's edge to where the
XP of every quest ready to hand in would put you, ended by a one-pixel tick.
Clamped at the end of the level. The hover says how many quests, how much XP
and where it lands, or that it carries you into the next level.

The XP is Questie's: `QuestXP:GetQuestLogRewardXP(questId)` through
`ns.Questie`, the one door on its loader. No Questie, no marker. Note that
`Quests/Client.lua`'s `Rewards().xp` reads a global `GetQuestLogRewardXP` that
Questie v11 does not write, so that field is always nil on the live install.
