---
revision: 5
id: 01M2Z0B6YTHSSRRYTPFH53GN9M
type: task
status: doing
title: The ad hoc page names a bar first and shows the ring
---

The page you design an ad hoc bar on (`src/AdHoc/Panel.lua`) is hard to read
and harder to start. Three things are wrong with it.

**Making one is a `+` and a guess.** The plus on the tab strip calls
`ns.AdHoc.Add()` with no name, which invents `Bar 3`, selects it, and leaves
you to find the name field further down the page and type over what it
invented. Nothing asks what the bar is for, which is the one thing you know
when you press the plus.

**The picture is not the thing.** The squares are drawn as a wrapped line
while the bar on screen is a ring: square one at twelve, the rest clockwise,
the radius growing with the count. A line cannot show where the push goes, so
the page teaches an order that the gesture does not use.

**The gestures are already there and nothing says so.** Drag between two
squares moves, drag off the line removes, right click removes. All three work
today and the hint under the row mentions none of them.

## Wanted

- The plus asks for a name. One window, reused, the sibling of `UI/Ask.lua`
  and `UI/Amount.lua`: `UI.Name` in `src/UI/Name.lua`, with a field, an accept
  and a cancel. Enter accepts. Nothing is added until it is answered, so a
  bar exists only once it has been called something.
- The squares sit on the circle the ring draws, at the ring's own geometry
  scaled to the page: `AdHocBars.Radius` and `AdHocBars.SIZE` are exported and
  the page multiplies by one number, so the two pictures cannot drift.
- The empty square you drop onto sits in the middle of the circle, where the
  ring draws the name of what you are aiming at. The circle stays exactly the
  circle the game draws; the middle is the only thing the page adds.
- The hint says the three gestures.

`UI.Name` needs a text field, and a text field is `CreateFrame("EditBox")`
plus six scripts written out eight times in this addon. So the box comes out
into `UI.Field` in `src/UI/Widgets.lua` first, with `ui.TextField` migrated
onto it in the same commit. The other six copies are a card of their own.

## Done when

- Pressing `+` with no name typed adds no bar.
- A bar named in the window is on the strip, selected, with the name on it.
- The page's squares are at the ring's own angles and its own radius over
  `SIZE`, asserted in `76-adhoc.lua` against `AdHocBars` rather than against
  numbers typed twice.
- `./scripts/check.sh` at 0 warnings, 0 errors.
