---
revision: 5
id: 01M2TBM088MXMPHXNZMCTJEHJ7
type: task
status: done
title: The spell book draws no tab for your pet's abilities
---

The spell book window read only the player's book, so a hunter or warlock pressing P saw no pet abilities, and the client's pet-book key printed "this window does not draw your pet's book".

Fix: src/Spellbook/Read.lua reads the "pet" book as a last tab while a pet with spells is out, named after the pet, spells only (PETACTION commands stay on the pet bar). Pet spells are armed by name(rank) and picked up from the pet book. Window.lua hides the tab when the pet goes and refreshes on UNIT_PET for the player. Blizzard.lua's pet-book toggle opens and shuts that tab.
