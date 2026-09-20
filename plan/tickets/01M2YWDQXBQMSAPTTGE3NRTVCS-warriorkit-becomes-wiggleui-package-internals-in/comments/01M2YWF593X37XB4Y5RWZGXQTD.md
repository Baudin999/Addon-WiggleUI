---
revision: 5
id: 01M2YWF593X37XB4Y5RWZGXQTD
---

Landed in 97e960f. Passes: WarriorKit/WARRIORKIT/warriorkit, /wk -> /wui, and \bwk[A-Z] -> wui on the fields hung on Blizzard frames. 280 lines that say warrior and mean the class were left alone on purpose, so a future case-insensitive sweep is wrong. Gate. check.sh fails on the old name in any spelling; plan/, docs/CHANGELOG.md, docs/POSTMORTEMS.md and check.sh itself are allow-listed with a reason each. Installs. Symlink repointed in both, 13 saved-variable files copied to WiggleUI.lua with every occurrence rewritten (the window-position keys are frame names, so a partial sed would have lost every window placement), 15 AddOns.txt entries renamed so no character logs in with it off. Old WarriorKit.lua files left in place as backups. Not verified in the client yet: log in once and check the windows are where you left them. Outside: CurseForge project 1675955 and its slug were renamed by hand before this landed; the GitHub repo is still Addon-WarriorKit and the banner art in art/ still has the old name painted on it.
