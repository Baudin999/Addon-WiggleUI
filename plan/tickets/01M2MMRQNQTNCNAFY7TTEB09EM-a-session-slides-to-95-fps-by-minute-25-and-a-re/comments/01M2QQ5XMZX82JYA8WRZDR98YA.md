---
revision: 5
id: 01M2QQ5XMZX82JYA8WRZDR98YA
---

The sweep, uncommitted. src/Perf/Sweep.lua switches one feature off, leaves it off for a fixed number of minutes, switches it back on and moves to the next, so the minute log can be split afterwards on a new text column called off. /wk perf sweep starts it, /wk perf sweep 3 sets the minutes a step lasts, /wk perf sweep stop restores, /wk perf sweep status says where it is. scripts/perflog.lua prints off as the third column.

Aligned to the roll. Perf/Trace.lua Roll calls ns.Sweep.Roll, takes the label for the minute that has just ended and lets the step change happen after it, so no row is half one state and half another. The one exception is a step that came due under combat lockdown: it is held, the minutes it waits through are written as the step that was really off, and the switch happens at PLAYER_REGEN_ENABLED, which lands mid minute, so that one minute is written as mixed and is a row to drop.

Ten steps, a baseline at each end labelled base. Each is switched through the slash word the player would type, so the part apply runs and its tickers, events and hooks come down with the setting. Perf is in the base set trees.lua closes, so nothing under Perf may name ns.EnemyBars or any other feature; the word is found in ns.features and that is the route the gate leaves open.

  base                nothing off, what the eight are read against
  bars   /wk bars     a widget per plate, a tick on every frame filling cast bars, UNIT_AURA UNIT_HEALTH UNIT_POWER_UPDATE per plate
  skin   /wk skin     the same three unit events per frame skinned, a fast poll and a full reading once a second
  cast   /wk cast     a sweep on every frame and ten UNIT_SPELLCAST_ events, armed whether or not you are casting
  action /wk actionbars   allocKey named action in nearly every minute of the 14:25 session at 0.8 to 4 MB, and it is the one step that owns secure buttons
  swing  /wk swing    every frame, plus the combat log, plus UNIT_AURA on the player
  buffs  /wk buffs    ten a second, plus the UNIT_AURA handler Buffs/Upkeep.lua marks as outrunning its own tick
  hits   /wk hits     a combat log subscriber that turns lines into frames
  meter  /wk meter    the other combat log subscriber, with a window redrawing five times a second
  base                nothing off again, so drift across fifty minutes is visible

Always restores. A feature already off is skipped, each step restores before the next is switched, stop restores, and the run writes itself into ns.db.perfSweep so PLAYER_ENTERING_WORLD on the next login finds an interrupted run, puts the feature back and says so. PLAYER_ENTERING_WORLD and not PLAYER_LOGIN: Perf loads before nearly every part, so at login a slash word would reach a part that has built nothing yet.

Left out. The chat window, the cooldown row, the combat feed, the creature tooltip and the quest column all switch cleanly and are the next ten steps if these nine answer nothing; nine is what fits in a session that reaches the plateau. Core/BlizzHide.lua, the bag, mail and merchant windows and the census itself are not on the list: an event that arrives when a window is opened is not what makes 100 KB on a frame nobody opened anything on. Nothing was left out for wanting a reload.

Gate. Harness section 77 alone: ok, with five simulated minutes of the sweep asserted, and the measured minute still allocates under 0.05 KB with the off column in it. luacheck on Perf/: 0 and 0. shape.lua on the three touched files: worst 60 lines, 2 deep, 16 branches. trees.lua over src: 34 edges, 34 allowed. check.sh was not run; its hot guard scan was replicated by hand over the eight Sweep functions hot.lua now derives and came back clean, and no cold: or hot: marker was added, so its allow-lists are untouched.
