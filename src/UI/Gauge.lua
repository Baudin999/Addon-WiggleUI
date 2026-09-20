local ADDON, ns = ...

local UI = ns.UI
local Gauge = {}
UI.Gauge = Gauge

--------------------------------------------------------------------------
-- The gauge
--
-- A status bar with a flat fill and the spent part of it drawn behind, which
-- is what every health and power gauge in this addon is. The modern bar look
-- lays a sheen over the fill; see Sheen below.
--
-- It was written twice and neither copy was wrong. UnitFrames/EnemyBars.lua
-- builds a bar of its own with a white texture the bar tints; Skin.lua takes
-- the bar Blizzard already made and turns its fill into the same white
-- texture. Those two really are different jobs. What made them one file is the
-- line underneath, which was the same in both: the fill set to the unit's
-- colour and the track set to a fifth of that colour at nine tenths alpha,
-- with the same constant and the same 0.9 typed out in each. A pair of writes
-- like that drifts the first time somebody decides the spent end is too dark,
-- and the two gauges stop agreeing about what a mob at ten percent looks like.
--
-- Four calls, split by when they run rather than by what reads tidily.
-- Gauge.New and Gauge.Underlay allocate and are called once per widget.
-- Gauge.Flatten and Gauge.Paint run on a ticker against every mob on the
-- screen and every unit frame on it, so neither allocates and neither writes
-- what is already there. check.sh's HOT list holds the second pair to that.
--
-- Not in here: the meter's rows. Meter/Window.lua draws each row's bar as one
-- texture whose width is that player's share of the top row's number, with
-- nothing behind it and no spent part to colour. Putting a status bar under
-- every row would add a frame per row, an ordering question between that frame
-- and the row's own icon and text, and float arithmetic where the meter rounds
-- a share to whole pixels on purpose.
--
-- It takes one call off this page, which is Gauge.Sheen, and that is the
-- difference between a meter bar and a health bar being the same surface lit
-- the same way and being two flat slabs that happen to share a palette. What it
-- does not take is Gauge.Paint: a row has no spent end, so its colour is
-- written straight onto the texture at the alpha the meter's own setting holds.
--------------------------------------------------------------------------

-- What the spent part keeps of the fill's colour. Off the unit palette rather
-- than restated here: the enemy bars and the skinned frames already agreed on
-- one fifth, and a second copy of the number in the drawing layer is what the
-- extraction into ns.Unit.Color was for.
local TRACK = ns.Unit.Color.track

-- And what it keeps of the surface behind it. Not opaque, so the empty end of
-- a gauge reads as the frame's own dark showing through rather than as a
-- second fill in a duller colour. Nine tenths is the figure both callers
-- shipped and it is kept rather than rounded, because rounding it to one is a
-- look change wearing a tidy-up's clothes.
local TRACK_ALPHA = 0.9

-- A status bar's own fill texture, turned into a flat colour.
--
-- Swapping in a new texture instead left the original parented to the bar and
-- still drawing, which is what kept the soft rounded ends of UI-StatusBar
-- under a flat colour that was doing nothing.
--
-- Re-fetched rather than cached, because a client that swaps the texture
-- object out from under the bar would leave a cached one pointing at nothing,
-- and re-applied from the tick, because Blizzard's own code sets these back
-- and ours has to be the last word.
--
-- Being the last word is not the same as writing every tick, which is what
-- this did. A colour texture answers no file path, so a bar that is still flat
-- costs one comparison, and the moment Blizzard puts UI-StatusBar back the
-- path answers and this writes again. Six bars at five ticks a second is
-- thirty texture writes saved, all of them writing the colour already there.
-- Where the client has no GetTexture the write stands unguarded, which is what
-- this did before and is the safe half to be wrong on.
function Gauge.Flatten(bar)
	local fill = bar and bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if not fill or not fill.SetColorTexture then
		return nil
	end
	local flat = fill.GetTexture and bar.wuiFlat == fill and not fill:GetTexture()
	if not flat then
		bar.wuiFlat = fill
		fill:SetColorTexture(1, 1, 1, 1)
	end
	return fill
