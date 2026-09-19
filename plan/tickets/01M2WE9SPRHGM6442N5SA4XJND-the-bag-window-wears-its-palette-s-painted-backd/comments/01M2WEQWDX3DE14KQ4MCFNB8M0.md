---
revision: 5
id: 01M2WEQWDX3DE14KQ4MCFNB8M0
---

Landed in dcb0213. Cause of the one false start: the floor under the top rail carries the rail's painted drop shadow, so a tile cut at the inset showed a dark band on every row. The bake cuts CLEAR (40 px) further in and rolls the tile back, which keeps the phase. An automatic frame mask (pixels that match one period away are floor) failed because the rails repeat at the floor's period too; the insets are measured by hand in the PAINTINGS table. Tiling is a grid of plain textures, not SetHorizTile, because the client tiles those at the texture's own pixel size. Gate: Theme.lua asserts nine pieces per painting and that each names a listed palette; 88-theme-backdrop checks tile count, the last tile's cut and the shrink. Not yet seen in the client. A new desert painting means re-measuring its inset, corner and period, then re-running the bake.
