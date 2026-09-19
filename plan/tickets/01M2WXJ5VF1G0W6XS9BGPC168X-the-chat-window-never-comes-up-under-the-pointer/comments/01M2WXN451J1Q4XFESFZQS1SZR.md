---
revision: 5
id: 01M2WXN451J1Q4XFESFZQS1SZR
---

Cause. UI.Reveal's catcher sat at the frame's own level, under every child; the chat window is children edge to edge, so OnEnter never fired.  Fix. 880d9d8: at rest the catcher sits one level over the highest descendant (walked each rest, the chat builds rail and entry after Theme.Wear); on enter it turns motion off so links and buttons answer, the recheck ticker turns it back on. UI.Unreveal lifts it for /wk unlock. EnableMouse(true) would re-enable clicks, so only SetMouseMotionEnabled toggles.  Gate. 88-theme-veil asserts the hit test finds the catcher at rest, the child once up, and the click passes through.
