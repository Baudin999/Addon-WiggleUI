---
revision: 5
id: 01M2HR2VP61K9XDSQ09YJBPY24
type: task
status: todo
title: "release.sh prints ten lines, not the whole gate"
---

`./scripts/release.sh --upload --type beta` scrolled the whole gate onto the
screen: 271 luacheck `Checking … OK` lines, a summary line per harness section
for each of the thirteen class runs, and the failure buried in the middle.

Wanted, roughly:

    Starting release
    ✓ gate passed
    ✓ build
    ✓ upload to CurseForge
    release done 0 errors / 0 warnings

Fix. The gate's full output goes to dist/release.log. release.sh prints one
line a step and, when a step fails, only the lines that say why. check.sh keeps
a harness run's chatter to itself unless the run failed, and luacheck runs `-q`.
