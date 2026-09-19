local ADDON, ns = ...

-- Forest. The dark palette's surfaces pulled toward moss, a leaf green where
-- the blue accent was, and text a shade warmer so it does not read as grey on
-- green. The headings keep their gold, dulled, because a gold title on a green
-- ground is what the zone text in Elwynn already is.

local Palettes = ns.Palettes

Palettes.forest = {
	window   = { 0.04, 0.07, 0.05, 0.97 },
	chrome   = { 0.08, 0.12, 0.09, 1 },
	rail     = { 0.06, 0.09, 0.07, 1 },
	edge     = { 0.20, 0.29, 0.21, 1 },
	hairline = { 0.14, 0.20, 0.15, 1 },
	sunken   = { 0.02, 0.04, 0.03, 1 },
	control  = { 0.12, 0.17, 0.13, 1 },
	hover    = { 0.18, 0.26, 0.19, 1 },
	selected = { 0.15, 0.22, 0.16, 1 },
	accent   = { 0.42, 0.76, 0.38, 1 },
	shadow   = { 0, 0, 0, 0.55 },
	band     = { 0.42, 0.76, 0.38, 0.20 },
	bandAlt  = { 0.42, 0.76, 0.38, 0.09 },
	text     = { 0.86, 0.90, 0.83 },
	dim      = { 0.55, 0.62, 0.53 },
	heading  = { 0.92, 0.82, 0.42 },
	quiet    = { 0.40, 0.46, 0.39 },
	hint     = { 0.62, 0.86, 0.58 },

	unit = {
		backdrop   = { 0.03, 0.05, 0.035, 0.85 },
		seam       = { 0.015, 0.03, 0.02, 1 },
		iron       = { 0.22, 0.29, 0.23 },
		swingMain  = { 0.78, 0.70, 0.34 },
		swingOff   = { 0.40, 0.64, 0.52 },
	},
}
