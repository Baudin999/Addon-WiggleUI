---
revision: 5
id: 01M2QMF9FNT4C2D3J1R6F4AB4X
---

13:28 session on 17 September reached the plateau: over12 452 at minute 21, then 579 577 554 574 570 569, with floor 131.5 to 184.3 MB. Same 1.65 MB a minute, oursKB lows 15.7 to 16.9 MB. Third session in a row that says the leak is not ours.

Instrument, uncommitted. Perf/Trace.lua writes thirteen more columns a minute: beat, slowMs, slowOurs, slowKey, slowEvents, slowAlloc, slowSweeps describe the frames over 12 ms, and alloc, sweeps, oursAlloc, allocKey, allocKB, addonsKB are what they are read against. log.addons holds one column per addon over 2 MB. Perf/Perf.lua weighs the heap either side of every ticker bracket and Perf.Allocated hands the minute's total and the slot that made most. Perf/Held.lua keeps every addon's reading by name. Beat's minute accounting moved into Tally and TallySlow, which took the file's worst function from 84 lines and 4 deep to 59 and 3.

How to read it is in docs/SLOW-SESSION.md. scripts/perflog.lua prints the ring oldest first, one row a minute.

Gate. Harness section 77 alone: ok, and the measured minute still allocates under 0.05 KB with the new columns in it. luacheck on Perf/: 0 and 0. The static half of check.sh, everything above the harness runs: status 0. The full check.sh was not run.
