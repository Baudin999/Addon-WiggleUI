---
revision: 5
id: 01M2XB8XGFRZZ7K3QQYGYFXQ28
---

Landed in 80c7168. Detector is UI/Wiggle.lua: four turns of 40 UI units or more inside 0.8 s, deaf for 1 s after. Theme.lua samples the cursor x at 50 Hz on UI.Forever under Perf slot 'wiggle', armed at PLAYER_LOGIN only when the drawn theme has a hover element. Pinned, Dress unreveals each hover frame and holds its veil at 1; unpinned, it goes back through UI.Reveal. IsMouselooking resets the leg so camera turns never count. Not verified in the client yet. If it fires by accident or is hard to trigger, tune SPAN, TURNS and WINDOW at the top of UI/Wiggle.lua. Gate: harness 88-theme-wiggle.
