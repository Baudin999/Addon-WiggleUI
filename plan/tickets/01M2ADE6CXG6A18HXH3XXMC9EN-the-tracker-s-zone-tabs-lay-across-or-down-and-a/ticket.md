---
revision: 5
id: 01M2ADE6CXG6A18HXH3XXMC9EN
type: task
status: done
title: "The tracker's zones fold as a harmonica, or turn on a strip"
---

The tracker drew one tab per zone down its left edge, turned a quarter turn.
That is the cheap control and it is the one you tilt your head to read, on the
frame in this addon that is looked at most often.

So the zones are drawn as a harmonica and the turned strip is the other
setting. A harmonica is a plate per zone stacked down the column, each with its
name written the way round every other word on the tracker is, and the open
one's quests under its own plate:

    Elwynn Forest 2
    Westfall 1
      The Defias Brotherhood
        Defias Trapper slain: 5/12
    Duskwood 3

Pressing a plate opens that zone. Walking into a zone that has quests takes the
choice back, which is the rule the tabs already had.

- `src/Quests/Column.lua` the plates are rows in the same stack the quest names
  are in, which is what makes the open zone's quests sit under its own plate.
  `Folded()` lays them, `Quests()` unfolds one, and what is left of
  `Column.Quests` by then is the pins from somewhere you are not standing.
- `src/Quests/Feature.lua` `questsTabs`, "harmonica" or "turned", on the Quests
  page. The harmonica ships.
- `src/UI/Window.lua` untouched. UI.SideTabs still draws the turned strip and
  nothing else; in a harmonica it is handed no tabs and goes off the screen.
- `scripts/harness/sections/85-quest-column.lua` asserts both shapes and that
  only one of them is on the screen at a time.
