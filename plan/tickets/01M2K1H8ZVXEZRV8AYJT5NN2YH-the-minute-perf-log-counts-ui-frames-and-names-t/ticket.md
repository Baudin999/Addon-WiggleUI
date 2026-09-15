---
revision: 5
id: 01M2K1H8ZVXEZRV8AYJT5NN2YH
type: task
status: done
title: The minute perf log counts UI frames and names the addon that grew
---

Reported 2026-09-15: the frame rate falls to 90 about twenty minutes after a reload, and a /reload brings it back.

WarriorKitDB.perfLog from 17:54 to 18:27, standing still: events flat at 6000 a minute, our tickers flat at 235 ms a minute, frames over 12 ms from 1 to 584 a minute, average frame 10.00 to 10.44 ms. The 16:31 session climbs the same way from minute 30. A reload clears every addon's frames and hooks, and the log can see neither: it counts no UI objects, and with scriptProfile off it has no split by addon.

src/Perf/Trace.lua adds columns to each minute: frames the client holds, how many are visible, regions on the visible ones, visible frames with an OnUpdate, and the addon whose memory grew most, with its KB. The frame walk is spread across frames so no single frame pays for it.
