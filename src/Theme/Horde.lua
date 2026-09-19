local ADDON, ns = ...

-- Horde. Surfaces the clay of Orgrimmar's walls after dark, redder than the
-- desert's sand so the two are not one palette twice, an accent the orange-red
-- of the eye set in the frame's foot, and text a warm bone. The heading is the
-- eye's gold, which clears an accent that is nearly its own hue by lightness.

local Palettes = ns.Palettes

Palettes.horde = {
	window   = { 0.09, 0.04, 0.03, 0.97 },
	chrome   = { 0.16, 0.07, 0.05, 1 },
	rail     = { 0.12, 0.05, 0.04, 1 },
	edge     = { 0.42, 0.20, 0.13, 1 },
	hairline = { 0.28, 0.13, 0.09, 1 },
	sunken   = { 0.05, 0.02, 0.015, 1 },
	control  = { 0.22, 0.10, 0.07, 1 },
	hover    = { 0.33, 0.15, 0.10, 1 },
	selected = { 0.27, 0.12, 0.08, 1 },
	accent   = { 0.95, 0.38, 0.16, 1 },
	shadow   = { 0, 0, 0, 0.55 },
	band     = { 0.95, 0.38, 0.16, 0.20 },
	bandAlt  = { 0.95, 0.38, 0.16, 0.09 },
	text     = { 0.95, 0.89, 0.80 },
	dim      = { 0.70, 0.56, 0.47 },
	heading  = { 1.00, 0.80, 0.36 },
	quiet    = { 0.54, 0.40, 0.33 },
	hint     = { 1.00, 0.70, 0.50 },

	unit = {
		backdrop   = { 0.07, 0.03, 0.02, 0.85 },
		seam       = { 0.035, 0.015, 0.01, 1 },
		iron       = { 0.36, 0.22, 0.16 },
		bar        = { 0.78, 0.30, 0.20 },
		swingMain  = { 0.95, 0.66, 0.26 },
		swingOff   = { 0.72, 0.48, 0.36 },
	},
}
