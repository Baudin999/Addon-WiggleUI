---
revision: 5
id: 01M2DRRZGVB29DF7AFM00HPDK7
type: task
status: todo
title: "Party members on the map as Blizzard's party pin, named in class colour"
---

The map drew each party member as a class-coloured square. Draw them as Blizzard's own party pin, Interface\WorldMap\WorldMapPartyIcon at 16 px (UnitPositionFrameTemplates.lua and GroupMembersDataProvider.lua on classic_anniversary), with the name in class colour on the hover.

The continent picture (the map window's whole-continent row) must carry them too. Chart.Spot refuses an answer for any map but the one asked for, so a client that answers the continent override with the zone places nobody there.
