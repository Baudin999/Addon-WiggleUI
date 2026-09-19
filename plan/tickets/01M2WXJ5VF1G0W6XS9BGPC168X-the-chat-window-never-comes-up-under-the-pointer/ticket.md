---
revision: 5
id: 01M2WXJ5VF1G0W6XS9BGPC168X
type: bug
status: done
title: The chat window never comes up under the pointer in exploration
---

In the exploration theme the chat window is "hover" (src/Theme/Themes.lua) and stayed invisible however long the pointer sat on it.

UI.Reveal (src/UI/Veil.lua) found the pointer with a catcher at the frame's own level, under every child. The chat window is its rail, its lines and its entry edge to edge, so the pointer always landed on a child and the catcher's OnEnter never fired.
