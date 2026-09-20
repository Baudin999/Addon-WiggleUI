---
revision: 5
id: 01M2ZWNWM5AQWFEKE2RVZ7C81R
---

Landed. ./scripts/check.sh at zero.

Three things found on the way that were not the feature and are worth the next reader's time.

Ticker names are per frame and the page's trinket sweep hangs off ns.UI.Forever. A second pane built a second tick of that name and UI/Ticker.lua raised at login. The right answer was not a second name: the arc it drives reads a slot of yours whatever page asked, so an inspect pane builds no sweep at all.

UI/Window.lua sets OnHide itself, in Dismissals, to stop key capture and close an open dropdown. A SetScript on a window's OnHide silently deletes it. Both of this window's scripts are HookScript for that reason, and Character/RepWindow.lua's SetScript("OnShow") is only safe because it is not a dark window.

ns.ItemSockets returns two values and 'local filled, open = link and ns.ItemSockets(link)' truncates to one, so every piece read as fully gemmed. luacheck caught it as 'open is never set', which is the gate earning its keep.

Ruled out, so nobody re-derives it: there is no resistance row and no stat row for an inspected character, and it is not a gap. UnitStat, UnitArmor, UnitAttackPower and UnitDamage all answer for the player and nil for anybody else on 2.5.6, weapon skill has no unit on its call, and Blizzard's own TBC inspect frame shows no attribute at all for the same reason. Gethe/wow-ui-source classic_anniversary, Blizzard_InspectUI/Classic/InspectPaperDollFrame_Shared.lua, is the whole of what the client will answer: GetInventoryItemLink, Texture and Count by unit, and the talent calls with the inspect flag.
