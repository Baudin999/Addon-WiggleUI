---
revision: 5
id: 01M2QS4H6F3M5SYNPBRFCG3725
---

The 14:49 session on 17 September, 39 minutes, all columns, no sweep. The sweep did not run: the client was started at 14:48, Perf/Sweep.lua went into the TOC at 14:54, and a file added to a TOC is not seen until the client is restarted. A reload is not enough. Every row reads off = blank.

What the slow frames are, at minute 36. over12 582, beat 576: a ten a second timer. slowOurs 66 ms across all 582, 0.11 ms each: not our tickers. slowAlloc 57926 KB, 99.5 KB each, which is what every frame makes: not a burst. slowSweeps 13: not the collector giving back. slowMs / over12 is 12.6 ms at minute 18 and 21.4 ms at minute 36, and over20 goes 0 to 449, so the timer's work grows in a line with the session. That is why this session felt worse than the plateau: past minute 34 one frame in ten is 21 ms.

Whose. Questie 53.2 MB at minute 2 to 108.1 at minute 38, 1.5 MB a minute. WarriorKit lows 22.8, 25.5, 23.9. floor 135.7 to 201.2. The collector theory in docs/SLOW-SESSION.md is dead: the slow frames carry ordinary allocation and no sweeps.

Suspect, not tested. QuestieCombatQueue.lua:17 ticks at 0.1 s and takes up to six entries off the front of _Queue with tremove(list, 1), which shifts every entry behind it. A list fed faster than it drains is both a leak and a cost that grows in a line, which is the shape of both curves. _Queue is a local and cannot be read.

Probe, uncommitted. Perf/Probe.lua wraps QuestieCombatQueue.Queue with a counter, the way Quests/Party.lua wraps ScheduleUpdate, and the log gains qQueued, qPins and qMapPins a minute. The queue drains 3600 a minute at most out of a fight, so qQueued over that is the answer and qQueued under 600 kills the theory. Section 77 ok, luacheck 0 and 0, static half of check.sh status 0.
