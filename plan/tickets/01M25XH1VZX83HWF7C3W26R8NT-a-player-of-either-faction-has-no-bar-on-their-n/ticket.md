---
revision: 5
id: 01M25XH1VZX83HWF7C3W26R8NT
type: task
status: doing
title: A player of either faction has no bar on their nameplate
---

Reported: no unit bar on any player, own faction or the other one.

Two causes, both in the plate path.

- `Wanted` at src/UnitFrames/EnemyBars.lua:312 opens on `UnitCanAttack`.
  A player of your own faction is never attackable outside a duel, and a
  player of the other faction on a PvE realm is not attackable until flagged,
  so neither passes.
- The plate is never there. On 2.5.6 the friendly player plate is
  `nameplateShowFriendlyPlayers` (Blizzard_SettingsDefinitions_Frame/
  Nameplates.lua:472 on the classic_anniversary branch), and the live
  config-cache holds no value for it, so it is at the client's default of off.
  A bar is a child of a plate.

Fix. Every player but you gets a bar on the plate path; a mob still needs
`UnitCanAttack`. The list keeps the old rule, because its eight rows are the
enemy panel and a city would fill them. `nameplateShowFriendlyPlayers` is
borrowed while `bars` is on, prior kept in `platesFriendsPrior` like the other
three CVars. A player's gauge wears the class colour instead of threat, since
a player has no threat table, and a name goes grey for worthless only on
somebody you can attack.
