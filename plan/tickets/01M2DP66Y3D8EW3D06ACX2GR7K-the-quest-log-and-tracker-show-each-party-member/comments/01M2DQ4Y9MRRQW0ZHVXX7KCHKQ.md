---
revision: 5
id: 01M2DQ4Y9MRRQW0ZHVXX7KCHKQ
---

Landed at 52a403d. Party.Members is the one source: name, class, and Questie's per-objective fulfilled/required. Log.Read stores it on each quest; the window and the tracker both draw from it. Cause of a hidden bug found on the way: Questie's remoteQuestLogs also holds players it heard over YELL ('Nearby'), and the old merge counted them as party. Names now count only if the roster has them. Client.Objectives now carries the leaderboard index, because blank lines are skipped and Questie keys progress by index. Refresh: none of the client's events fire when a packet lands, so QuestiePartyObjectives.ScheduleUpdate is wrapped at PLAYER_LOGIN. It is a plain wrap, not hooksecurefunc: the table is Questie's, and the harness has no hooksecurefunc. Gate: sections 47 and 85 assert the members, the stranger filter, the packet repaint and the tracker rows. The comms stub moved to client/12-quest-party.lua, because ratchet.lua refuses raising 12-questlog's 810 ceiling. check.sh exit 0, 13/13 harness runs, 0 warnings. Not yet seen in the live client.
