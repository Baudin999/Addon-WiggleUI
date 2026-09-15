---
revision: 5
id: 01M2JN4F1SFN5CXCY5HPRQ2QNE
type: task
status: todo
title: "Pack a line by balancing its piles, with sections and dividers"
parent: 01M2JN4ESP53ET2Q080EAA8RJD
---

`Fit` and `Wants` in `Bags/Grid.lua` place a pile at up to min(count, columns) squares wide, narrow it to half, or start a new line. Replace them with a balanced line. Every pile on the line gets one more row, capped at floor(sqrt(n / 1.618)), until the line fits. A pile that still does not fit starts the next line.

Split piles join the line, each lane narrowed the same way.

ORDER gains sections and dividers, in the order Baganator ships for TBC: Session, divider, Hearthstone, Consumable, Quest, EQUIPMENT (Weapon, Armor, Gem), CRAFTING (Reagent, Trade Goods, Recipe), Projectile, Container, Quiver, Key, Misc, Other, divider, Junk, Empty. A section caption and a divider each start a new line. Only the bag window asks for them; the merchant rack does not.
