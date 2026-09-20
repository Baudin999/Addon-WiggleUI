---
revision: 5
id: 01M2YZJVD8A4N8A5GZ6YSJ3CNT
type: bug
status: todo
title: The setup's colours page is drawn out of the bottom of its window
---

Seven palettes in three columns is three rows of cards on the colours page.
The setup window was a fixed 400 units tall, which is the mode page's one row
and nothing over, so the last row was drawn through the footer and off the
bottom edge of the window. Reported from the game with a screenshot: Fire sits
below the window's own border.

Fix. `src/Setup/Setup.lua` had `HEIGHT = 400`. It now asks each page how much
room its cards need and takes the tallest answer, so the colours page decides
the window and an eighth palette takes it with it.

Gate. `scripts/harness/sections/00-setup.lua` walks all five pages and fails if
anything shown inside the window hangs below the window's own bottom. Put the
400 back and it fails with "the setup's colours page hangs 52 units below the
bottom of its own window".
