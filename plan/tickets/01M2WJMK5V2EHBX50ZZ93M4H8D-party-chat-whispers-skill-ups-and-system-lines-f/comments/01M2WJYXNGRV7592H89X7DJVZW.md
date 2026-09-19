---
revision: 5
id: 01M2WJYXNGRV7592H89X7DJVZW
---

Landed in 1c235c6. Feeds/Messages.lua mirrors the drops' lane (spec copied, side flipped) or pushes into it. A mirror is rebuilt whenever Floats.Lane() returns a new lane, so a loot float slider reaches it without a call. Lane:Push(frame, height, ttl, onGone): ttl is #text/15 clamped to [msgFloatHold, 8]; onGone per push keeps chat rows out of the loot pool. Own lines are skipped by GUID or by name, because the stub has no player GUID and a real event can lack one. The harness stub now models SetMaxLines. Gate: harness section 79-floating-chat. Not tested in game yet: BN whisper sender display, and how the class icon crop looks at 44 px.
