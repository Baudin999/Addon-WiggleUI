---
revision: 5
id: 01M2X08YSPJY1SYW8X19PQEG3W
---

Landed in 0d422f7. progressStyle expressive|minimal; minimal pins BOTTOMLEFT at 0,0, width off UIParent in the frame's units, 4 px, gap -1 so the faction line shares a hairline, chrome edge, Gauge.ShowFloor hides the floor. No eased fill: section 50 forbids an OnUpdate under Progress/, so DialogueUI's 2 s animation and +N XP chip are left out on purpose. Harness note: sections 48 and 49 hand UIParent back at 0x0, so 50 sizes it for its own claim. Gate 0/0.
