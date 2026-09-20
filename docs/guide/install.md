# Install

Unzip into `Interface/AddOns`, so that the folder is
`Interface/AddOns/WiggleUI` with `WiggleUI.toc` directly inside it.

If you end up with `Interface/AddOns/WiggleUI/WiggleUI/WiggleUI.toc`, move the
inner folder up one level. The client will not load it from the extra level.

Both clients are served by the same folder, and nothing has to be picked by
hand. The TBC Anniversary client reads `WiggleUI.toc` and the Classic Era
client reads `WiggleUI_Vanilla.toc`.

| Client | Version | Interface |
| --- | --- | --- |
| TBC Anniversary | 2.5.6 | 20506 |
| Classic Era | 1.15.9 | 11509 |

There is no retail TOC in the folder, so a retail client will not load it.

[Questie](https://www.curseforge.com/wow/addons/questie) is the one other addon
this one asks anything of, and it is worth having. Both TOCs name it under
`## OptionalDeps` and the CurseForge upload declares it an optional dependency,
so an addon manager offers it alongside this download and the client loads it
first where it is there. Install it by hand if you took the zip. Nothing here
needs it; the section on [Questie](#what-questie-adds) says what it adds.

## What Questie adds

The quest log window, the tracker, the map and the bag lanes all draw off the
client on their own. What [Questie](https://www.curseforge.com/wow/addons/questie)
adds is the map pin for where a quest is turned in, the drop rate under an item
something wanted, a party member's progress on a quest you share, the places on
the map you can tick on and off, and the quest a finished item belongs to on a
clutter card. Each of those says in the panel that Questie is not answering
rather than showing you a blank.

> **Screenshot wanted:** `install-addons-list.png`, the character select addon
> list with WiggleUI ticked.
