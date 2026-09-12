---
revision: 5
id: 01M2AA3DMXDF5SPDC27MJEX30T
type: task
status: done
title: "How full the log is, at the top of the window and the tracker"
---

`17/25 quests` reads at the top of the quest window and at the top of the
tracker.

The number the client caps you at is `MAX_QUESTLOG_QUESTS`, which is 25 on
2.5.6 and is set in Blizzard_FrameXMLBase/TBC/Constants.lua. It is a FrameXML
global rather than a call, so Quests/Client.lua probes it the way it probes
everything else and answers nil where the client does not carry one.

`QUEST_LOG_COUNT_TEMPLATE` is the client's own format string for the pair and is
what the client's log draws in its own corner, so the sentence is built from it
and not typed out here. A client missing it falls back to `%d/%d`.

## Where it goes

The window puts it in the title bar, right aligned, left of the close box.
UI/Window.lua grows `Window:Note`, which is the same corner `Window:Search`
already anchors into and the second caller that wants it.

The tracker puts it on the first row of the stack, above the quests.

The footer of the window keeps its own longer sentence: `%d quests, %d ready to
hand in` answers a different question and is read in a different place.
