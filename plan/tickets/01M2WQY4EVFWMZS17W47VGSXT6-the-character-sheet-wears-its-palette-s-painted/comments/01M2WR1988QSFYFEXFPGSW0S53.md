---
revision: 5
id: 01M2WR1988QSFYFEXFPGSW0S53
---

Landed in 7a2abe7. Cause: Surface in UI/Window.lua refused a backdrop to any screen window, a rule left from the full-monitor sheet. Fix: backdrop answers on its own; the sheet passes backdrop = true. A painted screen window skips the wash, because the floor is opaque and the wash only darkened the painting, so characterDim does nothing under a painted palette. Any screen window must also be secure: Placeable asserts a grip belongs to a snippet-dragged frame. Gate: 88-theme-backdrop, both screen cases.
