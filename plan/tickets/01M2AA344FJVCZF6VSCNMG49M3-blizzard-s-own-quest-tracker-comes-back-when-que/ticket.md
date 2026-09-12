---
revision: 5
id: 01M2AA344FJVCZF6VSCNMG49M3
type: bug
status: doing
title: Blizzard's own quest tracker comes back when Questie's goes off
---

Blizzard's `QuestWatchFrame` is on the screen whenever the client auto-watches
a quest, and nothing in this addon takes it down.

## Cause

Questie is what used to hide it. `QuestieInit:Init` calls `WatchFrameHook.Hide`
and `Questie:OnEnable` calls `QuestieCompat.HideWatchFrame`, and both are
guarded by `Questie.db.profile.trackerEnabled`. Quests/TrackerOff.lua switches
that setting off, which is the whole point of it, so from the first login after
the box is ticked nobody hides Blizzard's watch frame at all. The client's
`QuestWatch_Update` calls `QuestWatchFrame:Show()` off `autoQuestWatch`, which is
why it arrives partway through an evening rather than at login.

## Fix

Quests/Blizzard.lua cages `QuestWatchFrame` and `QuestTimerFrame` in
Core/Attic.lua on the same switch that puts this addon's own tracker up,
which is `quests` and `questsTrackerOff`. That is `ns.QuestColumn.Wanted()`
by another name: the state the hole opens in is exactly the state the column
has the screen.

The cage shape in Core/BlizzAdapter.lua wants a `global` to swap. There is no
toggle global for a watch frame, so the field becomes optional and Describe
drops the redirect clause where it is absent.

## Gate

A section that shows the frame, runs the pass and reads its parent back as the
attic.
