---
revision: 5
id: 01M31AK99MY4K51D0XX9YM59SD
type: bug
status: todo
title: Pressing a set does not swap any gear
parent: 01M1Y4JDFMVHEB87QK9R1KP4BJ
depends: [01M31BW0V6GET4YTV6YXJTFM85]
---

Pressing a set on the character page moves nothing. The run starts, every slot
it touches is picked up and put back, and the gear ends exactly where it was.

## Cause one: `stow` cancels the pickup instead of filling a bag

`src/Sets/Wear.lua:486` runs the `stow` operation as `Ask("ClearCursor")`.
ClearCursor cancels a pickup and hands the item back to the slot it was never
really taken out of. `Core/Sockets.lua:235` says so in as many words, and Core
already carries the call this wants: `ns.Stow` at `Core/Core.lua:1677`, which
is `PutItemInBackpack`, then `PutItemInBag` per bag, with a look at the cursor
between each one.

So every `lift` followed by `stow` is a no-op. That is the whole of `Strip`
(`Wear.lua:200`), which is the half of a set that takes a piece off you, and
the whole of `Displaced` (`Wear.lua:229`), which is the shield a two hander
pushes out.

It is worse than a wasted round trip, because `Room` (`Wear.lua:313`) counts a
stow as spending a bag slot. The live set on Kibbling holds slot 2, 13 and 14
as deliberately empty, so every press plans three lift and stow pairs, asks for
three free bag slots, and refuses outright with "needs 3 free bag slots to swap
into" when the bags are tight.

## Cause two: a skipped gesture stalls the queue for the session

`Step` (`Wear.lua:504`) only ever runs from ITEM_LOCK_CHANGED or BAG_UPDATE,
and there is no ticker by design. When `Fresh` refuses a gesture, `Skip` moves
the cursor past it and returns without making a single client call, so nothing
fires the event that would resume the run.

`running` then stays set forever. `Stop` is never reached, the deadline is
never read, no line is printed, and every later `Sets.Wear` answers "X is still
going on" until a reload. If the first operation is the one that fails, the run
dies inside the synchronous `Step()` in `Sets.Wear` and nothing happens at all.

The fix is a fall through: `return Step()` after `Skip`.

## And a refusal nobody reads

`Sets.Put` answers `false, "%s does not go in the %s slot."`. All three callers
throw it away: `SetRow.lua:217`, `:253` and `:293`. Drop a helmet on a ring
circle and the page does nothing and says nothing.

## Testing it in game

Save a set with the neck deliberately empty while wearing a neck. Press it.
The neck stays on today. Then press a set whose pieces are in the bags and
watch whether anything lands.

## The gate

`52-sets.lua` drives the planner and never the queue, which is why all of this
shipped. It needs a queue scene: a stow has to leave the cursor empty and the
bag one fuller, and a gesture refused by `Fresh` has to leave the run advancing
rather than stopped.
