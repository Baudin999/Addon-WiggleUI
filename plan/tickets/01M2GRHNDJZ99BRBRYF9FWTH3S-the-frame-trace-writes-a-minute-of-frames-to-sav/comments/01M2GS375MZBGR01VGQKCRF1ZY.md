---
revision: 5
id: 01M2GS375MZBGR01VGQKCRF1ZY
---

Cause. The recorder kept frames and dips in memory and logged nothing under 20 ms. The 89 fps report is vsync on a 99.98 Hz panel, so the frames behind it are 10 to 20 ms and a reload emptied what little was kept. No static leak found: login tickers guarded, window builders run once, feed ring capped at 400, GUID tables walked only on events.  Fix. 0e3562a. Perf/Trace.lua sums each minute into WarriorKitDB.perfLog, 180 rows of parallel columns made full length in Trace.Watch. Read over12 against heap and ours after an hour and a /reload.  Gate. Section 77 drives a minute of 25 and 9 ms frames with the collector stopped: 0.00 KB, counts and average read back. Pre-commit green.
