local ADDON, ns = ...

--------------------------------------------------------------------------
-- Dark, the palette the addon was drawn in before there was a choice
--
-- A palette is the surfaces, the lines, the accent and the text, and nothing
-- that means something. Item grades, class colours, the red on a stranger's
-- name and the orange on a quest item stay in UI/Theme.lua whatever is chosen
-- here, because a forest palette that turned a loss green would be lying.
--
-- Every palette names exactly the keys this one names, and Theme/Theme.lua
-- refuses to load one that does not. UI/Theme.lua builds UI.Color's entries
-- out of this file at load, which is the only answer it can give before the
-- saved variables arrive, and Theme/Theme.lua copies the chosen palette over
-- those same tables at ADDON_LOADED. Copies into, never replaces: a part that
-- took UI.Color.window into a local at file scope is holding the table, and
-- the table is what changes.
--------------------------------------------------------------------------

local Palettes = ns.Palettes or {}
ns.Palettes = Palettes

-- Four components, the fourth optional and taken as opaque.
Palettes.dark = {
	window   = { 0.05, 0.05, 0.06, 0.97 },
	chrome   = { 0.10, 0.10, 0.12, 1 },
	rail     = { 0.07, 0.07, 0.09, 1 },
	edge     = { 0.22, 0.22, 0.27, 1 },
	hairline = { 0.16, 0.16, 0.19, 1 },
	sunken   = { 0.03, 0.03, 0.04, 1 },
	control  = { 0.14, 0.14, 0.17, 1 },
	hover    = { 0.21, 0.21, 0.26, 1 },
	selected = { 0.17, 0.17, 0.21, 1 },
	accent   = { 0.25, 0.62, 0.95, 1 },
	shadow   = { 0, 0, 0, 0.55 },

	-- The two tones a dense list of numbers alternates between, row by row.
	--
	-- They are the accent and they are not a second name for it. The accent is a
	-- control you can press; these are the ground under a number, and the only
	-- thing either has to do is tell one row from the row under it without being
	-- read as anything. Two entries rather than one and an alpha at the call
	-- site, because the pair is the thing: change one and the stripe stops
	-- alternating, which is a decision about the palette and not about a row.
	--
	-- Low enough to be a tint over the world. The character sheet is a backdrop
	-- with no ground of its own, so these bands are the only surface its numbers
	-- have, and a band opaque enough to paint out the grass would be a panel
	-- through the middle of the page.
	band     = { 0.25, 0.62, 0.95, 0.20 },
	bandAlt  = { 0.25, 0.62, 0.95, 0.09 },

	text     = { 0.87, 0.87, 0.91 },
	dim      = { 0.56, 0.56, 0.62 },
	heading  = { 1.00, 0.82, 0.20 },
	quiet    = { 0.42, 0.42, 0.47 },

	-- The line in a tooltip that tells you what to type. It was a literal in
	-- Buffs/Nag.lua, 0.55 0.72 1, one of exactly two colours that file wrote by
	-- hand, and it came here when the tooltip it was written for became
	-- UI/Tooltip.lua. Blue rather than the accent because the accent is a
	-- control that can be clicked and this is a sentence that cannot.
	hint     = { 0.55, 0.72, 1.00 },

	-- The colours a unit and a HUD bar are drawn on, which Unit/Color.lua owns
	-- and takes from here. Its own table because none of them is a window or a
	-- control: the backdrop is behind every health bar, the seam splits an
	-- enemy bar's two chambers, iron is the frame round a bar, and the rest are
	-- the fills of the bars that are about you. What a colour means, threat and
	-- reaction and class, stays in Unit/Color.lua for the reason the item grades
	-- stay in UI/Theme.lua.
	--
	-- The fills are shaped after they are painted, so a palette may write any
	-- brightness here and the name on the bar still clears its contrast floor.
	unit = {
		backdrop   = { 0.04, 0.04, 0.05, 0.85 },
		seam       = { 0.02, 0.02, 0.03, 1 },
		iron       = { 0.24, 0.25, 0.29 },
		cast       = { 0.62, 0.45, 0.95 },
		experience = { 0.55, 0.32, 0.86 },
		rested     = { 0.30, 0.52, 0.92 },
		swingMain  = { 0.86, 0.72, 0.30 },
		swingOff   = { 0.42, 0.60, 0.86 },
	},
}
