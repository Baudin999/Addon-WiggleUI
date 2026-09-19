---
revision: 5
id: 01M2WMVQ088CZB9FXGNF1EK0WT
---

Cause. The tooltip (src/UI/Tooltip.lua) drew only a flat fill, and its shadow was a rectangle on BACKGROUND -8, the floor's own sublevel.  Fix. 928488f: UI.Ground in src/UI/Backdrop.lua lays the palette's floor alone at GROUND_SCALE 0.5 under a small surface and sends its flat fill to nothing; the dark palette keeps the fill. Tooltip Layout calls it at the size it sets; the purse panel takes it the same way. The shadow is now the two strips outside the box.  Gate. 88-theme-backdrop opens a tip under forest and under dark.
