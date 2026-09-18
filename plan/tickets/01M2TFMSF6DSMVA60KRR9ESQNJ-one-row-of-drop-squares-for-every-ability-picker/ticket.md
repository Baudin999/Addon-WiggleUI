---
revision: 5
id: 01M2TFMSF6DSMVA60KRR9ESQNJ
type: feature
status: todo
title: One row of drop squares for every ability picker
---

Four pages pick abilities by dragging onto a row of squares, and each one
carries its own copy of the same eight or nine functions on top of
`ui.DropSquare` (`src/UI/Widgets.lua`):

| page | file | Say | Take | Lift | Landed | Drop | Says | Square | Lay | Rest |
|---|---|---|---|---|---|---|---|---|---|---|
| buff nag | `src/Buffs/Panel.lua` | 69 | 77 | 107 | 117 | 144 | 171 | 202 | 227 | 254 |
| cooldown row | `src/Cooldowns/Panel.lua` | 81 | 91 | 138 | 152 | 184 | 216 | 242 | 271 | 299 |
| enemy bar debuffs | `src/UnitFrames/DebuffPanel.lua` | 66 | 85 | 116 | 121 | 139 | 155 | 167 | 190 | |
| extra bars | `src/AdHoc/Panel.lua` | 60 | 68 | 83 | 93 | 112 | 127 | 138 | 161 | |

Each copy does the same work: a refusal printed once per reason, a spell
read off the cursor through `ns.SpellIdOnCursor`, a drag that records a
slot on start and reads `ns.MouseFocus()` on button-up, a drop or right
click on one square, a hover note, a pool of squares built at login, and a
wrapped layout at the page's width. The debuff row was the fourth copy
(`49700d0`) and should have been the extraction.

## Wanted

One widget in the UI layer, say `UI.SquareRow` in `src/UI/SquareRow.lua`,
that owns:

- the pool, built once at a ceiling, and the wrapped layout, returned as a
  measure for `ui.Custom`;
- the empty square at the end that a drop lands on;
- the drag between squares (lift on start, `ns.MouseFocus` on button-up):
  onto another square is a move, anywhere else is off;
- the right click as remove;
- the spell off the cursor, and the talent drop through `UI.Carry`
  (`src/UI/Carry.lua`) for any page that asks for it;
- the say-once refusal.

Each page hands it an adapter and nothing else: what is in slot N (icon,
name), put(value, at), move(from, to), remove(at), the hover note, and an
optional `resolve` that turns a dropped spell or talent into what the page
stores. The debuff page's `resolve` is `ns.DebuffBook.Aura` and
`ns.DebuffBook.ForTalent`.

The buff page is the odd one: two lines that are sets rather than one
ordered list, a drag onto the other line adds rather than moves, and a tray
under the row. The widget has to carry that as more than one band sharing a
pool, or the buff page stays on its own with the reason written down. Decide
that first by reading `src/Buffs/Panel.lua:1-60`.

## Done when

- All four pages draw their rows through the one widget, migrated in the
  same commit. No page defines Take, Lift, Landed or Lay of its own.
- A gate in `scripts/check.sh` fails when a file outside `src/UI/` defines a
  local `Lift` + `Landed` pair or calls `ns.SpellIdOnCursor` from a
  `take` of its own, with an allow-list that needs a reason per entry.
- The harness sections that drive these pages still pass: `30-buff-page`,
  `42-cooldown-row`, `07-tracked-debuff`, and the AdHoc one.
- `./scripts/check.sh` at 0 warnings, 0 errors.
