---
revision: 5
id: 01M2WMGZ5Y8WYXBW2XAZ1JBNG8
type: task
status: done
title: The loot feed has no scroll bar and keeps its last 30 drops
parent: 01M2WM7H2QD0KYVCRBZZ25T564
---

Asked on 2026-09-19.

- No scroll bar on the loot feed: BuildBar (src/UI/Feed.lua) stays for any
  feed that wants one, the loot feed stops asking. The wheel still scrolls.
- The loot feed holds 30 entries (opts.held, set in src/Feeds/Loot.lua), so a
  session is not an ever-growing list. Check what the combat feed holds and
  leave it alone unless it is the same setting.
