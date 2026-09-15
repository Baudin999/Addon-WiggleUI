---
revision: 5
id: 01M2J1F5SQHRBSXBSYTNM1B2AB
---

Fix. c2cc570. A hover on a teachable row calls CraftFrame_SetSelection and lays WarriorKitBeastTeach, a secure type=click button on UIParent, over the row with clickbutton=CraftCreateButton; the press reaches DoCraft from Blizzard's own OnClick. The heading reads spent and left; a known list comes off the pet book (HasPetSpells, GetSpellBookItemName with 'pet'), dropping entries with no rank line as commands. Unverified in game: that pet book entries carry a rank line on 2.5.6, and that the selection taken from insecure Lua does not taint the secure click. If the error persists, turn on the gear trace's BLOCKED line to name the call.  Gate. 67-pet-training presses through CraftCreateButton; check.sh green in the hook.
