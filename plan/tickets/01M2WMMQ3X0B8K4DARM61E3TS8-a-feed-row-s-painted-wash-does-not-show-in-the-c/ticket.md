---
revision: 5
id: 01M2WMMQ3X0B8K4DARM61E3TS8
type: bug
status: todo
title: A feed row's painted wash does not show in the client
parent: 01M2WM7H2QD0KYVCRBZZ25T564
---

0710ae6 paints each loot feed row's wash with the palette's Middle tile under
the same left-to-right alpha ramp (UI.Wash with a file, src/UI/Draw.lua;
BuildWash and UI.FloorBand, src/UI/Feed.lua and src/UI/Backdrop.lua). The
harness passes; in the 2.5.6 client, on 2026-09-19, it does not work.

Still to find out: what is on screen instead (the old flat wash, nothing, or
an unfaded bar), and which palette was chosen. Read the live saved variables
for the palette before any client theory.

Parked by the user until the rest of the epic lands. Card 01M2WM83Z9AFFGRX657KRA7N3D
holds the change.
