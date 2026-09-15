---
revision: 5
id: 01M2JYYPCZ1K961E4WXW19YG31
type: task
status: done
title: "A double click on a loot row's delete destroys one item, not two"
---

A mouse that bounces clicks twice, and the loot feed's cross and can destroy two stacks: the first press takes the row out, the next entry moves up under the same button, and the second press destroys that one too.

Asked for on 2026-09-15: "if someone because of a mouse failure, clicks twice, we do not delete 2 items."

Fix. Comfort/Destroy.lua already refuses a second take inside DEBOUNCE = 0.4, as its own local. Move that guard into UI.Button as an option, have the clutter window's button use it instead of its own copy, and give the feed's row buttons the same option.

Gate. Harness: two presses of a row's cross inside the window destroy once and take one row; a press after it takes the next. The clutter window's own section still passes.
