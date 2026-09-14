---
revision: 5
id: 01M2GB6DKE1C6JXWQN9ZAXECH7
---

Cause. Grid.Paint writes the new item onto a square and nothing re-enters it with the pointer resting still. The template's UpdateTooltip only fires while GameTooltip owns the button, so ours never runs.  Fix. Follow() in src/Bags/Grid.lua runs after the whole layout, asks ns.MouseFocus() for the square under the pointer, and re-enters it when its link or count differs from what Enter last told the box. Leave wipes that record. The first attempt checked focus inside Paint, before Place moved the squares, and re-entered a square that the relayout then slid away from the pointer. Do not put it back there.  Gate. scripts/harness/sections/74-bag-hold.lua swaps the tusk's slot to Linen Cloth under a parked pointer and asserts the box names whatever square is under it.
