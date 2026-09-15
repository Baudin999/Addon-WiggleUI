---
revision: 5
id: 01M2K3HNW2HX1AYHAN9BSB930Z
---

Cause. The tracker's Quest row in src/Quests/Column.lua drew only Log.Tint on the name; the tick lived as a local in Quests/Window.lua.  Fix. Log.TICK beside Label and Tint; the tracker's title rows carry a UI.Glyph tick in C.tick in a 10 px column at LEAD, shown on quest.complete. Landed at cf0c532.  Gate. Section 85 checks the tick on Hogger and its absence on the diplomat. Its drawn() helper skips row.tick, because a hidden fontstring still counted as a row and put five row counts one over.
