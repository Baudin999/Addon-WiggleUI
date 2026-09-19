---
revision: 5
id: 01M2XENMJJMHKCHW1M49FZDC9V
type: task
status: todo
title: "A bar you made is a ring: push toward a spell, let the key go"
---

Every ad hoc bar becomes an OPie-style ring on its own held key.

- The ring opens in the middle of the screen, squares on a circle, up to 16.
- Hold the key, push the mouse toward a square, let go: that square fires.
- Direction only. The pick is the angle from where the cursor stood when the
  key went down, so the cursor never has to reach the middle. The client has
  no call that moves the cursor; every `SetCursorPosition` on disk is an edit
  box caret.
- Let go inside the dead zone and nothing fires.

Mechanism, read off the installed OPie (`OPieCore.lua:236`, `:553`,
`ORL_PerformSliceAction`): a restricted snippet reads `GetMousePosition` off a
hidden full-screen frame, turns the angle into a slice, and writes that
slice's action onto the button the key clicks. The release is the hardware
event, so the cast is allowed in combat.

2.5.6 `SecureActionButton_OnClick` (Gethe/wow-ui-source classic_anniversary,
`Blizzard_FrameXML/SecureTemplates.lua:799`): with `useOnKeyDown` false the
up edge is the click action, the down edge does nothing. So the key is an
action button registered on both edges, and a wrapped OnClick pre-body shows
the ring on the down edge and arms the key on the up edge.

Goes away: the drag grip, the saved position, `/wk adhoc reset`, columns,
and "put the bar away after a press". A ring always goes away on release.
