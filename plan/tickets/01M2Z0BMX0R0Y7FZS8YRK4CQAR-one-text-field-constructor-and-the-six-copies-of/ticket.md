---
revision: 5
id: 01M2Z0BMX0R0Y7FZS8YRK4CQAR
type: task
status: todo
title: "One text field constructor, and the six copies of it"
---

`CreateFrame("EditBox")` appears eight times in `src/`, and seven of them are
the same field: a sunken box, an edit inside it at four pixels of padding, the
addon's own font and text colour, no autofocus, a letter cap, and six scripts
that are the same six every time.

| what | file | line |
|---|---|---|
| the kit's text row | `src/UI/Widgets.lua` | 1888 |
| the window search box | `src/UI/Window.lua` | 743 |
| the debuff page's add-by-name | `src/UnitFrames/DebuffPanel.lua` | 263 |
| the mail window's fields | `src/Mail/Window.lua` | 124 |
| the console's editor | `src/Console/Feature.lua` | 96 |
| the console's output | `src/Console/Feature.lua` | 135 |
| the chat copy box | `src/Chat/Copy.lua` | 61 |
| the profile string box | `src/Profiles/Window.lua` | 68 |

The six scripts are `OnEnterPressed`, `OnEscapePressed`, `OnEditFocusGained`
(close the dropdown, stop a key capture, say the addon is typing, tint the box
selected), `OnEditFocusLost` (stop typing, tint it back) and `OnHide` (drop the
focus). Two copies forget `UI.Typing` and `UI.StopCapture`, which is how a key
capture stays armed while you type into a mail.

`UI.Field` in `src/UI/Widgets.lua` is the constructor and `ui.TextField`
already goes through it. It takes the width, the height, the font size, the
letter cap and what to do on commit; it hands back the box with `box.edit` on
it, which is the shape the call sites already keep.

## Wanted

- The remaining six migrated onto `UI.Field`, in one commit.
- `opts.ghost` for the two that draw a word in an empty field, `opts.multiline`
  for the three that are a paragraph rather than a line, and `opts.box = false`
  for the two that live on a scroll canvas and are anchored by their page.
- A gate in `scripts/check.sh`: `CreateFrame("EditBox"` outside
  `src/UI/Widgets.lua` fails, with a path-keyed allow-list that needs a reason
  per entry, in the shape the four `*_ALLOWED` lists in that file already use.

## Done when

- One `CreateFrame("EditBox"` in `src/`, and it is in `UI/Widgets.lua`.
- The harness sections that drive these windows still pass: the options page,
  the mail window, the console, the debuff page and the chat copy box.
- `./scripts/check.sh` at 0 warnings, 0 errors.
