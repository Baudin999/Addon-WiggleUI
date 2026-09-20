---
revision: 5
id: 01M2Z58P3R3Q69CXMDPX49438X
type: bug
status: todo
title: barsSpellsSeeded latches true on a class that seeded nothing
---

Found while working out why a hunter's stings do not light on the enemy bar
debuff row. The row itself is fine. This is the latch under it.

`EnemyBars.Spells()` at `src/UnitFrames/EnemyBars.lua:459` seeds the watched
debuff list from `ns.Class.Of("debuffs")` and then writes
`barsSpellsSeeded = true` whether or not it got anything. `Class.Of` returns nil
for any class with no file under `src/Class/`, and the comment at
`src/Class/Class.lua:182` is explicit that a part finding nothing there does not
build. So on a hunter, a rogue, a druid, a paladin or a warlock the row seeds
empty and then records that it has been seeded.

Why it matters later rather than now. When `Class/Hunter.lua` lands under
`01M1XJZXCNPFEXZ02D6C12QR0A`, every hunter who has already logged in carries
`barsSpellsSeeded = true` with an empty or hand-typed list, so none of them
picks up the defaults that card ships. Kibbling is one already:
`WTF/.../Kibbling/SavedVariables/WiggleUI.lua:40` holds `{3034, 3043}`, both
typed by hand, with the flag true further down at `:1424`. The card's three
specs list Serpent Sting under Debuffs, and he will not get it.

Fix. Set the flag only when `Class.Of("debuffs")` handed back a list. A class
with no file leaves it false, so the seed runs again when the file arrives.

Gate. Two class runs in `CLASS_SECTIONS`: one whose `Of("debuffs")` is nil
leaves the flag false, one whose `Of("debuffs")` is a list leaves the saved list
equal to it. The harness can already force a class, `lua5.1 scripts/harness.lua
src HUNTER class`.

Ruled out on the way here. The baked data is complete: `1978` Serpent Sting,
`3034` Viper Sting and `3043` Scorpid Sting are all in `AURAS`
(`src/UnitFrames/Debuffs.lua:148`, `:181`, `:144`), and `LEADS` carries no sting
entry. The row lights correctly on a hunter when the list has the right id in
it, checked against a forced list in a scratch copy of the harness.
