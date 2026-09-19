---
revision: 5
id: 01M2WYZ6EQGT437MJCXP7YHRHM
type: task
status: doing
title: The spent part of a unit frame's health bar is one neutral grey
---

The spent track under a unit frame's health is the fill at `Color.track`
(0.30), so a hostile target at 19% is mostly maroon with a small red chunk:
red on dark red, lowest contrast exactly when the mob is nearly dead.

Fix: on the unit frames (the blocks and the party tiles) the health track is
one neutral grey, the same on every unit. Colour means health left, grey
means health gone. Nameplates keep the tinted track, because there it carries
threat across the whole plate (`Unit/Color.lua`, `Color.track`).
