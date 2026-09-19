---
revision: 5
id: 01M2WJMK5V2EHBX50ZZ93M4H8D
type: task
status: doing
title: "Party chat, whispers, skill-ups and system lines float in like the drops"
---

A second stream of floating messages beside the loot float, for chat.

Placement: `msgFloatSide` is `opposite` (default) or `same`. Opposite is the
loot lane's spec with only `side` flipped, the way the target block mirrors the
player block. Same pushes into the loot lane itself.

Toggles: `msgFloat` (master), `msgFloatParty` (CHAT_MSG_PARTY, _LEADER),
`msgFloatWhisper` (CHAT_MSG_WHISPER, CHAT_MSG_BN_WHISPER), `msgFloatSkill`
(CHAT_MSG_SKILL), `msgFloatSystem` (all of CHAT_MSG_SYSTEM, unfiltered, the
user's call). Your own lines are skipped.

Theme: new element `messages`, show in informational and exploration, hide in
immersive. Checked before a push, so a hidden message never takes a slot in a
shared lane.

Library: `Lane:Push(frame, height, ttl)` takes a hold per message; text wraps to
three lines and the row is measured.

The chat window is left alone. This is a separate stream, not a replacement.
