---
revision: 5
id: 01M2XB28TMZ1TRTHGW3BY2VPZW
type: task
status: todo
title: "A mouse wiggle pins exploration's hover elements up, another drops them"
---

In the exploration theme, a quick side-to-side shake of the mouse brings up every element the theme keeps under the pointer (chat, quests, bars) and a second shake puts them back. It sits next to the hover reveal and does not replace it. The loot feed stays hidden.

Detector: horizontal direction reversals of the cursor, 40 px or more each, four inside 0.6 s. Skipped while mouselooking so camera turns never fire it.

Gate: a harness section feeds synthetic cursor paths through the detector and checks that the pin toggles the veils.
