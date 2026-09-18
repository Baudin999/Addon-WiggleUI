---
revision: 5
id: 01M2SXPVV41JSXXZMQKJBMZNXV
type: task
status: done
title: UI.PassCamera hands the camera only what a frame does not keep
---

`ns.Tip.Hang` called `UI.PassCamera`, which handed RightButton and MiddleButton to the camera on every frame, including frames that answer the right button. A button handed on never reaches the frame's scripts, so on a client with SetPassThroughButtons a right click turned the camera instead of acting: Mail/Window.lua's rail rows and attachment slots, Meter/Window.lua's rows, Dungeons/Window.lua's rows. The frames that got it right did so by skipping the pass and writing a paragraph on why: Buttons/Square.lua, Bags/Grid.lua, UnitFrames/Skin.lua, UI/Window.lua's list rows.

UI/Press.lua now holds the pass. Register records what a button keeps, `Press.Keep(frame, ...)` says it for a frame that reads the button in OnMouseUp, and `UI.PassCamera` hands on only the camera's buttons the frame does not keep, in either order. A frame that keeps both is never written to. UI.HoverOnly moves with it.

Gate: check.sh fails on SetPassThroughButtons or SetMouseClickEnabled in code outside UI/Press.lua. 04-ability-square drives the order both ways with a recorder in place of the stub's raising SetPassThroughButtons.
