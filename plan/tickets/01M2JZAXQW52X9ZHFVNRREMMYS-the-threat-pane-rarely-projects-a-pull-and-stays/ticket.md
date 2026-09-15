---
revision: 5
id: 01M2JZAXQW52X9ZHFVNRREMMYS
type: bug
status: doing
title: The threat pane rarely projects a pull and stays blank with no reason
---

Two reports from play: the threat pane sometimes has no rows, and the "Name in Ns" projection in its header rarely shows.

Cause. Meter/Threat.lua differentiates the scaled percentage, which is a member's threat divided by the tank's pull threshold. The denominator steps up every time the tank lands a blow, so a member gaining steadily reads as falling for half a second, and the exponential average carries that negative sample for seconds. The ETA is only drawn while the average is positive, so it flickers off most of the fight. An empty pane says "held", which is the same word as a pane with rows and nobody climbing, so a client that answered nothing for anyone looks like the addon failing.

Fix. Sample the fifth return, the raw threat value, and derive each member's pull threshold as value * 100 / scaled. Both numbers only climb during a fight. The closing speed is the member's gain minus the threshold's gain over a window of up to three seconds of half second marks, reset when either drops. The header says "no threat" when a hostile target has no threat entry for anyone in the group.

Gate. 25-meters: the projection arithmetic moves to the window, a tank gaining while a member gains faster still projects, and an empty threat table reads "no threat".
