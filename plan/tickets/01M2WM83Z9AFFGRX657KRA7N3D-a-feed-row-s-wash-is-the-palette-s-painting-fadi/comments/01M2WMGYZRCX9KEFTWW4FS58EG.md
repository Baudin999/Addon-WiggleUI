---
revision: 5
id: 01M2WMGYZRCX9KEFTWW4FS58EG
---

Cause. The row wash was a flat C.shadow ramp on a white texture.  Fix. 0710ae6: UI.Wash takes an optional file; under a palette with a painting each row washes with its Middle tile, tinted 0.45 grey at the shadow's 0.55 alpha, and UI.FloorBand cuts the band at the row's depth so the stack is one painting. A row wider than the tile stretches the tile instead of repeating it; a band that would run off the tile's foot is lifted to end on it. Dark keeps the flat ramp.  Gate. 88-theme-backdrop asserts file, ramp and band arithmetic. Not yet seen in the client: whether SetGradient ramps a file texture on 2.5.6 is the open question, and 0.45 is a guess against the desert tile.
