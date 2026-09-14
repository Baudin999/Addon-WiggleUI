---
revision: 5
id: 01M2GT5W76HRA4GYGCY8B1RHKJ
type: task
status: done
title: The pet bar does not move with shift like the action bars
---

The pet bar was placed with UI.Placeable, so only `/wk unlock` reached it, and
then only by its three pixel pad: every other pixel is a secure square whose
drag picks up the pet action. The action bars move with shift held, through
the handle Buttons/Placing.lua lays over each bar.

Fix: the pet bar joins Placing.lua (`Place.Join`). The shift watcher,
`/wk unlock`, `actionbars where` and `actionbars reset` walk joined frames with
the plan's bars. A drag is written to `barPoints.pet`. `petBarPoint` is retired.

Gate: harness 05-pet-bar holds shift, checks the handle is up, drags the bar,
reads `barPoints.pet` and the `where` line, and resets it to 0, 184.
