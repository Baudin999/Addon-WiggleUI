---
revision: 5
id: 01M2SPDXS1VXPKVAV1B786RWEP
type: task
status: todo
title: The Cooldowns page drops the list of spells you added
---

The Cooldowns page ended on a reading, "2 of 6: Blood Fury, Intimidation", listing the spells added by hand. The squares on the row already show them. Remove the reading from `src/Cooldowns/Feature.lua` and `Cooldowns.Own()` from `src/Cooldowns/Cooldowns.lua`, which nothing else calls. The six-slot ceiling stays and still refuses with its own message.
