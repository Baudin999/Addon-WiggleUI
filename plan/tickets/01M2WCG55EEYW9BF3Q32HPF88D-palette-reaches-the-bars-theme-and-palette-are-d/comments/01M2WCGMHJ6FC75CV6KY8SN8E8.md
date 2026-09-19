---
revision: 5
id: 01M2WCGMHJ6FC75CV6KY8SN8E8
---

Landed in ad4b42b. Cause: Theme.Paint only wrote UI.Color; the bars read Unit/Color.lua, which had its own literals. Fix: palettes carry a unit table (backdrop, seam, iron, cast, experience, rested, swingMain, swingOff), loaded before Unit/Color.lua; Unit.Color.Paint copies in place and reshapes. UI/Theme.lua now loads right after UI/Pixel.lua so UI/Ability.lua can use the palette. Gate: harness 88 paints forest and checks the tables the bars hold. Forest and desert cast/xp/swing colours were picked without a look in game.
