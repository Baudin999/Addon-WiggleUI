local ADDON, ns = ...

-- Written by scripts/bake-backdrops.sh. Do not edit: change the painting or
-- the numbers at the top of the bake, and run it again.
--
-- One entry per palette that has a painted frame. Each piece is a texture
-- and the size it is drawn at in window units; corner, top and left are the
-- frame's thickness outside the window, and fade is how far each rail and
-- corner reaches in over the floor. A palette with no entry keeps the flat
-- window fill.

ns.Backdrops = {
	forest = {
		thickness = { left = 18, top = 16, right = 18, bottom = 16 },
		fade = 5,
		corner = 36,
		Middle = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-Middle.tga", 100, 104 },
		Top = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-Top.tga", 100, 21 },
		Bottom = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-Bottom.tga", 100, 21 },
		Left = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-Left.tga", 23, 104 },
		Right = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-Right.tga", 23, 104 },
		TopLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-TopLeft.tga", 36, 36 },
		TopRight = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-TopRight.tga", 36, 36 },
		BottomLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-BottomLeft.tga", 36, 36 },
		BottomRight = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-BottomRight.tga", 36, 36 },
	},
	desert = {
		thickness = { left = 22, top = 30, right = 25, bottom = 24 },
		fade = 5,
		corner = 63,
		Middle = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Middle.tga", 100, 104 },
		Top = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Top.tga", 100, 35 },
		Bottom = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Bottom.tga", 100, 29 },
		Left = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Left.tga", 26, 104 },
		Right = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Right.tga", 29, 104 },
		TopLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-TopLeft.tga", 63, 63 },
		TopRight = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-TopRight.tga", 63, 63 },
		BottomLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-BottomLeft.tga", 63, 63 },
		BottomRight = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-BottomRight.tga", 63, 63 },
	},
}
