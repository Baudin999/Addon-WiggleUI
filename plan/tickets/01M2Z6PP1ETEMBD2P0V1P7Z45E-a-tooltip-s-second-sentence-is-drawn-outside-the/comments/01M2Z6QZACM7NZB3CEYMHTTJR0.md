---
revision: 5
id: 01M2Z6QZACM7NZB3CEYMHTTJR0
---

Fixed in fa15ef7e.

Cause. UI/Tip.lua:Pour's shorthand, described on the card. Worth adding: the
shorthand itself is not the defect. A source that answers one spec without the
outer brackets is a real convenience and eight of them use it. The defect was
one function serving two callers with different contracts.

Fix. Two functions. Tip.Lines takes a subject's list, one entry per line, and a
bare string is a line. Tip.Pour keeps the shorthand and only sources reach it.
No call site changed, which is the point: `{ "a", "b" }` now means what it looks
like everywhere it was already written.

Then the box stopped being able to overhang at all, because the call sites were
only the cause this time. A pair wider than MAX stacks onto two lines with the
value wrapped inside the box and still on its right edge. UI/Tooltip.lua:Layout
split into Place and Gauge on the way past the 100 line gate; worst function in
the file is now 59.

Gate. scripts/harness/sections/48-tooltips.lua, two blocks: two sentences draw
two lines and a bracketed pair is still a pair, then Tooltip.Spill() == 0 on a
subject built to overhang. Spill is rebuilt from the widths the strings were
measured at, not read off the font strings, because a font string with no width
answers no width on the client and in the stub both. Take the stacking out and
it fails at 270.4 units, which I checked rather than assumed.

Ruled out. Not a wrap-width problem and not a MAX problem: widening the box
moves the overhang, it does not remove it, and the label was still drawing as
nothing at any width. Not a UI/Scan.lua problem either; the subject never
reaches the scanner.

Gated in .claude/worktrees/tip-spill against HEAD, because the main tree is
mid-edit by another session and 37-player-cast fails twice there and passes at
HEAD. Whole run plus 13 class runs, 0 warnings, 0 errors in 310 files.
