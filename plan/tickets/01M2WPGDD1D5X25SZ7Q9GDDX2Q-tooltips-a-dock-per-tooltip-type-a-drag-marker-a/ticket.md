---
revision: 5
id: 01M2WPGDD1D5X25SZ7Q9GDDX2Q
type: task
status: doing
title: "Tooltips: a dock per tooltip type, a drag marker, a darker floor"
---

The Hovers section is renamed Tooltips. One global "where it opens" setting plus sixteen call sites hard-coding `Tooltip.BESIDE` become one placement per tooltip type, chosen from a dropdown.

Types: bag item, action button, spell, worn gear, aura, world unit, unit frame, map pin, feed or list row, addon control. Each call to Tip.Open, Tip.Settle and Tip.Hang names its type in the argument that used to carry a placement word.

Placements: bottom right (the old dock), bottom left (its mirror), attached (the old beside; on the cursor for a world unit), anchor (the marker you drag). Defaults are what each hover did before, so nothing moves on upgrade.

The marker is shown and draggable while the Tooltips page is open, as well as with the frames unlocked.

A slider darkens the tooltip floor: a black layer over the palette's painting, 0 to 90 percent.

Gate: check.sh refuses `Tooltip.(DOCK|BESIDE|ANCHOR|RIGHT|LEFT|ATTACHED)` outside UI/Tooltip.lua and Settings/, so a call site names a type and never a place. Tooltip.Show asserts the type is known.
