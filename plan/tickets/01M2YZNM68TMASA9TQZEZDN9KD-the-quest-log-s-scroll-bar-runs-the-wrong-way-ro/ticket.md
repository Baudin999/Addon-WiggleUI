---
revision: 5
id: 01M2YZNM68TMASA9TQZEZDN9KD
type: bug
status: doing
title: The quest log's scroll bar runs the wrong way round
---

Reported from the game: in the quest window the bar "does not scroll well, up
is down and down is up". Which of the three columns and whether it is the drag
or the wheel is not known yet; both go through the same view.

What was ruled out first, so nobody re-derives it:

- All three columns are `UI.ScrollView` (`src/Quests/Window.lua:869`), and so
  is every other window in the addon. Nothing in Quests/ handles the wheel or
  owns a bar of its own.
- The client picks the clipping path, not the ScrollFrame one:
  `SetClipsChildren` is a real method on 2.5.6, OPie calls it in five places on
  this install. So `Viewport` returns the anchor mover.
- The anchor mover is the right way round. A run under the harness moves the
  canvas from 0 to +200 on `ScrollTo(200)`, which in the client's coordinates is
  the canvas going up and the content below coming into the port.
- The slider convention is the right way round too. A vertical Slider's thumb
  runs from the minimum at the top to the maximum at the bottom, which is what
  LibQTip does on this install (`SetVerticalScroll(self:GetValue())`, wheel down
  raises the value) and what AceGUI's pullout does. `View:Update` writes
  `SetMinMaxValues(0, room)` and `SetValue(offset)`, offset 0 at the top.
- The wheel handler subtracts a positive delta, so wheel up scrolls up.

The one wrong sign in the file is in a branch nothing reaches:
`UI/Scroll.lua`'s ScrollFrame fallback calls `scroll:SetVerticalScroll(-offset)`
where LibQTip proves the client wants `+offset`. It is only taken on a client
with no `SetClipsChildren`, which is neither of ours, so it cannot be what was
seen in the game. Fix it anyway when this card is picked up.

So the next step is one answer from the game: which column, and does the
content go the wrong way when the thumb is dragged, when the wheel is turned,
or both.
