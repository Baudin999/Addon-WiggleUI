---
revision: 5
id: 01M2TFH0ZPHD1EPM2PDXYXNEPR
---

Landed at 49700d0. The row is ui.DropSquare squares in UnitFrames/DebuffPanel.lua. Spells, talents and names all go through UnitFrames/Book.lua, which reads the baked UnitFrames/Debuffs.lua (scripts/bake-debuffs.sh, wago anniversary DB2). Talent drag is UI/Carry.lua, SetCursor plus MouseFocus on button-up, copied from OPie's RingEdit. Untested in the client: SetCursor with a talent's file id, and whether a talent square's OnClick fires after a drag released over it. Gate 0/0.
