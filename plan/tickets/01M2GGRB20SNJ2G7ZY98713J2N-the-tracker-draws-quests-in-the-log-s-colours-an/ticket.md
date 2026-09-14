---
revision: 5
id: 01M2GGRB20SNJ2G7ZY98713J2N
type: task
status: doing
title: The tracker draws quests in the log's colours and level tag
---

The quest log draws a quest as `[level+] Title` in the XP ladder colour, green when it is ready to hand in and red when it failed. The tracker in Quests/Column.lua draws the bare title in body text, with gold for ready and red for failed, so the same quest reads two ways.

Move the log's Label and Tint out of Quests/Window.lua onto ns.QuestLog so both callers draw the one definition, and point Column's Quest() at them.
