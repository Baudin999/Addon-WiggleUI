---
revision: 5
id: 01M2TEVB6NDDX5BY806SN13YA9
type: feature
status: done
title: "The enemy bar's debuff list is filled by drag and by name, not by id"
---

The "Debuffs on the bar" section in `src/UnitFrames/Panel.lua` takes a typed
spell id. Every other list in the addon (Buffs, Cooldowns) is a row of
`ui.DropSquare`s you drag spells onto.

Wanted, from the user on 2026-09-18:

- drag a spell out of the spellbook onto the row;
- drag a talent out of the talent window onto the row;
- start typing a name and pick the debuff from what matches;
- never think about rank.

Rank is already solved by the name match in `EnemyBars.Resolve`. What is not
solved is that the thing you drag is often not the aura that lands: Deep Wounds
12162 is the talent, Deep Wound 12721 is the bleed. `REPLACED` in
`EnemyBars.lua` is that mapping typed by hand for one talent. A baked table of
player-class debuffs, with the spell-to-aura edges from SpellEffect's trigger
spells, replaces it and feeds the name search.
