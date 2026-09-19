local ADDON, ns = ...

-- Alliance. Surfaces the navy of Stormwind's stone, an accent the sapphire set
-- in the frame's foot, and text a cool white so it does not go yellow against
-- blue. The heading is the gold of the lions on the corners, the one warm
-- thing in the painting and so the one thing on the page that reads as a title.

local Palettes = ns.Palettes

Palettes.alliance = {
	window   = { 0.03, 0.05, 0.11, 0.97 },
	chrome   = { 0.06, 0.10, 0.20, 1 },
	rail     = { 0.05, 0.08, 0.15, 1 },
	edge     = { 0.20, 0.30, 0.52, 1 },
	hairline = { 0.13, 0.19, 0.35, 1 },
	sunken   = { 0.02, 0.03, 0.07, 1 },
	control  = { 0.09, 0.14, 0.28, 1 },
	hover    = { 0.15, 0.22, 0.42, 1 },
	selected = { 0.12, 0.18, 0.35, 1 },
	accent   = { 0.32, 0.58, 1.00, 1 },
	shadow   = { 0, 0, 0, 0.55 },
	band     = { 0.32, 0.58, 1.00, 0.20 },
	bandAlt  = { 0.32, 0.58, 1.00, 0.09 },
	text     = { 0.88, 0.91, 0.97 },
	dim      = { 0.60, 0.67, 0.82 },
	heading  = { 0.95, 0.77, 0.40 },
	quiet    = { 0.46, 0.53, 0.70 },
	hint     = { 0.70, 0.86, 1.00 },

	unit = {
		backdrop   = { 0.02, 0.03, 0.07, 0.85 },
		seam       = { 0.01, 0.015, 0.04, 1 },
		iron       = { 0.26, 0.32, 0.46 },
		bar        = { 0.36, 0.60, 0.95 },
		swingMain  = { 0.92, 0.74, 0.36 },
		swingOff   = { 0.50, 0.70, 0.95 },
	},
}
