---
revision: 5
id: 01M31B5YEZFHW71T2TW82TQXZV
type: task
status: todo
title: The settings window folds out a docs reader on the page you are on
---

The docs reader in the game, as asked for on 2026-09-21.

The settings window gets a fold-out panel that opens to the right. It opens on
the guide page that matches the settings page you are standing on, and from
there you can read any of the thirteen.

Why this shape and not a searcher, which is what was proposed first: a person
in the settings window is not mid-pull. They have the time to read, and the
control the paragraph describes is sitting a hand's width to the left of it.
Entry from the page you are on is what makes it a help button rather than a
book nobody opens twice.

What it needs:

- A page-to-part map. Every part already declares `name`, `order` and `help` in
  its `Feature.lua`; this adds the guide page it belongs to. That is the one
  new field and it is the whole of the contextual half.
- A baked Lua data file, the markdown parsed to a block list.
  `scripts/bake-guide-site.lua` already has the parser and the subset is
  closed, so this is a second writer on the same tree rather than a second
  parser. Roughly 60 KB of strings, which wants a `## LoadOnDemand` companion
  addon so a player who never opens it pays nothing at login.
- A renderer on `UI.ScrollView`, `UI.Wrap` and `UI.TextHeight`. Headings,
  paragraphs, the indented command blocks, bullets, the one table.
- Every `/wui ...` in a command block is a button that runs it. That is the
  thing the website cannot do and the reason to have this at all.

The screenshots do not come. The client reads TGA and BLP, `check.sh` enforces
power of two sides, and the thirteen at 1024x512 uncompressed are about 2 MB
each. Text only, and the pages that lean on a picture say "see the site" with
the URL in a read-only box you can copy out.

Depends on 01M31B5GCDS1KHDV8CZ3HTW7K8 for the parser and the page order.
