---
revision: 5
id: 01M2Z5935C94AB7C2RFWG6EMD0
type: bug
status: todo
title: "EnemyBars asks C_UnitAuras first, against the rule Core states twice"
labels: [perf]
---

`src/UnitFrames/EnemyBars.lua:846` walks a unit's debuffs with

    if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
        local aura = C_UnitAuras.GetDebuffDataByIndex(unit, index)

and falls back to `UnitAura`. That is the preference the wrong way round. The
rule is written down twice: `src/Core/Core.lua:942` states it under
`ns.BuffName`, and `src/UnitFrames/Auras.lua:213` restates it and says "This
file had the preference the other way round", so `Auras.lua` was fixed and this
site was missed.

The reason the rule exists is allocation. The old call hands back a row of
values. The new one builds a table to put them in, and every caller here wants
the values, so the table is made and dropped. This walk runs up to forty slots
per plate on the `bars` ticker, which is `VERIFY` at 1 s plus the per-plate
unit events, so it is tens of tables a second in a pull with several mobs up.

Not a correctness fault. Both calls answer the same question on 2.5.6, and
`C_UnitAuras.GetDebuffDataByIndex` is live on this install, `Details/boot.lua:793`
and `Details_RaidCheck/Details_RaidCheck.lua:63` both call it.

Why no gate caught it. `check.sh`'s hot path scan looks for a table constructor,
a `:format(`, a `string.format(` or a `..` in the source line. Here the table is
built inside the client call, so there is nothing in the line to see. That is a
third hole in the same rule, next to the two on
`01M2Z45CV4Y1QW1E89SFKXYN7T` and `01M2Z45WFBPD1E4BDCJP97SKDK`, and the honest
answer is probably a named list of client calls that allocate rather than a
pattern over the line.

Fix. Ask `UnitAura` first and `C_UnitAuras` second, as `Auras.lua` does.

Gate. The rule is stated in prose in two files and enforced nowhere. Make it a
check: no file may test `C_UnitAuras` before `UnitAura` in the same branch
ladder. One allow-list entry with a reason for any site that genuinely wants the
new call's extra fields.

Found while investigating why a hunter's stings did not light on the debuff row.
That turned out to be a different thing, `01M2Z58P3R3Q69CXMDPX49438X`.
