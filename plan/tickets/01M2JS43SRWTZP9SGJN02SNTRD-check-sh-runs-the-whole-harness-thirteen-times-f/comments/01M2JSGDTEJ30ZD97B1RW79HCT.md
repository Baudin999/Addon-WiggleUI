---
revision: 5
id: 01M2JSGDTEJ30ZD97B1RW79HCT
---

Landed in f558efe. check.sh runs the harness whole once as WARRIOR, then 13 class runs (12 specs and HUNTER) of 13 sections each: login, CLASS_SECTIONS in runner.lua, and the carry writers they depend on, computed from the section files. A class run is 0.43 s; check.sh is 17 s end to end. The hook's second harness run is gone.

Gate. runner.lua fails any section that reads PLAYER_CLASS, PLAYER_SPEC, Spec.Mine, Spec.Token or Class.Mine and is not in CLASS_SECTIONS, and any entry whose section stopped reading them. In a class run H.carry raises on a key some section writes and nothing in the run wrote.

Not at zero, and none of it is this change. HEAD was already red, confirmed by running HEAD's own runner from a git archive copy: (1) harness FAIL as WARRIOR 'with no Questie the quest pile still has 4 squares across a right lane', from today's bag pile commits; (2) the hot path scan on UnitFrames/EnemyBars.lua:1157-1158 and UnitFrames/Plates.lua:239,270,274, from the hit test point commits; (3) luacheck on Talents/Training.lua:67,85,97, from the pet training commits. They got in because core.hooksPath is unset in this checkout.
