---
revision: 5
id: 01M2XF9KBQDY5DAJDPT7M1Q79E
type: task
status: todo
title: "48 and 49 hand UIParent back at 0 by 0, not the size it had"
---

`harness/sections/48-tooltips.lua:283`, `:796` and `49-world-hover.lua:287`
call `UIParent:SetSize(0, 0)` to "hand the screen back". That was right when
the stub stood UIParent up with no size. `02-text.lua:646` now gives it the
screen's size, so every section after 48 runs on a zero-size screen.

Found by 76-adhoc: a frame SetAllPoints to UIParent answered no cursor.
76 works round it by sizing the screen for its own checks and putting back
what it found.

Fix: save the width and height before the SetSize and restore them. Then
drop the workaround in 76-adhoc and run the whole harness, since every later
section changes ground.
