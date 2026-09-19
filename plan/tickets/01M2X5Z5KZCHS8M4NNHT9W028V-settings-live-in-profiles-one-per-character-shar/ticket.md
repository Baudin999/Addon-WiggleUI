---
revision: 5
id: 01M2X5Z5KZCHS8M4NNHT9W028V
type: feature
status: doing
title: "Settings live in profiles, one per character, shared by a pasted string"
---

Every setting the reset writes moves out of the flat account table into a
named profile. Each character points at one, and gets its own on first login,
copied from the screen the account had before the split (kept as `Shared`).
Records the reset keeps (purse, groups, drops, CVar notes) stay account-wide.

- Core/Core.lua: `ns.db` is the active profile, with a metatable that sends
  every non-Restorable key to WarriorKitDB. One rule decides which side a key
  lives on, the same rule the reset already uses.
- Profiles/: switch, copy to a new name, delete, export and import as a
  `WK1:` string. The parser never runs loadstring; import keeps only keys a
  feature registers, of the type it registers.
- `/wk profile` and a Profiles page under Under the hood.
- scripts/bake-defaults.lua reads the baking character's profile.
