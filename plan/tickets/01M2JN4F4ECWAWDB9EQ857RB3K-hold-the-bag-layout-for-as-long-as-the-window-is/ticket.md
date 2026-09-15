---
revision: 5
id: 01M2JN4F4ECWAWDB9EQ857RB3K
type: task
status: done
title: Hold the bag layout for as long as the window is open
parent: 01M2JN4ESP53ET2Q080EAA8RJD
---

`Grid.Paint` holds the layout only while a merchant is open. Hold it from the first paint after the window opens until it hides. A removed item leaves an empty square.

The hold breaks when a slot no held square points at gains an item, when a held square's slot now holds an item from a different pile, and when the columns or the zoom change.
