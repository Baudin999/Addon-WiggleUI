---
revision: 5
id: 01M2MMRQNQTNCNAFY7TTEB09EM
type: task
status: doing
title: A session slides to 95 fps by minute 25 and a reload puts it back
---

Findings are in `docs/SLOW-SESSION.md`. Read that before re-deriving anything;
five sessions of `WarriorKitDB.perfLog` are already summarised there.

Short version. Frames over the 100 Hz deadline go from under 7 a minute to 566
of 5658, which is exactly 10.00%, between minute 20 and minute 33. `/reload`
clears it every time. Onset across five sessions: minute 21, 20, 25, 27, 27.

Ruled out with evidence: the compositor, more drawing, our own tickers. The
leading explanation is the collector marking a growing live set, roughly ten
steps a second at about 4 ms each. `readMs`, which walks the Lua heap and
renders nothing, went 9.95 to 39.55 ms across one 49 minute session and started
the next at 9.95.

What is missing is whose heap. `floor` and `oursKB` were added to the minute log
on 16 September to answer that in one session. If `floor` climbs and `oursKB`
climbs with it, it is ours. If `floor` climbs alone, it is another addon and
Questie is the only candidate with the volume.

Not committed yet: the tree is red at HEAD from three harness sections over
their line ceilings and one luacheck warning in `Talents/Trace.lua`, none of
them from this work.
