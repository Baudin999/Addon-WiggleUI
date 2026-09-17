---
revision: 5
id: 01M2QXCZ78H63G6SW2Z5WNWRCK
type: task
status: todo
title: The harness drops its 800 line file cap for shape.lua
---

`./scripts/deploy.sh --type beta` stopped on three harness files over a line
ceiling: 25-meters.lua at 825, 55-bags.lua at 823 over 806, 85-quest-column.lua
at 839 over 825. `HARNESS_LINE_ALLOWED` in scripts/check.sh held eleven entries
and the ratchet history shows them going up, which is the same failure that
retired the addon's own file ceiling for scripts/shape.lua.

Delete `HARNESS_LINE_LIMIT` and `HARNESS_LINE_ALLOWED`. Pass the harness files
to the existing shape.lua call so its functions meet 100 lines, 4 deep and 30
branches like the addon's. Keep `HARNESS_NAME_LIMIT`: Lua 5.1's 200 locals per
chunk is a real limit and the name budget is what watches it.

The same deploy also stopped on `Talents/Trace.lua:65`, a bare
`GetCraftSelectionIndex` luacheck does not know.
