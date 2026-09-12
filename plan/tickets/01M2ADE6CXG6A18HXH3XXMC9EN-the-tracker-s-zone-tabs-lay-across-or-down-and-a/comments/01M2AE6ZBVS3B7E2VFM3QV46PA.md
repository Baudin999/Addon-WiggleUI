---
revision: 5
id: 01M2AE6ZBVS3B7E2VFM3QV46PA
---

Correction to the comment above: the pre-commit hook did not cover this commit. .git/hooks holds only the samples and core.hooksPath is unset, so scripts/hooks/pre-commit is not installed in this checkout and neither 98f44f3 nor 90d899d was gated by it. What did run on 90d899d: shape.lua, trees.lua, luacheck and harness section 85, all at zero. What did not: the rest of the harness, the other class runs, and check.sh's own TOC and prose rules.
