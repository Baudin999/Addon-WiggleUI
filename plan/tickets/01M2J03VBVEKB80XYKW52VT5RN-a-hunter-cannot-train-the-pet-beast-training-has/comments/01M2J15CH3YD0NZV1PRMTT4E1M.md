---
revision: 5
id: 01M2J15CH3YD0NZV1PRMTT4E1M
---

Reported in game on b65fccb. A press on an ability raises an interface error, and the page does not show what is already spent on the pet. Cause of the first. DoCraft is protected for addons on 2.5.6; Blizzard calls it only from CraftCreateButton's own OnClick, and the rows call it from insecure Lua. Fix. A secure type=click button onto CraftCreateButton, laid over the hovered row once CraftFrame_SetSelection has picked it; the heading says spent and left, and the pet's own book lists what it knows.
