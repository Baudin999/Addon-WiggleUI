---
revision: 5
id: 01M2XBGYPAF5W5TH8N076YBN3G
type: task
status: done
title: Exploration draws the minimal XP line; a wiggle swaps in the expressive
---

In a theme with hover elements the experience rail's style follows the pin: minimal at rest, expressive while pinned. Theme gains Theme.OnPin(fn) so a part can redraw on a shake; Progress/Rails.lua reads the pin in Minimal() and re-applies on it. The style setting still rules in the other two themes.
