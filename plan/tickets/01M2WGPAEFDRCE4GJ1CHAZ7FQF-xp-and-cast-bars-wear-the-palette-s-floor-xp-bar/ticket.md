---
revision: 5
id: 01M2WGPAEFDRCE4GJ1CHAZ7FQF
type: task
status: todo
title: XP and cast bars wear the palette's floor; XP bar gets a slim frame
---

The spent part of the experience rails and the player cast bar shows the
palette's painted floor instead of the flat track, with the track kept at
half alpha over it as a tint so the text on the bar still reads. The
experience frame also gets the painted rails and corners at a fifth of the
bag window's scale, the slim version of the border. The cast bar gets the
floor only.

- UI.Backdrop: opts.frame = false, and SetScale, because these frames are on
  the pixel grid and their unit moves with the zoom.
- UI.Gauge: Gauge.Floor(bar) and Gauge.LayFloor(bar, unit, w, h); Paint reads
  a per-bar track alpha.
- Rails.lua, PlayerCast.lua: call both; the rails' hairline comes off under a
  painted frame.
