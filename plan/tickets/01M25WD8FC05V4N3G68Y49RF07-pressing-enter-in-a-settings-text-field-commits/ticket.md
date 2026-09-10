---
revision: 5
id: 01M25WD8FC05V4N3G68Y49RF07
type: task
status: todo
title: Pressing Enter in a settings text field commits it twice
---

kit.TextField in src/UI/Widgets.lua commits on OnEnterPressed and again on
OnEditFocusLost. OnEnterPressed calls ClearFocus before Commit, and
ClearFocus fires OnEditFocusLost, so one Enter runs the setter twice.

Seen on the enemy bar panel's "or add any spell by id" field: typing a name
instead of an id prints "a spell id is a whole number" twice. Eight fields
use the widget, and any setter with a side effect runs it twice: an add
reports twice, a whisper text saves twice.

Fix: OnEnterPressed only clears focus, and the focus-lost handler is the one
commit.
