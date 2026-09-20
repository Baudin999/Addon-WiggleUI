---
revision: 5
id: 01M2ZQNQSB9QAQ6675T5GSANNM
type: feature
status: todo
title: "The breakdown drills into one ability, and the bands become a graph"
---

The breakdown window keeps the right numbers and hides them behind the wrong
control. Three complaints, one sitting, because they land in the same two files.

## The chip is the only way to see a band, and it is one band at a time

`src/Breakdown/Window.lua:401` draws a `targets` label and a chip that cycles
five words. Reading whether the miss rate climbs with the level gap means
clicking the chip, reading a row, clicking it again, reading the same row, and
holding three numbers in your head. That is a graph drawn by hand, badly.

Draw it. X is the band, Y is a chance from zero to a hundred, one coloured line
per outcome: crit, miss, dodge, parry, block, glancing. The eye reads the slope
and the slope is the whole answer.

Three points on the X axis and not four. UNDER, NEAR and HIGH are an ordinal
scale; UNKNOWN is the absence of one and putting it on the axis draws a slope
that means nothing. The unknown bucket's sample count goes under the plot as a
sentence instead.

`frame:CreateLine(name, layer)` with `SetThickness`, `SetStartPoint`,
`SetEndPoint` and `SetColorTexture` is real on 2.5.6: Questie calls it at
`Modules/FramePool/QuestieFramePool.lua:224` and Details' chart library at
`Libs/DF/charts.lua:182`. Lines pool the way every other repeated widget in the
addon pools, because this redraws on every row click.

Colours come from the palette, not from a list typed into the file. Six lines
need six distinguishable hues and the palette owns that question.

## A row is a Button with nothing on the button

`BuildRow` at `src/Breakdown/Window.lua:302` makes a `Button` and gives it
OnEnter and OnLeave that show a glow. Nothing on click, no tooltip. The glow
promises a click that does not exist, which is worse than a row that looks
inert.

Click a row, get that ability on the right: its name, its icon, the four
derived figures `Breakdown.lua` already computes per row, and its own copy of
the graph. Click it again, or click away, and the right pane goes back to the
pooled graph for the whole character. The pooled graph is what answers "am I
hit capped"; the per-ability one is what answers "why is Heroic Strike dodged
more than Mortal Strike".

Side by side rather than a drill-down with a back button. The quest log and the
dungeon log are both three columns wide for the same reason: the list is the
navigation and losing it to see a detail costs a click on the way back. The
window is 560 wide at `WIDTH`; a detail pane wants about 300 more.

## The window cannot throw the data away

`Breakdown.Reset` exists and has two callers, the slash word at
`src/Breakdown/Feature.lua:86` and the armed two-press Action on the settings
page at `src/Breakdown/Feature.lua:118`. Neither is in the window, and the
window is where you are standing when you decide a month of counting is
polluted by a week of leveling.

Same armed two-press button, in the window's footer beside `close`. The armed
flag is per-window state and not saved, same argument as the panel's.

## What this does to the chip

It stops being the way you read a band difference and becomes a filter on the
ranking and the damage column, which is what a filter should be. Keep it.
`ns.db.breakdownBand` stays as it is; the graph reads every band regardless and
does not touch the setting.

## The gate

`Breakdown.Rank` already takes a band or nil. The graph needs rates per band
for one ability and for the pool, which is the same fold over `record.at` with
the band loop inverted. Put that in `Breakdown.lua` as a function that returns
a table, and cover it in `scripts/harness/runner.lua`'s `32-breakdown` section
with a fixture that has a different miss rate in each band. A chart drawn from
a fold nothing tests is a chart that will quietly draw a flat line.
