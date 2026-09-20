local ADDON, ns = ...

-- Parchment. The one palette whose surfaces are not a colour somebody picked
-- but a colour the painting already is: scripts/paint-parchment.sh lights the
-- sheet at a mean of roughly 0.35, 0.30, 0.24, and window, chrome, rail and
-- control are that tone stepped darker, so the title bar and the tooltip read
-- as bands pressed into the paper rather than panels laid on it.
--
-- The writing is pale, which is the opposite of what a page suggests. The sheet
-- is lit where the fixed colours let it be lit and no further -- UI.Quality's
-- white item name is what sets the ceiling -- and a ground that white reads on
-- is a ground brown ink would vanish into. So the hand is a warm bone rather
-- than a warm black, and the gold accent is leaf on the page.

local Palettes = ns.Palettes

Palettes.parchment = {
	window   = { 0.30, 0.26, 0.20, 0.97 },
	chrome   = { 0.19, 0.16, 0.12, 1 },
	rail     = { 0.24, 0.20, 0.15, 1 },
	edge     = { 0.48, 0.38, 0.25, 1 },
	hairline = { 0.34, 0.27, 0.19, 1 },
	sunken   = { 0.13, 0.11, 0.08, 1 },
	control  = { 0.27, 0.22, 0.16, 1 },
	hover    = { 0.41, 0.34, 0.24, 1 },
	selected = { 0.34, 0.28, 0.20, 1 },
	accent   = { 0.86, 0.66, 0.30, 1 },
	shadow   = { 0.06, 0.04, 0.03, 0.55 },
	band     = { 0.86, 0.66, 0.30, 0.20 },
	bandAlt  = { 0.86, 0.66, 0.30, 0.09 },
	text     = { 0.95, 0.92, 0.85 },
	dim      = { 0.73, 0.68, 0.58 },
	heading  = { 1.00, 0.88, 0.60 },
	quiet    = { 0.55, 0.50, 0.42 },
	hint     = { 0.74, 0.85, 0.99 },

	unit = {
		backdrop   = { 0.16, 0.13, 0.10, 0.85 },
		seam       = { 0.08, 0.06, 0.05, 1 },
		iron       = { 0.39, 0.32, 0.23 },
		bar        = { 0.52, 0.34, 0.72 },
		swingMain  = { 0.90, 0.72, 0.34 },
		swingOff   = { 0.48, 0.62, 0.78 },
	},
}
