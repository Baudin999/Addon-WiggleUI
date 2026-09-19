---
revision: 5
id: 01M2WQY4EVFWMZS17W47VGSXT6
type: task
status: done
title: The character sheet wears its palette's painted backdrop
---

UI.Window's `backdrop` flag was ignored on a screen window (src/UI/Window.lua:225, `and not opts.screen`). The rule dates from when the character sheet filled the monitor. The sheet is half a screen now, so the flag should answer on its own.

- `backdrop = true` works on every window; the character sheet asks for it.
- A painted screen window gets no world wash: the floor is opaque, so the wash would only darken the painting.
- Cut what in UI/Window.lua no longer matches the code: the number branch of ZoomOf, which no window passes, and the comments describing the full-monitor sheet, the strip grip and the BACKGROUND strata.
