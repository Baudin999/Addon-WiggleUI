---
revision: 5
id: 01M2Z45WFBPD1E4BDCJP97SKDK
type: task
status: todo
title: "hot.lua walks tickers only, so an event handler's garbage is unseen"
labels: [perf, gate]
---

`scripts/hot.lua` derives the hot closure by walking out from frame handlers it
can name, and every permanent tick is registered through `ns.UI.Ticker`, so
every ticker is a root by construction. That is the design and it is a good one.
The closure is 651 functions.

An event handler is not a root. It has no `hot:` marker and nothing walks to it,
so `check.sh` has never read a line inside one. The measurement says that is
where the rest of the garbage is: the second comment on
`01M2MMRQNQTNCNAFY7TTEB09EM` records `oursKB` swinging 16 to 57 MB a minute with
under 6 MB of it made inside a Perf bracket, which puts tens of MB a minute in
code the lint cannot see. Written down on 2026-09-17 and never carded.

Why it matters more than it looks. An event handler is hotter than most tickers
on this addon's own numbers. `Perf/Census.lua` counted 6000 events a minute in
an idle minute during the quest log loop, and `topEvent` after the fix is
`UNIT_POWER_FREQUENT` at 94 to 169 a minute. `Core/CombatLog.lua` takes the
busiest event the client sends. `UnitFrames/Skin.lua` and
`UnitFrames/EnemyBars.lua` each take three unit events per plate.

Two ways in and I do not know which is right.

The cheap one: treat `frame:SetScript("OnEvent", fn)` and the addon's own
registration helpers as roots the same way `UI.Ticker` is, and let the existing
walk do the rest. Risk is the closure grows from 651 to most of the addon and
the rule becomes noise, which is the shape the `_G` rule was rejected for.

The honest one: measure first. `Perf.Start`/`Perf.Stop` already bracket by name
and `Perf/Census.lua` already sees every event. Bracket the handlers, weigh the
heap either side the way `Perf.Allocated` does for tickers, and let the numbers
say which handlers deserve to be in the closure. Then add those as roots by
name, with the count gated so the list cannot quietly shrink.

Second is what I would do. The first would land a 2000 function closure and an
allow-list nobody reads, and the whole argument for this gate is that its
allow-lists are short enough to be read.

Gate. Closed when a deliberately allocating event handler fails `check.sh`, with
a fixture, and when `oursKB` less what the brackets account for is under 5 MB a
minute over a session past minute 35.
