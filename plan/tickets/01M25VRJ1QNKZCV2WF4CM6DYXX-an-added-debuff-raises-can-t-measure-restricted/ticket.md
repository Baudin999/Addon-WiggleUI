---
revision: 5
id: 01M25VRJ1QNKZCV2WF4CM6DYXX
type: task
status: doing
title: An added debuff raises Can't measure restricted regions on a plate bar
---

Adding Shadow Word: Pain from the enemy bar panel, as a priest with a bar on a
nameplate, raised:

    StatusBar:GetPoint(): Action[FrameMeasurement] failed because
    [Can't measure restricted regions]

The stack is AddSpell → Retrack → ApplyLayout → LayoutWidget, at
src/UnitFrames/EnemyBars.lua:1401. LayoutWidget reads widget.health:GetPoint()
to find the gauge's middle. A widget on a plate hangs under a restricted
region, and this client refuses a positional read anywhere beneath one. It
throws; it does not return nil.

The list edit itself lands. The saved list held 589 afterwards.

The harness missed it because its nameplate frames answer every measurement.
Release at EnemyBars.lua:2282 makes the same kind of read (GetLeft,
GetBottom) and needs checking too.
