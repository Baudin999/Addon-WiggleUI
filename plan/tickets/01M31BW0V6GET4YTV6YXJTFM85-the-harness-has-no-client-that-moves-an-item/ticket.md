---
revision: 5
id: 01M31BW0V6GET4YTV6YXJTFM85
type: task
status: done
title: The harness has no client that moves an item
parent: 01M1Y4JDFMVHEB87QK9R1KP4BJ
---

The gear set queue cannot be gated, because the harness has no client that
moves an item. That is why a run which does nothing at all shipped green.

Do this first. Both gear set bugs under `01M1Y4JDFMVHEB87QK9R1KP4BJ` ask for a
queue scene and neither can have one until this lands.

## What is there now

`scripts/harness/client/13-character.lua:139` counts and moves nothing, and
says so on purpose:

    _G.PickupInventoryItem = function(slot)
        moved.picked[#moved.picked + 1] = slot
    end

The comment above it argues that a stub which shuffled items between bag and
slot would be modelling the server. That was right when the only question was
whether the page called at all. It is wrong now: `Sets/Wear.lua` is a queue of
cursor operations whose whole correctness is where the items end up.

The cursor itself is already real. `05-quests.lua:252` answers `GetCursorInfo`
off one upvalue, `PickupContainerItem` at `:331` loads it from a bag slot, and
`PutItemInBackpack` and `PutItemInBag` at `:401` and `:406` already walk the
bags for a free slot.

## What lands

Four calls that agree with each other about one cursor.

**`PickupInventoryItem(slot)` swaps.** With an empty cursor it takes the worn
item onto the cursor and leaves the slot bare. With an item on the cursor it
equips that item and puts the one that was there onto the cursor. It keeps
appending to `moved.picked`, because `52-character.lua` and `52-gear-page.lua`
read that list and must go on passing.

**`ClearCursor` returns the item where it came from.** That is what the call
does, `Core/Sockets.lua:235` says so, and it is the exact behaviour the queue
is currently wrong about. A stub that quietly dropped the item would let the
bug under test pass.

**`stow` takes a cursor item that came out of a worn slot.** `05-quests.lua:384`
refuses anything without `cursor.bag`, so a piece lifted off your body has
nowhere to land today. The free slot has to come from a bag whose family is
nought, because `Sets.World` only counts those as room and a quiver must not
swallow a helmet.

**Every one of the four fires the event the client fires.** ITEM_LOCK_CHANGED
on a pickup and a put down, BAG_UPDATE on a bag slot changing. The queue is
driven by those two events and nothing else, so a stub that moved items in
silence would test the plan and never the queue.

## What this makes possible

A section can then stand a character in one set, press another, run the events,
and assert where all nineteen pieces ended up. That is the assertion neither
bug card can write today.

## The gate

`52-sets.lua` grows a queue scene beside its planner scenes. The two bug cards
add to it rather than building their own.
