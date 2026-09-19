---
revision: 5
id: 01M2WYEZP2PK0FSMVSC5X7N4XE
---

Landed in 9bb4722. Cause: World.lua heard only UPDATE_MOUSEOVER_UNIT, and a game object sets no token and fires no event. Fix: Scan.Watch hooks the client tooltip's OnShow/OnHide. A show owned by UIParent, over WorldFrame, about no unit/item/spell opens an object subject, and the parchment sits at alpha 0 (Scan.Hold). It is never hidden, because OnHide is the only leave signal. Sources: 'quest objects' (Drops.lua, extra 41, via l10n.objectNameLookup + o_ keys, zone-narrowed like Questie) and 'your skill in it' (Skills.lua, body 30, bar). Unverified in the client: whether its fade-out on leave touches the alpha. If a ghost parchment flashes on leaving a vein, look there first. Gate: section 49-world-objects.
