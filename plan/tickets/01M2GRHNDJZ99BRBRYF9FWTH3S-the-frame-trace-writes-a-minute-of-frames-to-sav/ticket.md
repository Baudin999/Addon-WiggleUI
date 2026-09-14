---
revision: 5
id: 01M2GRHNDJZ99BRBRYF9FWTH3S
type: task
status: doing
title: The frame trace writes a minute of frames to saved variables
---

Reported 2026-09-14: frame rate falls from 100 to 89 after an hour of play.

The recorder keeps frames and dips in memory only, and a dip is 20 ms or more. On this machine 100 fps is vsync on a 99.98 Hz panel, so the drop is frames of 10 to 20 ms missing a deadline. Nothing records them and nothing survives a reload.

src/Perf/Trace.lua writes one row a minute into WarriorKitDB: average and worst ms, frames over 12, 20 and 50 ms, Lua ms, our ms, events, heap KB, KB collected. A ring of 180 rows, three hours. Read after a /reload.
