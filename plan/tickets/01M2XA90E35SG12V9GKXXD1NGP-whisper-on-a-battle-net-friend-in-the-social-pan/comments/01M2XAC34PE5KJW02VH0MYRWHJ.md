---
revision: 5
id: 01M2XAC34PE5KJW02VH0MYRWHJ
---

Fixed in fe9ede6. Field.lua post-hooks ChatFrameUtil.SendBNetTell (installed from Field.Adopt, because the harness only has hooksecurefunc per block) and re-aims with Field.Aim, which writes attributes and calls the box's own UpdateHeader. Rooms.Target answers BN_WHISPER for a name starting |K, Rooms.For and Window.Follow accept BN_WHISPER, Window.Fill aims instead of writing a slash. Harness: 45-chat-keys models SendBNetTell from the 2.5.6 source and fails with the hook removed (line opened on SAY). Not yet checked live: whether a BN whisper room title shows the token raw.
