---
revision: 5
id: 01M2HWC96M9GMJ4HEPP07MPTRF
type: bug
status: todo
title: Talent names overlap their points; hovers miss the description
---

Two defects on the talent window, reported with a screenshot on 2026-09-15.

1. The heading row overlaps. `src/Talents/Board.lua` is 172 px wide (4 squares of 31, gaps of 16) and the tree name has no right anchor, so "Beast Mastery" and "Marksmanship" run under "23 points".

2. A hover does not show the description at once. The square resolves its tooltip arguments once on OnEnter, `Read.TipArgs` caches a failed probe as `false` for the session, and nothing rebuilds the box when the client's spell text lands (`SPELL_DATA_LOAD_RESULT`).