end

-- A texture of ours, drawn inside a status bar and under its fill.
--
-- Under it by draw layer, not by frame level, and that is the whole reason
-- these textures live on the bar rather than on a rail of ours behind it. Two
-- frames agree on an order only while their levels do, and the code that
-- writes both of those levels can still be wrong about them: on the live
-- client the target frame came out with its rail level with its bar, the tie
-- went to whichever was built later, which was ours, and the spent track drew
-- over the fill at nine tenths alpha. A target at full health read at 28
-- percent of its own colour, which is what a dead one looks like. The player
-- frame, one line of the same code away, was correct.
--
-- Inside one frame there is nothing to disagree about. Layer beats level and
-- BACKGROUND is the bottom one, so a sublevel there is below every layer a
-- status bar's fill can be built on, on any client, and no number a caller
-- writes can move it. A caller drawing two underlays in one bar orders them by
-- passing the two lowest sublevels the client allows; a caller drawing one
-- passes nothing and takes the default.
--
-- The colour is optional and a gauge that is painted on its first tick leaves
-- it out, because a colour set here is a colour drawn for the frame before
-- that tick lands.
function Gauge.Underlay(bar, sublevel, color)
	local texture
	if color then
		texture = ns.Fill(bar, "BACKGROUND", color[1], color[2], color[3], color[4])
	else
		texture = bar:CreateTexture(nil, "BACKGROUND")
	end
	texture:SetAllPoints()
	if sublevel and texture.SetDrawLayer then
		texture:SetDrawLayer("BACKGROUND", sublevel)
	end
	return texture
end

-- The modern look's sheen: white thinning to nothing down the top half of the
-- fill and black thickening out of nothing down the bottom half, so the colour
-- reads lit from above. Two washes rather than one gradient from white to
-- black, because one gradient passes through a grey at the middle and a grey
-- laid over a class colour is a dirtier class colour.
--
-- Over the fill and pinned to it, so it is exactly as long as the fill whichever
-- way the bar runs, and drawn once here: the tick paints the fill through the
-- status bar's own colour and never touches these. One sublevel up in the
-- fill's layer, which keeps it under every label, all of which are OVERLAY.
-- Half what shipped first. At 0.16 and 0.24 the bottom of every bar went
-- muddy, an olive fill read brown, and the sheen was seen before the colour.
local SHINE = { 1, 1, 1, 0.08 }
local SHADE = { 0, 0, 0, 0.12 }
local SHEEN_LAYER = 1

-- Public, and the meter's rows are why. A row's bar is a texture on the row
-- rather than a status bar's fill, so it cannot come through Gauge.New, and
-- every other way of giving it the modern look is a second copy of 0.08 and
-- 0.12 in Meter/Window.lua. Two copies of a wash is how a meter bar and a
-- health bar stop agreeing about what lit from above means, which is a thing
-- nobody would notice for a year and then could not unsee.
--
-- The layer is the caller's because the two callers stack differently. A status
-- bar's fill is on ARTWORK and this goes one sublevel over it, under every
-- label. A meter row draws its bar on BACKGROUND and its spec icon on ARTWORK,
-- so there the sheen goes on BORDER, over the colour and under the art, which
-- must not be washed: a sheen over an icon is the icon in a different shade at
-- the top than at the bottom.
--
-- The parent is the caller's too, and it is the frame rather than the fill,
-- because a texture cannot carry a texture. The anchors are what pin the two
-- washes to the fill, so they are exactly as long as it is whichever way the
-- bar runs and however often the tick rewrites its width.
function Gauge.Sheen(parent, fill, layer, sublevel)
	layer = layer or "ARTWORK"
	sublevel = sublevel or SHEEN_LAYER
	local lit = UI.Wash(parent, SHINE, "TOP", layer)
	lit:SetDrawLayer(layer, sublevel)
	lit:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
	lit:SetPoint("BOTTOMRIGHT", fill, "RIGHT", 0, 0)
	local dark = UI.Wash(parent, SHADE, "BOTTOM", layer)
	dark:SetDrawLayer(layer, sublevel)
	dark:SetPoint("TOPLEFT", fill, "LEFT", 0, 0)
	dark:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
	return lit, dark
