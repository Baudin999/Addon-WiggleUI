---
revision: 5
id: 01M2AAZBS0XWER2YQAQTDAD3HB
---

Done. Client.Cap reads MAX_QUESTLOG_QUESTS off _G and answers nil where the client has none; Log.Full formats it against the client's own QUEST_LOG_COUNT_TEMPLATE and falls back to the count alone. One reading, two drawings: the window's title bar through the new Window:Note, and the tracker's first line.

Shape. The tracker's line is chrome rather than a stack cell. It is anchored above the stack, so nothing that counts the rows on that column has to subtract it and no click can land on it, and 85-quest-column asserts both.

Gate. The stub in client/12-questlog.lua was at exactly 800 lines, which is the general harness limit, so the two constants tipped it over. It is allow-listed at 810 with the reason the file is one subject: the map column reads Questie's spawns through the same standing position, map art table and H.quests handle the rows come through, so splitting it would carry all three twice. check.sh at zero.
