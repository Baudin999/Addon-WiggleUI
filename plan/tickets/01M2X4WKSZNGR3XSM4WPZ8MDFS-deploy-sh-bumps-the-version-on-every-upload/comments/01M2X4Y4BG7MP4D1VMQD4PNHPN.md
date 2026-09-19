---
revision: 5
id: 01M2X4Y4BG7MP4D1VMQD4PNHPN
---

Landed in 6ef4e17. Bump raises the last part (1.9 -> 1.10). Refuses to run if the three version files hold uncommitted edits, so a Release commit carries only the number. Tested on a scratch repo with a stub release.sh: failure restores 1.9 with an empty diff, success commits and tags v1.10.
