---
revision: 5
id: 01M2Z1ASEFJD2BAPT0Y8N69APC
type: task
status: todo
title: "The ring opens wider, and a push has to reach it"
---

Three changes to the ring an ad hoc bar draws, asked for after
01M2Z0B6YTHSSRRYTPFH53GN9M put the circle on the page where it can be seen.

**It is too tight.** The circle is `math.floor(SIZE * 1.6)`, 86 units, hard
coded in `src/AdHoc/Bars.lua`. Sixteen squares widen it to 186 by the packing
term beside it, but the four or five squares anybody actually puts on one of
these sit in a cluster in the middle of the screen.

**The dead zone is 20 units and it should be the ring.** `DEAD` refuses a
release that has travelled less than 20 units from where the key went down,
which is there to refuse a thumb letting go of a key it pressed by mistake.
It means a release two centimetres from the start casts whatever square that
direction happens to point at, while the squares are drawn far further out
than that. The picture says push out to a square; the arithmetic says twitch.

**Neither number is the player's.** `adhocZoom` scales the whole ring, icons
and all. How far out the squares sit is a separate question and there is no
way to answer it.

## Wanted

- `adhocRadius`, in `ns.db`, the circle a ring starts at. The packing term
  stays as a floor under it, because two squares overlapping is not a setting
  anybody chose. A row on the ad hoc page, `adhoc radius <n>` as a word, and a
  reading saying what the shown bar's circle actually came out at.
- The pick's dead zone is the inner edge of the squares, `Radius(count)` less
  half a square, converted into the units the snippet measures the push in. A
  release that never left the middle of the ring casts nothing.
- One number, computed once per apply and written onto the ring as an
  attribute, so the snippet and `Bars.Wedge` read the same one. The snippet
  cannot call Lua and this is the second thing it would have to be told twice.

## Done when

- A push short of the squares casts nothing and lights nothing, asserted in
  `76-adhoc.lua` against `Bars.Reach` rather than a number typed there.
- A push that reaches them casts, at the ring's default and after the radius
  has been moved.
- `./scripts/check.sh` at 0 warnings, 0 errors.