end

-- A gauge of our own: the fill, spent track behind it, and a scale of zero to
-- one until the caller knows what the unit's maximum is. The fill is flat, and
-- under the modern bar look it wears the sheen above.
--
-- The track hangs off the bar as `track` because this one owns both. A caller
-- painting a bar it did not build hands its own track to Gauge.Paint instead.
function Gauge.New(parent)
	local bar = CreateFrame("StatusBar", nil, parent)
	local fill = bar:CreateTexture(nil, "ARTWORK")
	bar:SetStatusBarTexture(fill)
	Gauge.Flatten(bar)
	bar:SetMinMaxValues(0, 1)
	bar.track = Gauge.Underlay(bar)
	if ns.Theme.Modern() then
		Gauge.Sheen(bar, fill)
	end
	return bar
end

-- The fill and the spent part behind it, in one colour. This is the pair of
-- writes the file exists for.
--
-- Through the setter the bar came with, or through the copy the skin put aside
-- when it froze the client's own: a frozen bar's SetStatusBarColor is a no-op
-- and the original lives under the same wk-prefixed key ns.Strip and
-- UnitFrames/Art.lua's Freeze use, so painting one has to go the long way
-- round.
--
-- No guard in here, and that is the one difference from ns.Recolor. Both
-- callers already compare the colour table's identity against the one they
-- drew last, and the same comparison decides three or four other writes beside
-- these two, so a cache here would be a second one to keep true across a
-- pooled widget. ns.Recolor guards internally because its callers cannot all
-- compare the same thing; these two can and do.
function Gauge.Paint(bar, track, color)
	local r, g, b = color[1], color[2], color[3]
	local set = bar and (bar.wuiSetStatusBarColor or bar.SetStatusBarColor)
	if set then
		set(bar, r, g, b, 1)
	end
	if track then
		track:SetColorTexture(r * TRACK, g * TRACK, b * TRACK, bar and bar.wuiTrackAlpha or TRACK_ALPHA)
	end
end

-- The palette's painted floor under a gauge's empty end.
--
-- Under the track, on the lowest sublevel UI/Backdrop.lua draws its floor on,
-- and the track stays over it at FLOOR_TINT rather than nine tenths: thin
-- enough that the pattern shows, thick enough that it is darkened and taken
-- toward the bar's own colour, so the name and the number written on the bar
-- read on it the way they read on the flat track.
--
-- At FLOOR_SCALE of the bag window's size, which puts about one row of slabs
-- across a bar of the height the rails and the cast bar ship at. Nil when the
-- palette has no painting, and the bar is drawn as it always was.
local FLOOR_SCALE = 0.35
local FLOOR_TINT = 0.35

function Gauge.Floor(bar)
	local floor = UI.Backdrop(bar, { frame = false })
	if floor then
		bar.floor = floor
		bar.wuiTrackAlpha = FLOOR_TINT
	end
	return floor
end

-- The floor shown or taken away, for an owner with a style that draws none.
-- The track's alpha goes with it, because over no floor the thin track would
-- let the world show through the empty end. Answers true when anything
-- changed, which is the owner's cue to paint the track again: the alpha is
-- written with the colour, in Gauge.Paint.
function Gauge.ShowFloor(bar, on)
	if not bar.floor or (bar.floor.alpha > 0) == on then
		return false
	end
	bar.floor:SetAlpha(on and 1 or 0)
	bar.wuiTrackAlpha = on and FLOOR_TINT or nil
	return true
end

-- Laid across the bar at the size just given it, in design pixels, with the
-- unit the owner's zoom puts them in.
function Gauge.LayFloor(bar, unit, width, height)
	if bar.floor then
		bar.floor:SetScale(FLOOR_SCALE * unit)
		bar.floor:Layout(width * unit, height * unit)
	end
end

