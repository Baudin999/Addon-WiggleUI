---
revision: 5
id: 01M2W8X3ZSH458FRQ1VXBS2KC1
type: feature
status: done
title: "Three themes: immersive, informational, exploration"
labels: [needs-design]
---

A theme sets many display decisions at once instead of one row per setting
per page. Three of them: immersive, informational, exploration.

What the themes own, so far, taken off the bars page on 2026-09-19 with the
behaviour kept:

- the bar's ground colour (removed in 05ca2a1; every bar paints the window
  colour and Look.Retire dropped the saved ones);
- when a bar is up: down in combat, up only while shift/ctrl/alt is held
  (Look.SetCombat, Look.SetKey, still on the slash words).

Still to decide: what each theme sets for each of these, and where the
theme picker lives in the window.
