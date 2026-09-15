---
revision: 5
id: 01M2JH360NG5RT4VFC58TW4EE6
type: task
status: done
title: "Ammo pill: drop it onto the bottom edge and put the arrow icon on it"
parent: 01M2JFZRDAXDJT8RD2809SDK6S
---

Seen in the client on 2026-09-15: the pill sits on the portrait's chin and reads as a bare number.

- Move it down so it straddles the block's bottom edge, still in the portrait's corner on the gauge side.
- An icon at the pill's left: the ammo's own art (GetInventoryItemTexture on slot 0), the thrown stack's art for a stacking thrown weapon, and the ranged weapon's art when the ammo slot is empty.
- Harness 10-ammo-pill asserts the icon for each case and the drop below the portrait.
