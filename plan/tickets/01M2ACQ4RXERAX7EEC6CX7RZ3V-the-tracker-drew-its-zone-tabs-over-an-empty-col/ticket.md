---
revision: 5
id: 01M2ACQ4RXERAX7EEC6CX7RZ3V
type: bug
status: todo
title: The tracker drew its zone tabs over an empty column
parent: 01M1B7RTAFVTSQ3FARJZCD1PYK
---

Six zone tabs down the left of the tracker, one of them lit, and nothing beside
them: no quest names, no objectives, and not even the line saying how full the
log is. Reported off a screenshot in Shattrath with seventeen quests in the log.

## Cause

`body`, the frame the strip's arrival put the tally and the stack inside so one
anchor could move them off the strip's width, was made with a width and no
height. A frame with no rectangle is not drawn on this client and neither is
anything anchored inside it, so everything on the tracker that is not a zone
tab was laid out into nothing.

Every assertion in 85-quest-column passed while it did. They are made against
the model and against the pool, and both were right: `Column.Quests` answered
the zone's quests, the pool held a row per quest and per objective, and each row
carried the string it should. The stub resolves a frame's height off opposing
anchors the way the client does and had no rule that a frame holding something
has to have one at all.

## The other half

The turned labels sat against one edge of the strip with no air on the other.
`Side:Resize` sized a tab across the strip off `self.size`, the size the font
was asked for, and a line of text is taller than that by its leading. The width
is measured off the label now, through `UI.TextHeight`, and SIDEEDGE went from
four to six so the air that fix makes room for is visible.

## Gate

Two, both in 85-quest-column, and each was watched to fail with the fix taken
out: the tracker's words stand in a frame measuring more than nothing, and a
zone tab is at least eight units wider than the line of text it holds. The
first one reads `220.0 by 0.0` without the fix.

And 89-frame-rects, a sweep of every frame on the addon's pixel grid that is
visible and holds something, which is 268 of them at the foot of a run. It
cannot reach the tracker, because 85 puts it away again at its own foot, which
is why the rule is asserted in both places.
