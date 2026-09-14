---
revision: 5
id: 01M2GJ0EG1Q0GSNWGMHCXQE5S2
type: bug
status: done
title: Enemy bar threat colours are the tank's when you are not tanking
---

The enemy bars colour every mob as if you were the tank. Green when a mob is on
you, red when it is on somebody else. For a damage dealer or a healer in a group
that is backwards: the mob on you is the problem, and the mob on the tank is the
state you want.

Where. `src/Unit/Threat.lua`, `Threat.State` and `Threat.Swinging`. Both feed
`src/UnitFrames/EnemyBars.lua` (`ThreatState`) and the hover line in
`src/Meter/Standing.lua`.

Fix. When you are not the tank, invert. The mob on you is red. The mob on
somebody else is shaded by your own scaled percentage on the same 70 and 90
lines the tank view uses for the nearest challenger. On Era, where only the
swing target is known, on you is red and on them is green.

Who is tanking. `Unit.Role.Of("player")`, which is the override, the group
finder, the main tank flag, then talents. A group of one always reads as the
tank, because alone every mob you fight is on you.
