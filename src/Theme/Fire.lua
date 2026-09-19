local ADDON, ns = ...

-- Fire. Surfaces the charcoal of the frame's stone, darker and greyer than
-- horde's clay so the two read apart, an accent the ember orange of the
-- crystals in its corners, and text a warm ash white. The heading is the gold
-- at the heart of the flame, which clears an orange accent by lightness.

local Palettes = ns.Palettes

Palettes.fire = {
	window   = { 0.07, 0.05, 0.045, 0.97 },
	chrome   = { 0.12, 0.08, 0.07, 1 },
	rail     = { 0.09, 0.06, 0.05, 1 },
	edge     = { 0.40, 0.17, 0.09, 1 },
	hairline = { 0.26, 0.12, 0.08, 1 },
	sunken   = { 0.04, 0.025, 0.02, 1 },
	control  = { 0.17, 0.09, 0.07, 1 },
	hover    = { 0.28, 0.13, 0.08, 1 },
	selected = { 0.23, 0.11, 0.07, 1 },
	accent   = { 1.00, 0.42, 0.10, 1 },
	shadow   = { 0, 0, 0, 0.55 },
	band     = { 1.00, 0.42, 0.10, 0.20 },
	bandAlt  = { 1.00, 0.42, 0.10, 0.09 },
	text     = { 0.96, 0.90, 0.84 },
	dim      = { 0.72, 0.58, 0.50 },
	heading  = { 1.00, 0.78, 0.40 },
	quiet    = { 0.52, 0.40, 0.34 },
	hint     = { 1.00, 0.66, 0.40 },

	unit = {
		backdrop   = { 0.05, 0.03, 0.025, 0.85 },
		seam       = { 0.03, 0.015, 0.01, 1 },
		iron       = { 0.34, 0.30, 0.28 },
		bar        = { 0.85, 0.28, 0.12 },
		swingMain  = { 1.00, 0.60, 0.20 },
		swingOff   = { 0.80, 0.40, 0.30 },
	},
}
