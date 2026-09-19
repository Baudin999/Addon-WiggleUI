local ADDON, ns = ...

-- Desert. Surfaces the brown of Tanaris sand after dark, an amber accent, and
-- text the colour of bleached cloth. The heading goes to a paler gold than
-- dark's so it still stands off an accent that is now nearly its own hue.

local Palettes = ns.Palettes

Palettes.desert = {
	window   = { 0.08, 0.06, 0.04, 0.97 },
	chrome   = { 0.14, 0.10, 0.07, 1 },
	rail     = { 0.10, 0.08, 0.05, 1 },
	edge     = { 0.35, 0.26, 0.17, 1 },
	hairline = { 0.24, 0.18, 0.12, 1 },
	sunken   = { 0.05, 0.04, 0.03, 1 },
	control  = { 0.19, 0.14, 0.09, 1 },
	hover    = { 0.29, 0.21, 0.14, 1 },
	selected = { 0.24, 0.17, 0.11, 1 },
	accent   = { 0.92, 0.60, 0.26, 1 },
	shadow   = { 0, 0, 0, 0.55 },
	band     = { 0.92, 0.60, 0.26, 0.20 },
	bandAlt  = { 0.92, 0.60, 0.26, 0.09 },
	text     = { 0.94, 0.89, 0.80 },
	dim      = { 0.66, 0.58, 0.47 },
	heading  = { 1.00, 0.86, 0.52 },
	quiet    = { 0.50, 0.43, 0.34 },
	hint     = { 0.98, 0.78, 0.52 },

	unit = {
		backdrop   = { 0.06, 0.045, 0.03, 0.85 },
		seam       = { 0.03, 0.02, 0.015, 1 },
		iron       = { 0.31, 0.26, 0.20 },
		bar        = { 0.72, 0.40, 0.52 },
		swingMain  = { 0.92, 0.70, 0.32 },
		swingOff   = { 0.52, 0.62, 0.72 },
	},
}
