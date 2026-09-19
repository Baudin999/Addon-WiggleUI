local ADDON, ns = ...

-- Written by scripts/bake-backdrops.sh. Do not edit: change the painting or
-- the numbers at the top of the bake, and run it again.
--
-- One entry per palette that has a painted frame. Each piece is a texture
-- and the size it is drawn at in window units; corner, top and left are the
-- frame's thickness outside the window, and fade is how far each rail and
-- corner reaches in over the floor. cover says the floor is one picture
-- drawn over the whole window, and its size is the picture's shape. A
-- palette with no entry keeps the flat window fill.

ns.Backdrops = {
	forest = {
		thickness = { left = 18, top = 16, right = 18, bottom = 16 },
		fade = 5,
		corner = 36,
		cover = true,
		Middle = { "Interface\\AddOns\\WarriorKit\\Media\\Forest-Middle.tga", 1408, 768 },
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
		cover = true,
		Middle = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Middle.tga", 1408, 768 },
		Top = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Top.tga", 100, 35 },
		Bottom = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Bottom.tga", 100, 29 },
		Left = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Left.tga", 26, 104 },
		Right = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-Right.tga", 29, 104 },
		TopLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-TopLeft.tga", 63, 63 },
		TopRight = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-TopRight.tga", 63, 63 },
		BottomLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-BottomLeft.tga", 63, 63 },
		BottomRight = { "Interface\\AddOns\\WarriorKit\\Media\\Desert-BottomRight.tga", 63, 63 },
	},
	arcane = {
		thickness = { left = 23, top = 30, right = 23, bottom = 25 },
		fade = 5,
		corner = 63,
		cover = true,
		Middle = { "Interface\\AddOns\\WarriorKit\\Media\\Arcane-Middle.tga", 1408, 768 },
		Top = { "Interface\\AddOns\\WarriorKit\\Media\\Arcane-Top.tga", 90, 35 },
		Bottom = { "Interface\\AddOns\\WarriorKit\\Media\\Arcane-Bottom.tga", 90, 29 },
		Left = { "Interface\\AddOns\\WarriorKit\\Media\\Arcane-Left.tga", 28, 66 },
		Right = { "Interface\\AddOns\\WarriorKit\\Media\\Arcane-Right.tga", 28, 66 },
		TopLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Arcane-TopLeft.tga", 63, 63 },
		TopRight = { "Interface\\AddOns\\WarriorKit\\Media\\Arcane-TopRight.tga", 63, 63 },
		BottomLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Arcane-BottomLeft.tga", 63, 63 },
		BottomRight = { "Interface\\AddOns\\WarriorKit\\Media\\Arcane-BottomRight.tga", 63, 63 },
	},
	horde = {
		thickness = { left = 23, top = 30, right = 23, bottom = 25 },
		fade = 5,
		corner = 63,
		cover = true,
		Middle = { "Interface\\AddOns\\WarriorKit\\Media\\Horde-Middle.tga", 1408, 768 },
		Top = { "Interface\\AddOns\\WarriorKit\\Media\\Horde-Top.tga", 90, 35 },
		Bottom = { "Interface\\AddOns\\WarriorKit\\Media\\Horde-Bottom.tga", 90, 29 },
		Left = { "Interface\\AddOns\\WarriorKit\\Media\\Horde-Left.tga", 28, 45 },
		Right = { "Interface\\AddOns\\WarriorKit\\Media\\Horde-Right.tga", 28, 45 },
		TopLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Horde-TopLeft.tga", 63, 63 },
		TopRight = { "Interface\\AddOns\\WarriorKit\\Media\\Horde-TopRight.tga", 63, 63 },
		BottomLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Horde-BottomLeft.tga", 63, 63 },
		BottomRight = { "Interface\\AddOns\\WarriorKit\\Media\\Horde-BottomRight.tga", 63, 63 },
	},
	alliance = {
		thickness = { left = 23, top = 30, right = 23, bottom = 25 },
		fade = 5,
		corner = 63,
		cover = true,
		Middle = { "Interface\\AddOns\\WarriorKit\\Media\\Alliance-Middle.tga", 1408, 768 },
		Top = { "Interface\\AddOns\\WarriorKit\\Media\\Alliance-Top.tga", 90, 35 },
		Bottom = { "Interface\\AddOns\\WarriorKit\\Media\\Alliance-Bottom.tga", 90, 29 },
		Left = { "Interface\\AddOns\\WarriorKit\\Media\\Alliance-Left.tga", 28, 45 },
		Right = { "Interface\\AddOns\\WarriorKit\\Media\\Alliance-Right.tga", 28, 45 },
		TopLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Alliance-TopLeft.tga", 63, 63 },
		TopRight = { "Interface\\AddOns\\WarriorKit\\Media\\Alliance-TopRight.tga", 63, 63 },
		BottomLeft = { "Interface\\AddOns\\WarriorKit\\Media\\Alliance-BottomLeft.tga", 63, 63 },
		BottomRight = { "Interface\\AddOns\\WarriorKit\\Media\\Alliance-BottomRight.tga", 63, 63 },
	},
}
