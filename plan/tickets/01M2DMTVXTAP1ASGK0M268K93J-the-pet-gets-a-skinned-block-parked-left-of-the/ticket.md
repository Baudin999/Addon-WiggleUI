---
revision: 5
id: 01M2DMTVXTAP1ASGK0M268K93J
type: task
status: todo
title: "The pet gets a skinned block, parked left of the player portrait"
---

With a pet out, Blizzard's PetFrame drew in its own art. PetFrame is declared
under PlayerFrame and stayed on the screen with PlayerFrame caged.

A fourth block in src/UnitFrames/Skin.lua SPECS, key `pet`, parked by
Block.Flank in src/UnitFrames/Block.lua. PetFrame is in the hideBlizzUnitFrames
list in src/Core/BlizzHide.lua.
