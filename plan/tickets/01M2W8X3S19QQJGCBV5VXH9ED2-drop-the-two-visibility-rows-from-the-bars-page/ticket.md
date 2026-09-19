---
revision: 5
id: 01M2W8X3S19QQJGCBV5VXH9ED2
type: task
status: done
title: Drop the two visibility rows from the bars page
---

"down in combat" and "up while holding" leave the bars page. The behaviour
stays in src/Buttons/Look.lua and behind `actionbars combat` and `actionbars
key`; the themes will set it for every bar at once.
