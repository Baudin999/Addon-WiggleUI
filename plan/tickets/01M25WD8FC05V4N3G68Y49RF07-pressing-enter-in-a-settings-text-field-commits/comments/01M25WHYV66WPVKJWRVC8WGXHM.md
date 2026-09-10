---
revision: 5
id: 01M25WHYV66WPVKJWRVC8WGXHM
---

Cause. OnEnterPressed called ClearFocus and then Commit, and ClearFocus fires OnEditFocusLost, which commits too. Fix. OnEnterPressed only clears focus; the focus-lost handler is the one commit. Gate. Section 16 builds a TextField, presses Enter and counts the setter's calls. HEAD's Widgets.lua fails it with two.
