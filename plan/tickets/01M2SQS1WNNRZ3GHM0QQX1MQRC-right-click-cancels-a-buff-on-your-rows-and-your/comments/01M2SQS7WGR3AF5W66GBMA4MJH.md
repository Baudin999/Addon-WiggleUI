---
revision: 5
id: 01M2SQS7WGR3AF5W66GBMA4MJH
---

Cause. The squares had no click handler at all; the header of Auras.lua said cancelling was impossible, which is only true in combat. SetPassThroughButtons from Tip.Hang is not the cause on 2.5.6, the client has no such call.  Fix. OnMouseUp in Hover, HELPFUL rows on player and pet, guarded by InCombatLockdown.  Gate. 14-aura-row presses Mend Pet through H.mouse: right click cancels pet 1 HELPFUL, left click, combat and a debuff cancel nothing.  Unverified: CancelUnitBuff on the pet unit in the live client; Blizzard never calls it with pet.
