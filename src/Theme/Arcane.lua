local ADDON, ns = ...

-- Arcane. Surfaces the indigo of the painting's star-slabs, a violet accent,
-- and text a cool white so it does not go yellow against blue. The heading is
-- the gold of the frame's trim, which is the one warm thing in the painting
-- and so the one thing on the page that reads as a title.

local Palettes = ns.Palettes

Palettes.arcane = {
	window   = { 0.05, 0.05, 0.10, 0.97 },
	chrome   = { 0.09, 0.09, 0.18, 1 },
	rail     = { 0.07, 0.07, 0.14, 1 },
	edge     = { 0.25, 0.24, 0.42, 1 },
	hairline = { 0.17, 0.16, 0.30, 1 },
	sunken   = { 0.03, 0.03, 0.07, 1 },
	control  = { 0.13, 0.13, 0.25, 1 },
	hover    = { 0.21, 0.20, 0.38, 1 },
	selected = { 0.17, 0.16, 0.32, 1 },
	accent   = { 0.66, 0.50, 1.00, 1 },
	shadow   = { 0, 0, 0, 0.55 },
	band     = { 0.66, 0.50, 1.00, 0.20 },
	bandAlt  = { 0.66, 0.50, 1.00, 0.09 },
	text     = { 0.88, 0.88, 0.97 },
	dim      = { 0.64, 0.64, 0.82 },
	heading  = { 0.92, 0.82, 0.52 },
	quiet    = { 0.52, 0.52, 0.72 },
	hint     = { 0.62, 0.88, 1.00 },

	unit = {
		backdrop   = { 0.03, 0.03, 0.07, 0.85 },
		seam       = { 0.015, 0.015, 0.04, 1 },
		iron       = { 0.26, 0.26, 0.38 },
		bar        = { 0.40, 0.72, 0.95 },
		swingMain  = { 0.80, 0.66, 1.00 },
		swingOff   = { 0.45, 0.80, 0.90 },
	},
}
