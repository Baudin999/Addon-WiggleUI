---
revision: 5
id: 01M2WNG20MW1PJAZZ8NZDJHT9D
---

Cause. Every feed built a scroll bar and reserved its column, and the loot feed never passed opts.held, so it kept UI/Feed.lua's 400 entries all session.  Fix. 53895ef: the bar is opts.bar in UI/Feed.lua; the combat feed asks for it, the loot feed does not, and a feed without one gives the rows the column back. The wheel still scrolls; the faded bottom row says there is more. HELD = 30 in Feeds/Loot.lua goes through Stream.New; not a saved setting, nothing to retire.  Gate. 31-feeds: loot holds 30, no bar, rows frame-wide, wheel scrolls; combat keeps its bar and 400. 40-loot-remove scrolls 10 instead of 20.
