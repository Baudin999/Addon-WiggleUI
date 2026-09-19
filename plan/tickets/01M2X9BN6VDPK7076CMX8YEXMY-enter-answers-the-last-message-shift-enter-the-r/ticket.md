---
revision: 5
id: 01M2X9BN6VDPK7076CMX8YEXMY
type: feature
status: todo
title: "Enter answers the last message, Shift-Enter the room you last spoke in"
---

Enter answers whoever spoke last. A party line, then three whispers: Enter opens
the line on `/w <third>`. Shift-Enter opens it where you last sent a line, so
`/p ` in that example. Tab steps back through the rooms newest message first,
then the rooms nobody has spoken in, in rail order.

What counts as a message: party, raid, instance, guild and officer lines, and
whispers, from somebody other than you. Say, yell, emote, numbered channels,
system and skill lines move nothing.

The latest event wins. Picking a room on the rail, answering a name or tabbing
is an event too, so Enter after a pick stays in the pick until the next line
arrives.

Where:
- src/Chat/Rooms.lua: the heard order, the room last sent to.
- src/Chat/Feed.lua: Handle tells Rooms which room a line was heard or sent in.
- src/Chat/Window.lua: Fill opens on the newest room, Step walks by time, the
  ghost says where Enter goes.
- src/Chat/Field.lua: SHIFT-ENTER and SHIFT-NUMPADENTER onto OPENCHAT through
  an override, taken again through ns.Rebind.

No clicking. The floats stay click-through.
