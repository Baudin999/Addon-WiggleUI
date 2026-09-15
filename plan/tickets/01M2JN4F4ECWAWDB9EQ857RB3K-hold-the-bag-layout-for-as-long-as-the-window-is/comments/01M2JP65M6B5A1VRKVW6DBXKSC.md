---
revision: 5
id: 01M2JP65M6B5A1VRKVW6DBXKSC
---

Landed in c03f142. Grid.Paint calls Keep on every fresh layout, not only at a merchant. Lay writes button.laid = group.key, and Hold returns false when a held slot holds an item whose group differs. Window.lua hooks OnHide to Grid.Release, so escape and the cross let go too. 74-bag-hold covers the hold with no merchant open, holes kept after the vendor closes, and the next open closing them. Gate at zero.
