---
revision: 5
id: 01M2GGYYMMBAYTWZN6J7W04C2C
---

Done. Label and Tint moved off Quests/Window.lua onto ns.QuestLog as Log.Label(quest, tag) and Log.Tint(quest). The window's rows and the tracker's quest names in Quests/Column.lua both call them, and Column's own Tone is gone. Gold for ready to hand in is now the log's C.tick green.

Gate. Section 85 reads the Defias row whole and checks it against Log.Label and against Unit.Level.WorthOf(22). Its row and says helpers match a title with or without the bracket tag, because the elite + shows up only once Where.Tag has been asked once.

Watch for. Window.lua's own comment says C.tick sits two shades off the ladder's green. The log carries the finished state in a tick glyph beside the name; the tracker has no glyph region, so a finished quest and an easy one are close in colour there. If that reads badly in game, the fix is a tick glyph in front of the tracker name, not a different colour.

Seen once and not caused here. 08-bars-zoom failed 'nameplates ship ignoring the mouse' on one harness run and passed on the next two with no change between them.
