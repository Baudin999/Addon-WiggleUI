---
revision: 5
id: 01M2JVDXFMNEXD5M7JMJSWRSGS
type: task
status: todo
title: "Delete on a loot row destroys the item in the bags, not only the row"
---

The loot feed's cross and can take a row off the feed and leave the item in the bags. The user expected delete to delete: "the delete button does not always delete the item from the bag, just from the list" (2026-09-15). The "sometimes" is Comfort/Leftovers.lua destroying what the loot filter refused when lootDestroy is on.

Fix. Both buttons destroy what the row counts from the bags, split off the stack the way Leftovers does, and a listed item is destroyed as it arrives. One destroy path: Leftovers grows an entry point the feed owes counts through, under its guards (never blue and up, never a quest item, five second staleness), and the group's drops are never owed.

Gate. Harness: a press destroys the row's count and leaves the rest of the stack, a listed drop is destroyed on arrival, a blue row is not destroyed.
