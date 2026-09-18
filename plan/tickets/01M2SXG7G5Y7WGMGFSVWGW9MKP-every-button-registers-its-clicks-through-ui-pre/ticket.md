---
revision: 5
id: 01M2SXG7G5Y7WGMGFSVWGW9MKP
type: task
status: done
title: Every button registers its clicks through UI.Press.Clicks
---

Seventeen files called `RegisterForClicks` by hand on buttons that are not secure action buttons: the three bound-key buttons (Marking/Keys.lua, Perf/Key.lua, Dungeons/Key.lua), the secure unit buttons (UnitFrames/Group.lua, UnitFrames/Skin.lua), and rows and squares in Widgets, Window, Mail, Meter, Quests/Column, Merchant, Sockets, Bags/Belt and Talents/Board. Each spelled its own button names and edge suffix.

Which buttons a frame answers is the question UI.PassCamera has to ask before it hands a button to the camera, and it had no place to ask it. That is the next card.

UI/Press.lua: `Press.Clicks(button, edge, ...)` goes through the same `Register` that `Press.Button` does, one edge word and the button names.

Gate: check.sh fails on a `:RegisterForClicks(` call outside UI/Press.lua.
