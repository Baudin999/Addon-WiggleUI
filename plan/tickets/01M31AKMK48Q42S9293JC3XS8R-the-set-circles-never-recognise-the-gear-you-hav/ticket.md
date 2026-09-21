---
revision: 5
id: 01M31AKMK48Q42S9293JC3XS8R
type: bug
status: todo
title: The set circles never recognise the gear you have on
parent: 01M1Y4JDFMVHEB87QK9R1KP4BJ
---

Every circle under every row draws at full strength, which the page means as
"this piece of the set is not on you". It says that about gear you are
standing in.

## Cause

`PaintCircle` at `src/Character/SetRow.lua:424`:

    local on = link ~= nil and link == worn

Two raw item links, compared as strings. `uniqueId` moves when an item moves,
which is the reason `Sets.Key` exists at all, and `52-sets.lua:130` asserts it
with a `plain` and a `moved` link that differ in that one field. `Standing`
(`Wear.lua:95`) and `Sets.Wearing` (`Sets.lua:497`) both compare keys. This one
line does not.

The window repaints on UNIT_INVENTORY_CHANGED, PLAYER_EQUIPMENT_CHANGED and
BAG_UPDATE (`Character/Window.lua:448`), so the first time anything touches
your gear after a capture, all nineteen circles light up together.

That is the page's headline reading gone: a glance down the near edge after a
swap is supposed to stop on the circles that disagree with the disc above them,
and today every circle disagrees.

## The fix

Compare `ns.Sets.Key(link)` against `ns.Sets.Key(worn)`. The worn link is
already handed in, so nothing else moves.

## The gate

`52-set-page.lua:278` asserts the dim state and passes, because the stub hands
back the same link string every time. The scene has to move the `uniqueId` on
the worn link between the capture and the repaint, the way the game does.
