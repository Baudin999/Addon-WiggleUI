---
revision: 5
id: 01M2SXTR121RMWKESKEC3P8E8C
type: task
status: done
title: "One constructor per tooltip subject, one way to say where a box opens"
---

A worn item as a tooltip subject was a table written by hand in UnitFrames/Auras.lua (twice), Character/Paperdoll.lua, Character/Compare.lua and Buffs/Nag.lua, which built a note and rewrote its kind. An aura was written by hand twice in Auras.lua, once reading the filter and once hard-coding "buff".

Where the box opens had two spellings. Five subjects carried `place = UI.Tooltip.BESIDE` (Buttons/Square.lua, Buttons/Pet.lua, Auras.lua twice, UI/Chart.lua, which also carried `above = true`), and fourteen calls passed it as Tip.Open's fourth argument. Tip.Open read both.

UI/Tip.lua: `Tip.Worn(unit, slot, title)` and `Tip.Aura(unit, index, filter)`. Tip.Open reads `above` and `place` from its arguments only, and Tip.Hang takes them too, so a hover hung with Hang can open beside its owner.

Gate: check.sh fails on `kind = "inventory"|"buff"|"debuff"` outside UI/Tip.lua, and on `place = ...Tooltip.X` or `above = true` written as a table field.
