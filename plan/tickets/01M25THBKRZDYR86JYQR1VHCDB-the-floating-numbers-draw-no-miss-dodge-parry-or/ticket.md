---
revision: 5
id: 01M25THBKRZDYR86JYQR1VHCDB
type: bug
status: done
title: "The floating numbers draw no miss, dodge, parry or resist"
---

A blow that does not land draws nothing. `CombatText/Numbers.lua` returns early on every `*_MISSED` line, on purpose: the comment at the shape check says drawing the word was a decision not yet taken. The quiet setting then turns off `floatingCombatTextCombatDamage_v2`, which is also what draws the client's own "Miss" and "Resist" over your target, so with both in place nothing on screen says a swing missed.

Fix: draw the client's own word for the miss type in the column the blow belongs to, grey like the combat feed's miss row, never merged. Take `floatingCombatTextDodgeParryMiss_v2` and `floatingCombatTextDamageReduction_v2` with the other four, because once this part draws dodges the client's scroll would draw them a second time.
