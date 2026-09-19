---
revision: 5
id: 01M2WYQG52HC16NMG03R1C3XGH
type: bug
status: done
title: The target's name hugs its percent instead of the frame's outer edge
---

`UnitFrames/Block.lua:310` creates the name justified LEFT on every block.
`PlaceText` stretches it from the portrait edge to the health percent, so on
the mirrored target the box is right but the text sits at its left end,
against the percent: "19% Drywhisker Kobold".

Fix: justify the name by `spec.mirror`, so the target's name hugs the outer
edge the way the player's does and both percents sit next to the character.
