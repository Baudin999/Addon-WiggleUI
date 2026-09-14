---
revision: 5
id: 01M2GNJ6Q87QB5XG05QAG2AG60
type: task
status: todo
title: The pet bar is still Blizzard's; draw it as our own squares
---

With a pet out, Blizzard's PetActionBar draws in its 2007 art beside the cloned
action bars.

Ten squares of our own in src/Buttons/Pet.lua, under the actionBars switch. A
left press is the secure `pet` action on that slot. A right press clicks
Blizzard's PetActionButtonN, whose own OnClick toggles autocast. The keys stay
on the client's BONUSACTIONBUTTON bindings, which call PetActionBar directly.
Blizzard's PetActionBar goes into the attic by Attic.Take alone: no ns.Strip,
because its own OnEvent calls self:Show() and then protected work.

Source: Blizzard_ActionBar/Classic/PetActionBar.xml and Shared/PetActionBar.lua
on Gethe/wow-ui-source classic_anniversary.
