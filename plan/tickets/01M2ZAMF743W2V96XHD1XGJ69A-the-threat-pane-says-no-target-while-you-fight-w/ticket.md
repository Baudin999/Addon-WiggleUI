---
revision: 5
id: 01M2ZAMF743W2V96XHD1XGJ69A
type: bug
status: doing
title: The threat pane says no target while you fight with the camera
---

Reported from play twice: the threat pane never fills, and swapping mobs does
not help. The header word added by 01M2JZAXQW52X9ZHFVNRREMMYS is what named it:
it says "no target".

Cause. Meter/Threat.lua asked the client about "target" in all three places it
needed a mob: ThreatMeter.Watching, the GUID it compares to decide the mob
changed, and the UnitDetailedThreatSituation call itself. With action targeting
on, which Targeting/Aim.lua switches on out of the box, the client picks the
enemy in front of the camera and answers for it under `softenemy`. That token
is not the target. SoftTargetForce is what copies one onto the other, and a
client not honouring it leaves a player swinging all night with nothing
selected, so every one of those three questions answered nothing.

Fix. Unit.Aimed in Unit/Unit.lua: the held target when there is one, because
holding one is a decision and an angle is not, then the soft token. The probe
for `softenemy` and the "may I swing at this" predicate moved there out of
Charge/Charge.lua, which had the only copies, and Charge calls them there.
Sample takes the mob as an argument. The reset that forgets the sample window
runs on the tick as well as off PLAYER_TARGET_CHANGED, because a soft target
moves with no event of its own.

Gate. 25-meters: with nothing targeted and a mob under the camera the pane
samples `softenemy`, draws rows and does not say "no target"; a held target
beats the camera; a corpse under the camera is "no target" the same as a corpse
held.
