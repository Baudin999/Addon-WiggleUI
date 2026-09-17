---
revision: 5
id: 01M2QT3AT8Y4FBQGX9N1KDMXRF
type: task
status: todo
title: The pet block draws no happiness icon
parent: 01M1XJZXCNPFEXZ02D6C12QR0A
---

Blizzard's PetFrame draws a face beside a hunter's pet: happy, content or
unhappy. PetFrame is caged, and the pet block in src/UnitFrames/Skin.lua
carries a raid marker and nothing else, so an unhappy pet doing 75% damage
looks the same as a happy one.

Blizzard_UnitFrame/Classic/PetFrame.lua on classic_anniversary is the
reference. It reads `GetPetHappiness()` and `HasPetUI()`, hides the face when
either says this is no hunter pet, and crops
Interface\PetPaperDollFrame\UI-PetHappiness: happy 0 to 24/128, content 24/128
to 48/128, unhappy 48/128 to 72/128, all 23/64 tall. UNIT_HAPPINESS is the
event.

A fourth badge in src/UnitFrames/Block.lua BADGES, key `mood`, on the pet spec
only, painted by src/UnitFrames/Paint.lua.
