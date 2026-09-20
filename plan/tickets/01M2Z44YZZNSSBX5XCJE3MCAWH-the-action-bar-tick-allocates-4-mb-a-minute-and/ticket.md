---
revision: 5
id: 01M2Z44YZZNSSBX5XCJE3MCAWH
type: bug
status: todo
title: The action bar tick allocates 4 MB a minute and the gate sees none
labels: [perf]
---

Measured, not guessed. The minute log of the 14:25 session on 2026-09-17 reads
`oursAlloc` 4.2 to 5.2 MB a minute with `allocKey` naming the `action` slot in
nearly every row. That slot is `Buttons/Bars.lua:857` `Bars.Tick` at 0.1 s. It
was under 1% of the client's Lua churn before the quest log loop was fixed at
`0a33558`; with that loop gone it is about a quarter of everything the client
allocates, which is why it is worth a card now and was not before.

The whole read is in the comment thread of `01M2MMRQNQTNCNAFY7TTEB09EM` and in
`docs/SLOW-SESSION.md`. The instrument already exists: `Perf.Allocated` weighs
the heap either side of every ticker bracket and hands back the minute's total
and the slot that made most, and `scripts/perflog.lua` prints it.

Cause, one site proven and the rest not. `UI/Ability.lua:563` `Countdown` is on
the hot closure, is reached from `Bars.Tick` through `Paint` and `Ability.Draw`,
and every one of its three branches builds a string:

    if remaining >= 60 then
        text:SetText(("%dm"):format(math.floor(remaining / 60)))
    elseif remaining >= 10 then
        text:SetText(("%d"):format(remaining))
    else
        text:SetText(("%.1f"):format(remaining))
    end

Under ten seconds the format is `%.1f`, so `Quantum` lets it through ten times a
second per sweeping square. It is the only site on that path that builds a
string by hand and it passes the gate for the reason on the sister card.

Countdown does not account for the whole figure. A small Lua 5.1 string is about
40 bytes, 4 MB a minute is roughly 1650 strings a second, and a few cooldowns
sweeping at ten a second is two orders under that. So the number is a budget to
close, not a single line to delete: measure first, with `Perf.Allocated` split
per call site or by bisecting `Bars.Tick`, and name the rest before changing it.

Ruled out already. `ns.Slot.Count`, `ns.Slot.Range`, `ns.Slot.Aiming` and
`ns.Slot.State` return numbers and booleans and build nothing.
`Ability.Draw:683` builds a string too but sits behind `count ~= w.shownCount`,
which is a real change guard and fires on a stack move, not on a tick.

Fix. Precompute the whole-second strings once. A countdown has at most sixty
distinct `%dm` readings, sixty `%d` readings and a hundred `%.1f` readings under
ten seconds, so a table built at load makes the tick a lookup. Whatever else the
measurement names gets the same treatment or a real guard.

Gate. Closed when `oursAlloc` sits under 1 MB a minute with `allocKey` naming
something other than `action`, over a session past minute 35. The sister card
`an if whose every branch allocates` is what stops it coming back.
