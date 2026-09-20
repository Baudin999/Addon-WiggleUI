---
revision: 5
id: 01M2ZNSVX3W77KW0RPB8YZ2VPD
---

Meter/Window.lua's four are gone, at 5f331204. WARN and GREY went to Unit/Color.lua: the grey was the fallback bar for a player with no class yet and is Color.reaction.idle, the coral was the threat pane's converging member and is a new token, Color.text.alarm, registered in the shaping pass so it is held to TOKEN_RATIO against the fill it is written on. The rule's 0.5 0.5 0.55 at 0.35 alpha and the bar's default 0.5 0.5 0.5 went to UI.Color.dim and Color.reaction.idle.

Worth knowing before the next file: the sort in the body is one kind short. A literal on a surface with no window under it cannot take the palette's chrome, because edge and hairline are dark for a window and this line had a desert floor behind it. UI.Color.dim at full alpha is the one value that survives a pale floor and a dark one, and that is what the meter's rule is now.

The body also says a class colour is the client's and stays. It is not and it does not. RAID_CLASS_COLORS is the chat tint and it is unshaped, so a bar filled with it carries a name at 1.7:1; Color.Class and the new Color.ClassTint are the two answers and every caller wants one of them by name. That was the whole of the meter's defect.
