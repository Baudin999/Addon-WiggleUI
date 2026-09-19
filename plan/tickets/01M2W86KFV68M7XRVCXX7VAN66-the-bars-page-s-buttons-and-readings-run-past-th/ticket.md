---
revision: 5
id: 01M2W86KFV68M7XRVCXX7VAN66
type: bug
status: done
title: The bars page's buttons and readings run past the ? column
---

`Paired` rows stop 12 px + rowGap short of the row's right edge, so the `?` hint
mark has a column and every control ends on one line (src/UI/Widgets.lua).
`kit.ActionPair` and `kit.Reading` anchor to the row's full right edge instead,
so on the bars page the two button pairs and the four readings stick out one
column to the right of the sliders and pickers above them.
