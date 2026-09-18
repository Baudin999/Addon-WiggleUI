---
revision: 5
id: 01M2SKHEB1SM4JDKY9FPFEH3ZG
type: task
status: todo
title: "Mouseover casting is one page, with its on-screen list on it"
---

Mouseover casting was two sections under Fighting: the keys, and a page called "The list on screen" with the list's switch, background, size and reset. Somebody looking for the list's size opened Mouseover casting and did not find it.

Fold the second into the first, in src/Hover/Panel.lua, under a divider after the keys. Label the rows so they say what they size: "show the list on screen", "list background", "list size".

Out of scope: the same size setting is also a row on "Zoom: on screen" through the `zooms` registry in src/Hover/Feature.lua:96. That is the zoom-pages move and gets its own card.
