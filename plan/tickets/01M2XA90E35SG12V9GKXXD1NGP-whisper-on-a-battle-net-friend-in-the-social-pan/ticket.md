---
revision: 5
id: 01M2XA90E35SG12V9GKXXD1NGP
type: bug
status: doing
title: Whisper on a Battle.net friend in the social panel opens on the room
---

Right click a Battle.net friend in the social panel (O), pick Whisper, and the line opens on the room's own slash instead of on them.

Cause: ChatFrameUtil.SendBNetTell writes BN_WHISPER and the friend's token onto the field, then opens it empty. Chat/Field.lua fills an empty line on focus with the room's slash, and the parser moves the channel off the friend. No slash can reach a friend named by a |K token, so the unit-menu fix from 58a39fe (which reads the /w write back) never covered this path.
