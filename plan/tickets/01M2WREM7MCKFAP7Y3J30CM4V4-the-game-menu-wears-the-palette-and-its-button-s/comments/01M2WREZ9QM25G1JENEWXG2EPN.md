---
revision: 5
id: 01M2WREZ9QM25G1JENEWXG2EPN
---

Landed in 2722c68 and the pre-commit gate passed. Harness section 34 covers the flat fill only, because the harness palette is dark and has no painting. The painted path has only been checked in game, after a /reload on a painted palette. Taint: the paddings and our layoutIndex are addon writes, so Blizzard's layout pass runs tainted, the same as the old SetHeight did. The menu and its buttons are not protected, and Logout's OnClick is still Blizzard's own closure.
