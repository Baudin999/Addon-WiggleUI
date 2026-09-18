---
revision: 5
id: 01M2GT6AFRHHF84X1DCZB2A8JN
type: task
status: doing
title: The pet bar draws no keys on the live client
---

On Kibbling (2.5.6, 2026-09-14 22:25) the pet squares draw no key in the
corner. The action bar squares under them draw theirs.

What is known:

- bindings-cache.wtf holds `bind G BONUSACTIONBUTTON4`, `T ...5`, `R ...6`, and
  the same file agrees with the keys the action bars draw (E, sQ, sZ, s1, s5).
- Pet.Bind reads `GetBindingKey("BONUSACTIONBUTTON" .. index)`, the call
  Blizzard's own PetActionButtonMixin:SetHotkeys makes on classic_anniversary,
  on PLAYER_LOGIN and UPDATE_BINDINGS, the same two events Blizzard's does.
- Nothing in WarriorKit holds an override on G, T or R (markBinds F3-F5,
  perfKey CTRL-R, switchKey TAB, hoverBinds empty). No SetOverrideBinding call
  anywhere in Blizzard_ActionBar or Blizzard_ActionBarController.
- Ability.Bind is the only writer of `w.key`, and nothing hides it.
- Harness 05-pet-bar now binds G and SHIFT-R and reads "G" and "sR" back off
  squares 4 and 6, so the stub draws them.

Next: one live read splits the two causes left, the call answering nil or the
label not rendering.

    /run print(GetBindingKey("BONUSACTIONBUTTON4"), WarriorKitPetButton4.key:GetText())
