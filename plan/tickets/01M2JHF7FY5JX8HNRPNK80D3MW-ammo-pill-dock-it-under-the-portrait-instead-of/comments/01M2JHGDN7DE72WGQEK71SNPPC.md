---
revision: 5
id: 01M2JHGDN7DE72WGQEK71SNPPC
---

Cause. PlaceAmmo anchored the pill BOTTOMRIGHT to the portrait texture and dropped it by -(tall/2 - 1) px. That is a computed offset off the pill's own height, and in the client it still read as floating over the portrait. Fix, in d87a258: the pill's TOP<gauge edge> is anchored to entry.slot's BOTTOM<gauge edge> at (0, px). The pill hangs under the block like a tab and shares the bottom hairline. AMMO_INSET is deleted. Gate: harness 10-ammo-pill asserts TOPRIGHT to BOTTOMRIGHT of the portrait square and an offset of 0 across, 1 px up. Open: the player debuff row also hangs under the block, starting at the gauge end and growing toward the portrait. A long row would run into the pill. Not yet seen in the client.
