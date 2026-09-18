---
revision: 5
id: 01M2TAVW5JKY8V3STZTSM56CXS
---

Cause. The keys were set and drawn all along: a live read on 2026-09-18 gave GetBindingKey G, label text G, visible, white, 7 pt, one pixel in from the top right. A screen capture shows a faint G, T and R lost in the bright corner of the claw and fang icons. A 7 px key with a one pixel shadow does not hold off light art; the action bars lose sX and sC the same way.  Fix. Ability.Dress gives every square a keyPlate, black at 0.7 on ARTWORK sublevel 7 under the key, sized to the string in Ability.Size and shown by Ability.Bind only when there is a key. An outline was out: UI/Text.lua forbids one under 14 px.  Gate. Harness 05-pet-bar checks the plate is up on a bound square and down on an unbound one.
