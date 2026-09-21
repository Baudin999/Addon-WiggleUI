---
revision: 5
id: 01M31AM52HJ1XBNRTTSNT3M4KB
type: task
status: done
title: In a fight a set swaps the weapons and nothing else
parent: 01M1Y4JDFMVHEB87QK9R1KP4BJ
depends: [01M31AK99MY4K51D0XX9YM59SD]
---

Press a set in a fight and the weapons go on. Nothing else moves, and nothing
is said about it.

## What lands

`Allowed` (`src/Sets/Wear.lua:537`) refuses the whole run when any operation
touches a slot the fight holds shut. That is the wrong answer. The press drops
every operation on a slot `Worn.Free` refuses, keeps the rest, and runs.

Slots 16, 17 and 18 are the three the fight allows, and `Worn.Free`
(`Character/Worn.lua:463`) already holds that rule per slot.

The line at the end counts what it did and says nothing at all about the slots
it dropped. We are WoW players. Everybody knows armour does not change in a
fight, and a sentence explaining it every time you press a weapon swap mid pull
is noise.

## Not the design in phase 4

`01M1Y4JJCMRCGEMB0DT4MET6W7` says the rest is held and finished on
PLAYER_REGEN_ENABLED, with a line saying how many pieces are waiting. That is
overruled. A set half applied thirty seconds later, when you have already moved
on, is worse than a set that did the two things you asked for and stopped.

Dropping operations rather than deferring them also keeps the queue a single
state machine, which is the argument the file header already makes.

## The arithmetic moves with it

`Room` and `Touched` are counted off `plan.ops` (`Wear.lua:313` and `:333`), so
the refused operations have to come out of the plan before those run, not at
the moment the queue reaches them. Otherwise a press in a fight asks for bag
room to stow armour it is never going to lift.

## Testing it in game

Pull something. Press a set that names a two hander and nineteen pieces of
armour. The two hander lands, the armour does not, the line says what changed
and mentions no armour. Let the fight end and confirm nothing lands late.

## The gate

Extends `52-sets.lua`. A plan made in combat carries only the hands and the
bow, its room figure is the room those need, and the refused slots are absent
from the plan rather than absent from the run.
