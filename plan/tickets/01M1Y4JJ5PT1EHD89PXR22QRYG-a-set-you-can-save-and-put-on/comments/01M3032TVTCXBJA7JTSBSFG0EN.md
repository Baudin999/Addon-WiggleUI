---
revision: 5
id: 01M3032TVTCXBJA7JTSBSFG0EN
---

Landed at 6b5cb292. ./scripts/check.sh at zero.

Three files rather than the card's four: Sets.lua is the model and the readers, Wear.lua is the plan and the queue, Feature.lua is the slash words and the gearSets charDefault. The card's Key.lua is twenty lines and is the one thing Sets.lua is about, so it lives there.

The whole contract shipped under the names it was written down with, and the page branch compiled against them unchanged. Beyond it: Sets.Plan, Sets.World, Sets.Slots, Sets.Label, Sets.Key, Sets.Describe, Sets.Running.

Two things the next reader would otherwise re-derive.

The reservation is two flags, not one. A worn slot that is already right may not be a source; a worn slot whose piece has been promised elsewhere may still be a target. One flag for both makes two rings trading places come out as a move and a half and a spare bag slot instead of lift 11, drop 12, drop 11. The section caught it on its first run.

The key's id comes off ns.ItemKind, not off field 2 of the link. The harness writes every fixture link as |Hitem:1: and keeps the real id in the fixture table, so a key read straight out of the string keys every item alike and every scene passes for the wrong reason.

Found at the merge and fixed there: Sets.Put refuses an item ns.Gear.Replaces says does not land in the slot. That is right and it is where the refusal belongs, but 52-set-page had been written against a store that accepted anything, so the page section dropped a chest on a head slot and read the refusal as a drawing bug.
