---
revision: 5
id: 01M2SS0V705NCVPHRD73WFEPA4
type: task
status: done
title: Right click cancels your buff in combat through the secure aura header
---

Right click cancels your own buff in combat. The squares cannot make the call in combat, so the buff row carries the client's SecureAuraHeaderTemplate over it, built by UI.Press.Cancels with pre-built Press.Button children (RightButton, up, type2 cancelaura). Row drawn in the client's own index order so square N is the aura button N cancels; grid worked out from Flow's line-break rule.
