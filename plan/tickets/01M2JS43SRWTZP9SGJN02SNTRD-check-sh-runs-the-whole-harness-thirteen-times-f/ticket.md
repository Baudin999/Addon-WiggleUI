---
revision: 5
id: 01M2JS43SRWTZP9SGJN02SNTRD
type: task
status: doing
title: check.sh runs the whole harness thirteen times for one login check
parent: 01M1XJZSDGJ90YGY9ZP6HBYPS9
---

`scripts/check.sh:1498` runs all 115 sections once per spec: four classes with
three specs each, plus HUNTER, so 13 full runs. `scripts/hooks/pre-commit:32`
then runs the WARRIOR suite a 14th time. It loads the owner's machine hard
enough that removing the harness was on the table.

The spec runs exist for the asserts that fire at PLAYER_LOGIN, in
`Cooldowns.All` and `Upkeep.Fixed` (the comment at `check.sh:1455`). Only
`58-spec.lua` drives a spec, and 83 of the 115 sections never name a class.

Fix. One full run as WARRIOR. The twelve spec runs and HUNTER stop after
`00-login` through the runner's existing third argument. The hook stops
running the harness a second time, because check.sh already did.

Gate. check.sh still fails on a login error for any spec, and still fails on
any section as WARRIOR.
