---
revision: 5
id: 01M25XW8FXP6JQQ7NT6EZ7QGWR
---

Cause. Wanted opened on UnitCanAttack, so your own side (never attackable outside a duel) and the other side on a PvE realm (not attackable until flagged) got no bar. Separately, 2.5.6 puts friendly players behind nameplateShowFriendlyPlayers, which the live config-cache leaves at off, so there was no plate to hang a bar on. Fix. 08c07e8. Wanted is the plate rule: every player but you, a mob when attackable. The old rule is Hostile and only the list asks it. Plates.lua borrows the CVar while the bars are on plates, prior in platesFriendsPrior, kept by the reset. A player's gauge is Color.OfUnit, the grey worthless name needs UnitCanAttack, UNIT_FACTION marks a bar already up. Gate. Section 18 covers both factions, self, the flag up and down, the class colour, the grey name, list exclusion and the CVar both ways; the pre-commit hook passed. Not yet seen on the live client. Friendly plates in an instance are forbidden to addons, so there is no bar on a party member inside a dungeon.
