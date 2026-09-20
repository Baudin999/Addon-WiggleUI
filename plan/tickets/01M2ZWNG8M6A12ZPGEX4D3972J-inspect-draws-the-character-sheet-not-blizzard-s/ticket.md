---
revision: 5
id: 01M2ZWNG8M6A12ZPGEX4D3972J
type: task
status: todo
title: "Inspect draws the character sheet, not Blizzard's window"
---

Inspect on a player's right click menu opens this addon's own character sheet
drawn for them, instead of loading Blizzard's three-tab window.

## What it is

The same `Character/Paperdoll.lua` page, built with one flag. The flag changes
four things and the head of that file argues each one:

- **No secure squares.** A secure square carries `/use <slot>` written at build
  and the slot number in it is yours whoever the page is about, so a right click
  on somebody else's chest row would take your own chestpiece off. The attribute
  cannot be rewritten in a fight either, so "clear it on the subject change" is
  not an answer. The inspect page never grows one: the row is a hover and shift
  over a piece links it, which is what the client's own inspect frame answers
  with. That is also why the window is an ordinary window and opens, closes and
  moves mid pull, where the sheet needs a snippet on the C key.
- **No durability, no stone countdown, no cooldown arc.** All three read a call
  that takes a slot and no unit at all, so the honest version is no mark rather
  than yours drawn under their name.
- **Four different badges.** Item level and empty slots carry over. Durability
  and your miss chance cannot, and the two that replace them are the ones a raid
  leader opens an inspect for: enchants on, of the eleven enchantable slots with
  a piece in them, and gems in, of the sockets they are wearing. Both go red on
  the first one short and the hover names the slot.
- **Two tabs instead of four.** UnitStat, UnitArmor, UnitAttackPower, weapon
  skill and a faction standing are all nil or yours-only for another unit. What
  the server does send is their gear and their talents, so those are the two.

## The files

- `Character/Inspect.lua` — who, and the conversation with the server. Not
  Unit/Spec.lua's inspect: no queue, no retry gap, and the inspect is held
  rather than handed back, because the talents tab reads the client's inspect
  tables for as long as the window is open. Held by GUID, so a token that stops
  meaning the person closes the window with a line saying whose sheet went.
- `Character/Theirs.lua` — the four readings and the two column tabs.
- `Character/InspectWindow.lua` — the window.
- `Character/InspectBlizzard.lua` — the cage. `InspectUnit` is a plain global
  and taking it is the whole gesture: there is no binding for inspect, the menu
  entry calls it, and Blizzard_InspectUI then never loads at all.
- `Character/Worn.lua` — every reader takes a unit and defaults to you.
- `Talents/Read.lua` — `Tabs` and `Tree` take the inspect flag.

## Gates

- `52-inspect` in the harness: the refusals, the empty state before the server
  answers, the four badges against a character built with one enchant and one
  gem missing, the three marks the page does not draw, no use attribute on any
  square, the two tabs, the talent flag, opening and closing in a fight, the
  re-ask when their gear moves, the frame's own OnHide handing the inspect back,
  and the player's own sheet still reading the player with an inspect open.
- `client/26-inspect.lua`: a second character on the other end of the four
  inventory calls, answering nothing until INSPECT_READY.
