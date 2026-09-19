---
revision: 5
id: 01M2W7KFN43EX1TE2R1EF99A1X
type: task
status: doing
title: A slider on the bars page sets the key's size to the pixel
---

A "key" slider under "square" on the bars page sets the keybind text size per bar, 7 to 32 px in one-pixel steps. Whole pixels because Ability.Size floors every string on a square: a fractional font size draws across two rows. Unset, the key stays half the square (Ability.KeySize). Set, it is stored as barLook.keySize and a square resize leaves it alone.
