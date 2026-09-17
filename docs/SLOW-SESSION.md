# The session gets slower

Open, as of 17 September 2026. Written from `WarriorKitDB.perfLog`, five
sessions across 15 and 16 September. Nothing here is a fix. It is what the log
says, what that rules out, and what I think is left.

## What happens

A session starts at a clean 10.00 ms a frame and stays there for twenty
minutes. Then, over about eight minutes, it slides to a plateau and sits on it
until you reload.

```
minute  1-26   0 to 7 frames over 12 ms     avg 10.00 ms
minute 27-33   33 to 563                    avg 10.32 ms
minute 34-49   565 to 580                   avg 10.62 ms
```

The plateau is 566 slow frames out of 5658, which is 10.00%. One frame in ten
costs about 4 ms extra. On a 99.98 Hz panel that reads as 95 fps and it is why
the number on screen looks like a GPU problem when it is not.

Ramp onset across the five sessions: minute 21, 20, 25, 27, 27. `/reload` puts
it back to 10.00 ms every time.

## Ruled out

**The compositor.** Baudin's first theory was that Hyprland buffers frames for a
hidden workspace and replays them on the way back. Neither half survives the
log. Every away-minute fits `frames = away + (60 - away) * 100`, no catch-up,
and checking the predicted seconds away against the frames the client actually
spent over 50 ms, the worst disagreement across 26 away-minutes is 3 frames.
Max frames in any minute across 180 rows is 6000 and never 6001, so nothing is
being replayed.

The stronger argument is `/reload`. It rebuilds the Lua state and every frame,
texture and fontstring. It does not recreate the window, the surface, the
swapchain, the present mode or the connection to Hyprland. A compositor problem
cannot be cleared by a command that never speaks to the compositor.

**More drawing.** `uiFrames` sat at exactly 10405 from minute 28 to minute 49
while the slow frames went from 33 to 580. `uiShown` 631, `uiRegions` 2397,
`uiTicking` 14, all flat. The client is drawing the same scene at minute 49
that it drew at minute 28 and drawing it worse.

**Our tickers.** `ours` is 311 to 317 ms a minute before the ramp. During the
plateau it runs 350 to 368. That rise is real but it is not the cause: Lua steps
the collector on allocation, so a ticker that allocates pays for a step inside
its own timing bracket, and a bigger live set makes every step cost more.

## What I thought it was, which was wrong

The slow frames carry ordinary allocation and 13 of 582 saw the collector give
anything back. Kept for the reasoning, not the conclusion.

The Lua live set grows all session and the collector's mark phase grows with it.
Ten steps a second overrun by about 4 ms each.

The evidence for the growing heap is `readMs`, the cost of walking it. That call
renders nothing. It went 9.95 ms to 39.55 ms across a 49 minute session, was
still climbing at the end, and started the next session back at 9.95. Bytes did
not move: `heap` stayed in its usual 150 to 220 MB band. Growing object count
with flat bytes means many small objects.

The collector part is the leading explanation and it is not proven. It fits the
10 Hz signature, the cost scaling with the live set, and the reset on reload,
and I have not tested it directly.

## What is missing

Whose heap, and which structure. `grower` names WarriorKit most minutes, but it
is a difference between two samples of a number the collector swings by 30 MB,
so for this question it is close to worthless.

Two columns were added on 16 September to answer it. `floor` is the smallest the
client's heap got at any point in the minute, taken from the `collectgarbage`
call `Perf/Trace.lua` already makes on every frame. Garbage is what a collection
gives back, so a minute's floor is close to what was live in it, and a floor
that climbs minute on minute is a leak whatever the peaks do. `oursKB` is this
addon's own heap, from the reading `Perf/Held.lua` already takes for `grower`
and used to discard.

If `floor` climbs and `oursKB` climbs with it, it is ours. If `floor` climbs and
`oursKB` does not, it is another addon, and Questie is the only other one in
this install with the volume.

## What 17 September answered

`floor` climbs 1.65 MB a minute, the same in three sessions, and goes back to
106 MB on a reload. The lows of `oursKB` stay between 14 and 19 MB. So the leak
is another addon's. Details, Baganator, OPie and Syndicator are disabled, which
leaves Questie 11.37.1, Titan, Auctionator, DialogueUI, Clique and Leatrix_Plus.

```
13:28 session   floor 131.5 MB (min 2) -> 184.3 MB (min 27)
                over12  1 3 0 ... 135 56 209 160 452 579 577 554 574 570
                plateau from minute 21, floor 169 MB
```

