---
revision: 5
id: 01M2WTXY7EJFMXKK9PC6K7DXWH
type: bug
status: done
title: A painted window's footer is written over its bottom corners
---

The bag window's "26 free of 68" and purse ran into the arcane frame's bottom corner ornaments. `Footer` in `src/UI/Window.lua` anchored the footer and its rule at `M.pad` (12), and the corner reaches `corner - thickness` (63 - 23 = 40) into the window.

Fix: `Backdrop:Reach(side)` in `src/UI/Backdrop.lua`, and a painted window's footer and rule start at `max(M.pad, reach)` on each side. Bags and character sheet are the two painted windows.
