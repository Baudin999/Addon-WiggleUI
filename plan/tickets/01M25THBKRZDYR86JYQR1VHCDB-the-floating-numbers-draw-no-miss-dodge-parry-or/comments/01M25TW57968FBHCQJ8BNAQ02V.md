---
revision: 5
id: 01M25TW57968FBHCQJ8BNAQ02V
---

Cause. Numbers.OnLog returned early on every *_MISSED line by design, and hitsQuiet turns off floatingCombatTextCombatDamage_v2, which also draws the client's own Miss/Resist over the target. Nothing drew a failed blow.  Fix. aa9eb95: Missed() in CombatText/Numbers.lua draws the client's word (COMBAT_TEXT_<kind>, else the bare global, table built at load so the log line joins no string) in the feed's grey MISS, off the column the blow was aimed at, weight FLOOR, no merge key. Blizzard.lua TAKEN gains floatingCombatTextDodgeParryMiss_v2 and floatingCombatTextDamageReduction_v2 so the scroll does not double them; remembered and restored like the other four.  Gate. Section 80 asserts side, word, grey, weight under 1, two parries stay two, the not-mine filter, and the DodgeParryMiss CVar at 0. It is 872 lines, allow-listed in check.sh as one subject. Partial resists and blocks on a landed hit are not drawn.
