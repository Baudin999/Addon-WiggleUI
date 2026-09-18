---
revision: 5
id: 01M2T6Y68PWB4QFFFHWH66S0R0
---

Landed bf8d9be. Bound.Hold and Bound.Drop are the only override calls; Bound.Keys is the several-keys loop Marking and Cast shared. The hover /use path runs through Bound.Keys like a spell; only the macro verb differs, on the same Press.Button down edge. Edge audit: every bound button was already a Press button with matching edges. One dead path found: Press.Edge fell back to ActionButtonUseKeyDown for a plain Press.Clicks "up" button, so a hover macro's /click onto the frame report or dungeon log key went out on the press and was dropped. Press now records wkEdge and Edge reads it first. Hold refuses a button without it. Gate: check.sh fails on SetOverrideBindingClick, ClearOverrideBindings or heldAny outside UI/Bound.lua, and on wkEdge outside Press and Bound. 31 hits on the old HEAD, 0 now.
