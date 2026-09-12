---
revision: 5
id: 01M2AA3VA88D6PG6P2CESXSVHG
type: task
status: todo
title: Zone tabs down the side of the tracker
---

The tracker draws the zone you are standing in and nothing else, so a log with
quests in six zones is a tracker you can only read one sixth of, and the only
way to see the rest is to walk there. The pin is the current answer and it is
the wrong shape for the question: a pin is for one quest you always want, not
for looking at Westfall for a moment.

## What it is

A strip of tabs down the left edge of the tracker, one per zone your log has
quests in, each turned -90 degrees so the strip is as narrow as a line of text
is tall. On a tab: the zone's name and how many quests you still have there.
Clicking one draws that zone. A gold dot in the corner where the zone has
something ready to hand in.

`FontString:SetRotation` is real on both of these clients: it is in
`SimpleFontStringAPIDocumentation.lua` on the anniversary branch and on
classic_era. It is still probed and pcalled at the call site, like everything
else this addon asks a client for, and a client that will not turn a label
draws the strip along the top instead.

## Which zone is drawn

Where you are standing, until you click a tab, and then that one until you walk
into a zone that has quests. Walking is the gesture that means "I am here now"
and a click is the gesture that means "show me there"; the second outranks the
first until the first happens again.

Pins keep the rule they have: appended after the zone's own quests, wherever
you are standing and whatever tab is up.

## And the column stops hiding itself

The rule today is that a tracker with no quests on it is not drawn. That was
right while the tracker was only ever the zone under your feet. It is wrong the
moment there are tabs on it, because standing in Ironforge would take away the
control you use to look at Westfall. It is drawn whenever your log has a quest
in it, and hidden when the log is empty.
