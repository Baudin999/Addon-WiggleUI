---
revision: 5
id: 01M2JZNQQWPP2SWKPZS13TW6YC
---

Reported in game on c2cc570: a click on a teachable ability (Growl rank 4) teaches nothing and raises no error.  Cause. The hover armed the teach button by running Blizzard's CraftFrame_SetSelection inside a pcall, and the press relied on that selection and an enabled CraftCreateButton surviving until the click. Blizzard's code from classic_anniversary does not show which link failed, and the harness mocks all of them. The fix removes the dependency instead of guessing one.  Fix. 37760b6. WarriorKitBeastTeach's PreClick calls SelectCraft and enables CraftCreateButton, then type=click presses it. The hover only lays the button over the row. ns.CraftSelect no longer calls CraftFrame_SetSelection.  Unverified in game: that a PreClick on the secure button leaves the delegated OnClick secure. If a press still does nothing, run /wk character trace for the BLOCKED line.  Gate. 67-pet-training disables the create button and selects another row between the hover and the press; the press still teaches the hovered row. Hook green.
