---
revision: 5
id: 01M2Z56ANDMF90DZE5YV7CVEHX
---

Kibbling's stings not lighting up is this card, not a bug in the row.

Cause. `Class.Of("debuffs")` is nil on a hunter, so `EnemyBars.Spells()` at
`src/UnitFrames/EnemyBars.lua:459` seeds nothing and still writes
`barsSpellsSeeded = true`. The row ships empty on this character and says so
nowhere. Everything on it was typed in by hand.

What is actually saved. The live file is `WiggleUI.lua`, not the stale
`WarriorKit.lua` beside it. `WiggleUICharDB.barsSpells = { 3034, 3043 }`, and
Wowhead's tbc pages name those Viper Sting and Scorpid Sting. Serpent Sting,
1978, is not on the list at all. So the row watches the two stings a level 40
hunter almost never casts and not the one he casts every pull. Nothing lights
because nothing it watches lands.

Ruled out. The baked data: 1978 and 3034 are both in `AURAS`, `LEADS` carries
no sting, so `Book.Aura` and `Book.Canonical` return the sting itself. The
plumbing: a probe section run as `lua5.1 scripts/harness.lua src HUNTER`, with
the list forced to `{3034, 3043}`, repairs clean, resolves with 0 unresolved,
and lights the square `mine` off a "player" aura. The aura read: Details and
Details_RaidCheck both call `C_UnitAuras.GetDebuffDataByIndex` on this install,
so the call `EnemyBars.lua:847` prefers exists and works. A silent load error:
the whole TOC loads under the harness.

Fix for today, no code. Type the name into the debuff page's add-by-name box.
Serpent Sting goes on as 1978 and the square lights.

Fix for this card. The three specs above already list Serpent Sting under
Debuffs. Landing `Class/Hunter.lua` seeds a fresh hunter correctly.

The one thing to change while you are in there. `barsSpellsSeeded` latches on a
class that seeded nothing, so Kibbling will not pick up the hunter defaults
when this card lands, and neither will any other hunter who has logged in
since. Only set the flag when `Class.Of("debuffs")` returned a list. A class
with no file should leave it false.

Gate. `07-tracked-debuff` covers the row itself. What it does not cover is the
seed: a class run whose `Of("debuffs")` is nil must leave `barsSpellsSeeded`
false, and a class run whose `Of("debuffs")` is a list must leave the list
equal to it. Both belong in `CLASS_SECTIONS`.
