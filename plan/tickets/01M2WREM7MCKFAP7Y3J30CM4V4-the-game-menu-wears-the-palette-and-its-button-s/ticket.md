---
revision: 5
id: 01M2WREM7MCKFAP7Y3J30CM4V4
type: task
status: todo
title: "The game menu wears the palette, and its button sits under Options"
---

The Escape menu drew in flat greys whatever the palette, hung the WarriorKit button off its foot under Return to Game, and kept Blizzard's air: 32 at the top, 28 at the sides, 20 between sections, 0 between buttons, and 8 round ours.

- `src/Core/Menu.lua`: the button joins Blizzard's own column. GameMenuFrame is MainMenuFrameTemplate, a VerticalLayoutFrame, on both classic_anniversary and classic_era (Gethe/wow-ui-source). Ours carries Options' layoutIndex plus 0.5 and the client's layout places it. Grow and the bottom anchor are gone.
- `src/Core/MenuSkin.lua`: a palette with a painting puts the menu on it, with the title over the painting and a rule under it, the same as UI.Window. The layout reads M.pad (12) on all four sides and between sections, and M.rowGap (4) between buttons. The switch puts Blizzard's paddings back.
- `src/UI/Backdrop.lua`: `Backdrop:Each`, so the skin can mark its tiles and hide them.
- Harness stub rebuilt to the real template: a pool, InitButtons on show, the layout pass. The old one was a chain of named buttons that neither client has.
