---
revision: 5
id: 01M2GB3HN7BW3ZHTDYP7W8A0SB
type: bug
status: todo
title: Bag tooltip keeps the equipped item after the slot changes under it
---

Equip an item off a bag square with the pointer resting on it. The old piece lands in the slot and the square repaints, but the box over it still describes the item you just put on.

src/Bags/Grid.lua Paint writes the new link onto the square and nothing re-enters it. The template's UpdateTooltip only runs while GameTooltip owns the button, and our box is not GameTooltip.
