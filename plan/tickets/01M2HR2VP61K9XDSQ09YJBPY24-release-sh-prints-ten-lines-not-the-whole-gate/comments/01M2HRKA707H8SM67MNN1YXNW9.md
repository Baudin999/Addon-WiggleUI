---
revision: 5
id: 01M2HRKA707H8SM67MNN1YXNW9
---

Fix. release.sh sends the gate, the zip listing and the curl bodies to dist/release.log and prints a line a step, the reasons under a failed step (ten at most) and a tally. CF_API_TOKEN and CF_PROJECT_ID are checked before the gate. check.sh runs a harness run silently and on a failure prints one "harness FAIL as <run>: <assertion>" line each, or the tail when a run crashed; luacheck runs -q. The pre-commit harness run is quiet on a pass too.  Gate. Driven in a scratch copy with a fake check.sh: the failing gate prints two reasons and exits 1, a pass prints four lines and exits 0, --upload with no token stops before the gate.
