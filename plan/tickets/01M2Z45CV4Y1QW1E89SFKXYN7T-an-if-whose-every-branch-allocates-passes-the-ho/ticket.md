---
revision: 5
id: 01M2Z45CV4Y1QW1E89SFKXYN7T
type: task
status: todo
title: An if whose every branch allocates passes the hot guard as guarded
labels: [perf, gate]
---

The hot path scan in `scripts/check.sh` does not refuse an allocation. It
refuses an *unguarded* one:

    guarded = 0
    for (k = 2; k <= indent; k++) if (opener[k] == "if") guarded = 1
    if (!guarded) printf "%s:%d: %s %s without a guard: %s\n", ...

Any enclosing `if` at any depth clears it. That reads an `if` as a thing which
stops work from happening, and an `if/elseif/else` is not: it picks which work
happens. Every branch of `UI/Ability.lua:563` `Countdown` builds a string, so
the function allocates on every call and the gate calls it guarded. It is on the
hot closure, `lua5.1 scripts/hot.lua src` prints `UI/Ability.lua:Countdown`, and
it is the proven site on the card `the action bar tick allocates 4 MB a minute`.

Not a one line fix. The obvious tightening, "an `else` is not a guard", is wrong
on its own: an `else` that returns early or writes nothing is fine, and the
addon has those. What distinguishes the bad shape is that *every* arm of the
chain allocates, which the awk pass can see because it already tracks `opener`
by indent. Walk the chain, mark each arm as allocating or not, and refuse only
when none of them is free.

Two other holes in the same block worth settling while it is open, or writing
down as deliberate if they are:

- A guard that is a constant, or one that tests something the tick just wrote,
  is read the same as a guard that tests whether the value moved.
- The exemption marker is `-- allocates: <reason>` and nothing counts them, so
  the allow-list here has no ratchet the way `FRAMED_TICKERS_ALLOWED` and
  `QUEST_SORT_ALLOWED` do. Count them per file and lower it on every fix.

Gate. The rule change has to fail on `Countdown` as it stands today before that
function is touched, and pass once it is fixed. Add a fixture rather than
proving it against live source, so the next edit to `Ability.lua` cannot quietly
make the test vacuous.
