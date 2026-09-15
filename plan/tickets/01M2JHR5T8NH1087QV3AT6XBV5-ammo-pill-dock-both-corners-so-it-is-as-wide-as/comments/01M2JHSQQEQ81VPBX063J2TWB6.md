---
revision: 5
id: 01M2JHSQQEQ81VPBX063J2TWB6
---

Built in 9f298c5. PlaceAmmo docks TOP<portrait edge> to BOTTOM<portrait edge> and TOP<gauge edge> to BOTTOM<gauge edge> of entry.slot, both at (0, px). The width comes from the two docks and only the height is set, even. The icon is (tall-2) square on the portrait side. The number is anchored from the icon's far side plus AMMO_GAP to the pill's far edge less the padding, justified centre. AMMO_WIDEST and the 9999 cap are deleted because both existed only for the measured width. Gate: harness 10-ammo-pill asserts two points, both corners on the portrait square, offsets 0 and 1 px, and draws 12000 in full. Not yet seen in the client. Still open from the last card: a long player debuff row runs under the pill.
