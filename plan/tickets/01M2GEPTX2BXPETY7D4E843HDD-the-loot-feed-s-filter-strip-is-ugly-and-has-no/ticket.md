---
revision: 5
id: 01M2GEPTX2BXPETY7D4E843HDD
type: task
status: todo
title: The loot feed's filter strip is ugly and has no reset
---

The chips over the loot feed are eight boxed squares at full saturation, each
with its own hairline, and the reason chip is a blank white disc. In the game at
zoom 1 over open ground the strip reads as a row of emoji rather than as a
control. There is no way back to "show everything" short of clicking every chip
that is off, or opening the panel.

Wanted:

- the two runs of chips drawn as two segmented bars, one surface and one hairline
  each, with the marks bare inside them;
- the reason chip drawn as the ring the rows draw, a hollow square, rather than
  a filled disc;
- a reset button after the strip that turns every chip back on, up only while a
  chip is off.

Files: src/UI/Feed.lua (BuildChips, Chrome, MouseRows), src/Feeds/Loot.lua
(Chips), a harness section for the reset.
