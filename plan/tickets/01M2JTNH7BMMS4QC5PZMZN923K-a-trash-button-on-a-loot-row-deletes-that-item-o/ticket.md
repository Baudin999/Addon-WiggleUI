---
revision: 5
id: 01M2JTNH7BMMS4QC5PZMZN923K
type: task
status: done
title: A trash button on a loot row deletes that item on every future drop
---

A second button on a loot feed row, beside the cross: delete this item now and every time it drops again.

Asked for on 2026-09-15: grinding, put items on a "delete automatically" list so the cross is not pressed every time. It has to be visually clear that a delete list exists, and one button in the top strip empties the list, up only while there is one.

Where. The list is per character in ns.dbc, keyed by item id. Feeds/Loot.lua refuses a listed item at the door and counts it. UI/Feed.lua gets a generic row action and a strip control, and Feed:Remove becomes Feed:Sweep(match) so one press can take out every held row of that item.

Gate. A new harness section: the press lists the item and sweeps its rows, a later drop of it makes no row, the strip control appears with the count, and pressing it empties the list.
