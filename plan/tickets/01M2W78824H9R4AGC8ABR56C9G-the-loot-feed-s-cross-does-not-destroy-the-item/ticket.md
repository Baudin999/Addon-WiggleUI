---
revision: 5
id: 01M2W78824H9R4AGC8ABR56C9G
type: bug
status: doing
title: The loot feed's cross does not destroy the item it is pressed on
---

The cross and the can on a loot feed row are built by UI.Button, which set OnClick and never registered its clicks, so they were the one family of buttons left off yesterday's UI.Press.Clicks. Report 2026-09-19: "when I press the x in the loot feed, the item does not get deleted".

Fix. UI.Button registers through UI.Press.Clicks(button, "up", "LeftButton") whenever it is handed onClick.

Gate. 40-loot-watch asserts both row buttons carry wkEdge "up" and LeftButtonUp.
