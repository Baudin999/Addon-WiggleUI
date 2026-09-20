---
revision: 5
id: 01M2Z3YJ54X56DDM74Y5M1EPXD
---

Landed at 65183045. Ring.lua is the drawing, Bars.lua and Panel.lua both go through it.

Cause of the two bugs found while looking at it. The ring was drawn at the middle of the screen and the push was measured from where the cursor stood when the key went down, so the slice you were over and the slice that fired were rotated apart by the gap between them, and a cursor resting on the drawn hole was a push as long as that gap and cast. Nothing about that was visible while the ring drew no slices.

Fix. PICK re-anchors the ring on the press, inside the snippet because an addon may not move that frame in a fight, and Arrange writes the UIParent unit in the ring's units onto wk-scale for it. Not clamped to the screen on purpose: clamping the ring without clamping the point the push is measured from puts the picture and the arithmetic back out of step, which is the bug. If the overhang at a screen edge matters, clamp the start point too and move both.

Ruled out. The mask arithmetic was not the offset. UI.Wedge's two rotations were checked against OPie's Mirage.lua spiral on this client and against UI.Sweep's two ends before anything was changed, and 76-adhoc now reads the facing back out of the rotations so a sign error fails there rather than drawing backwards.

Gate. ./scripts/check.sh at 0 warnings, 0 errors, harness ok, through the pre-commit hook.
