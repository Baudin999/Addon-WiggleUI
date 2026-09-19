---
revision: 5
id: 01M2WY3YKYK8ZZT26GXZ7P2ETW
type: bug
status: doing
title: "Hovering an ore vein or herb shows Blizzard's tooltip, not ours"
---

A world object has no box of its own. src/World/World.lua listens for
UPDATE_MOUSEOVER_UNIT and nothing else, and an ore vein, a herb, a chest or a
mailbox is a game object: the client never sets `mouseover` for one and never
fires that event. The suppression in src/UI/Scan.lua acts only on a tooltip
that answers GetUnit. So the client's parchment goes up untouched.

Fix: an `object` subject kind. UI/Scan.lua hears GameTooltip show with no
unit, item or spell on it, owned by UIParent, over WorldFrame; World.lua reads
the client's lines off it, opens the addon's box and holds the parchment at
alpha 0 rather than hiding it, because its OnHide is the only signal that the
pointer left the object. Sources: quest objectives off Questie's `o_` keys in
the creature hover's own style (Quests/Drops.lua), and the player's rank in a
skill the client's text names, as a bar (Character/Skills.lua).
