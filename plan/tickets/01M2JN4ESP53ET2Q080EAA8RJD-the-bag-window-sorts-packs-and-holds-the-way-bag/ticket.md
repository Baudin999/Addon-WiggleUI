---
revision: 5
id: 01M2JN4ESP53ET2Q080EAA8RJD
type: feature
status: todo
title: "The bag window sorts, packs and holds the way Baganator's does"
---

Baganator's category view looks and feels better than ours. The reason is three mechanisms, not its art, and we keep our black squares and our icons.

1. Inside a pile it sorts on what an item is: class, equip slot, subclass, item level, quality, then name. Ours sorts on quality and then name, so a green belt sits beside a green sword.
2. It packs a line by balancing it. Each pile already on the line wraps one row taller, up to a golden-ratio block, before a new pile is pushed down. Sections and dividers force a new line. Ours fills a line greedily.
3. It holds the layout for as long as the bag is open. A removed item leaves a hole. Closing lets go. Ours holds only at a merchant.

It also has a Gem pile. On 2.5.6 ours files gems under Other.

The mechanisms are written from a description of what Baganator does. None of its code is copied.