Questie runs two unconditional `C_Timer.NewTicker(0.1)` loops, at
`QuestieMap.lua:218` and `QuestieCombatQueue.lua:17`. The first walks every
active minimap pin. That matches one frame in ten and it is not tested.

A minute of 3533 frames at 16.98 ms is not this bug. It is `maxFPSBk "61"` with
the window out of focus.

The nameplates are pooled and hold nothing per plate: `uiFrames` sat at 10405
while `over12` went 33 to 580.

`freed` is 320 to 570 MB a minute in the world and 70 to 140 at the auction
house, and `oursKB` swings 16 to 57 MB inside it. `check.sh` refuses a table, a
closure and a built string on every ticker path, so what is left is an event
handler with no `-- hot:` tag or a client call that answers with a fresh table.

## The columns added on 17 September

Read these in the first session that reaches the plateau. Every `slow` column is
a sum over the frames at or over 12 ms, so divide by `over12`.

```
beat         near over12: a ten a second timer. Near a tenth of it: random
slowMs       slowMs / over12 is how long a slow frame is
slowOurs     near ours / frames each: the cost is outside our brackets
slowKey      the ticker most often dearest in them, if slowOurs says it is ours
slowAlloc    against alloc / frames: a slow frame carrying a burst of allocation
slowSweeps   against sweeps / frames: a slow frame is a collection giving back
oursAlloc    KB our tickers made inside their brackets; allocKey, allocKB name one
addonsKB     every addon summed; floor less this is the client's own code
addons.<X>   one column per addon over 2 MB. The one whose lows climb is the leak
```

## The cause, found 17 September at 16:26

`Quests/Client.lua` called `ExpandQuestHeader(0)` at the top of every read of the
quest log. The client answers that call with `QUEST_LOG_UPDATE` whether or not
it opened anything. `Quests/Column.lua` reads the log on `QUEST_LOG_UPDATE`. So
the tracker read the whole log on every frame of every session.

```
events    6000 a minute in a minute with nothing in it, which is `frames`
qQueued   5999 6004 6005 5999 6001, which is `frames` again
```

Questie hears the same event and queues a tracker update behind each one.
`QuestieCombatQueue.lua:17` takes at most six entries off that queue every
0.1 s, 3600 a minute, and none in a fight. Fed 6000, the queue grows by 2400 a
minute or more. That is the 1.6 MB a minute `floor` climbed and the 53 to 108 MB
Questie's own column showed. It drains with `tremove(list, 1)`, which shifts
every entry behind the one it takes, so the cost of a tick grows with the
queue. That is the ten a second stall: `beat` 576 of `over12` 582, a slow frame
12.6 ms at minute 18 and 21.4 ms at minute 36.

The fix is `Client.Open` asking only when a header is shut. What to read in the
next session: `topEvent` should no longer be `QUEST_LOG_UPDATE` at `frames`,
`qQueued` should be in the tens, and Questie's column should stay flat.

The sweep of 15:36 to 16:24 found no feature to blame. `alloc` was 560 MB a
minute on both baselines and between 406 and 575 with each of bars, skin, cast,
action, buffs, hits and meter off, moving with what Baudin was doing rather than
with the step. The quest column was not on the list.

## Two things fixed on the way

`Perf/Cause.lua` read `GetScriptCPUUsage` without checking the `scriptProfile`
CVar. With the profiler off the call still answers, and what it answers is a
constant 0, which is a number and passed every other test in that function.
`Perf/Trace.lua` read it as a measurement, latched `minute.profiled` on it, and
wrote `0.00` into the `lua` column where the contract says `-1`. Three hours of
rows claimed the profiler was on and the client had spent no time in Lua.

The harness had an assertion for exactly that, and it passed, because the stub
modelled "profiler off" as the call being absent. No client behaves that way.
The stub now does what 2.5.6 does.

## One real leak, too small to be this

`joinResult` and `joinRight` in `UnitFrames/EnemyBars.lua` are keyed by the
accumulated targeter string and never evicted, so every distinct prefix of every
combination of names becomes a permanent key holding a permanent string. It is
also a broken memo, one `right` per `left`, so two mobs whose lists share a
prefix and diverge overwrite each other every pass and it recomputes anyway.

It grows with your party roster, not with time, which is the wrong axis for this
bug. Worth deleting. Not worth 30 ms of heap-walk growth.

## Checked and clean

Not worth re-deriving. `firstSeen` in `EnemyBars.lua` is capped at 500 and
wiped. The threat `slots` in `Meter/Threat.lua` key on party members, not mobs.
`Breakdown.lua` caps at `MAX_SPELLS = 400`.
