---
revision: 5
id: 01M31AMXD1Q58CE4BJ8Q1M8FHP
type: task
status: todo
title: "A set on a bar, as a macro square"
parent: 01M1Y4JDFMVHEB87QK9R1KP4BJ
depends: [01M31AK99MY4K51D0XX9YM59SD]
---

Drag a set onto a bar and press it there. One mechanism in both places, and the
mechanism is a macro.

## What lands

A set carried out of the toggle stack on the character page drops onto an ad
hoc bar as a macro square whose body is one line:

    /wui set wear Bling

`AdHoc/Bars.lua:507` already writes `macrotext` on a square for an item, so a
set is the same move with a different line. `AdHoc.Carry`
(`AdHoc/AdHoc.lua:143`) grows a fourth kind beside spell, item and macro, and
the record carries the set's name and whatever `PieceArt` or `ns.SpecArt`
already draws on its toggle.

Blizzard's own action bars hold spells, items and macros and nothing an addon
can invent, so there the answer is the same line pasted into a macro. The
toggle's hover offers it ready to copy, which is one sentence on a box that
already has three.

## Why a macro and not a set square

A macro square needs no new attribute, no new press path and no secure button,
because nothing in a gear swap is protected. It also means the bar's own
keybinding is the key on the set, so the per set key in
`01M1Y4JJCMRCGEMB0DT4MET6W7` does not need writing: bind the square.

The one cost is that renaming a set breaks the macro text pointing at it.
`Sets.Rename` should walk the ad hoc bars and rewrite the line, which it can do
because the bars are ours.

## Testing it in game

Drag a set onto an ad hoc bar, bind the square, press the key standing still
and watch the set go on. Rename the set and press the key again. Then paste the
line into a Blizzard macro and confirm it does the same thing.

## The gate

Extends `76-adhoc.lua` and `52-set-page.lua`. A set dropped on a bar writes a
macro square carrying the right line, a renamed set leaves no square pointing
at a name nobody has, and a set forgotten while a square points at it leaves a
square that refuses with a sentence rather than one that does nothing.
