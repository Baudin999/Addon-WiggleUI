local ADDON, ns = ...

local Ring = {}
ns.AdHocRing = Ring

local UI = ns.UI
local C = ns.UI.Color

--------------------------------------------------------------------------
-- What a ring looks like
--
-- A ring you hold a key for is a pie and this file draws it: the palette's
-- paper for a ground, a seam between every two slices, a hairline round the
-- outside, and a hole in the middle where nothing happens. The squares sit on
-- top of it, and Bars.lua puts them there.
--
-- **The picture says what the gesture does.** A push picks the slice it points
-- into, and every slice is a wedge of the whole screen rather than the square
-- drawn in it, so a ring that draws only its squares is a ring that hides the
-- thing you are actually aiming at. The seams say where one slice stops. The
-- hole is the dead zone: a release inside it fires nothing, and it is drawn at
-- the radius the release is measured against rather than at some fraction that
-- looks about right.
--
-- **The chrome is the palette's, not a colour of its own.** The ground is the
-- painting behind every window in the theme, cut round, and it falls back to
-- the flat window fill for a palette with no painting. The seams are the
-- sunken tone, the hairlines are the edge, the lit slice is the accent. A new
-- palette moves the ring with everything else and nobody comes back here.
--
-- **One drawing, two pictures.** Bars.lua dresses the ring on the screen and
-- Panel.lua dresses the circle on the settings page, both through here, at
-- their own radius and their own square. The page and the thumb cannot drift
-- apart, for the reason AdHocBars.Where is one function: a second copy of a
-- picture is a second rule.
--------------------------------------------------------------------------

-- The seam between two slices, in radians. A degree and a half is two pixels
-- at the rim of the widest ring and one at the hole of the tightest, which is
-- a line rather than a gap: a seam you can see through would read as a slice
-- of its own.
local SEAM = math.rad(1.5)

-- The hairline round the outside and round the hole, as a share of a square,
-- and never less than a pixel. A share rather than a number because the page
-- draws this at half the ring's size and a fixed hairline there is twice the
-- line it is under your thumb.
local RIM = 0.06

-- How solid each layer is. The ground is nearly opaque because a ring is up
-- for the second your thumb is on the key and a paper you can read the world
-- through is not paper. The hole is darker and thinner than the ground: it is
-- the one part of the ring that does nothing, and the name of what you are
-- pointing at is written across it.
local GROUND, HOLE, LIT = 0.92, 0.72, 0.4

--------------------------------------------------------------------------
-- Building one
--------------------------------------------------------------------------

-- The ground: the palette's floor tile, cut round.
--
-- Nil for a palette with no painting, and nil again on a client that would not
-- cut the mask, because an uncut painting is a square of parchment behind a
-- circle of squares. Either way the flat window fill stands in, which is what
-- this ring was drawn on before there was a painting to draw it on.
local function Paper(frame)
	local floor = UI.Floor()
	if not floor then
		return nil
	end
	local texture = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
	texture:SetTexture(floor[1])
	-- The middle square of a wide painting, so the tile is not stretched round
	-- into an oval. UI.Backdrop's Cover does the same sum for a window.
	local across = math.min(floor[3] / floor[2], 1)
	texture:SetTexCoord((1 - across) / 2, (1 + across) / 2, 0, 1)
	texture:SetAlpha(GROUND)
	UI.Clip(texture)
	return texture.mask and texture or nil
end

local function Disc(frame, sublevel, color, alpha)
	local texture = UI.Disc(frame, "BACKGROUND", sublevel)
	texture:SetVertexColor(color[1], color[2], color[3], alpha or color[4] or 1)
	return texture
end

-- Every part of the picture that does not depend on how many squares are on
-- the bar. The slices do, and they are made as the count reaches them.
--
-- Made once per ring and never destroyed, because the frame under it cannot
-- be: a bar you delete hands its frame and this chrome to the next bar added.
function Ring.Dress(frame)
	local chrome = { frame = frame, seams = {}, count = 0 }

	chrome.rim = Disc(frame, -8, C.edge)
	chrome.rim:SetAllPoints(frame)

	chrome.ground = Disc(frame, -7, C.window, GROUND)
	chrome.ground:SetPoint("CENTER")
	chrome.paper = Paper(frame)
	if chrome.paper then
		chrome.paper:SetPoint("CENTER")
		-- One ground, not two. The fill under the paper would show through it
		-- as a wash of the window colour, and the whole point of the painting
		-- is that the surface is the colour the painting already is.
		chrome.ground:Hide()
	end

	-- The slice under the cursor, and the whole disc for the ring of one
	-- square, whose slice is the circle and is wider than a pair of masks can
	-- cut. Both in the accent, only ever one of them up.
	chrome.lit = UI.Wedge(frame, "BACKGROUND", -5, C.accent)
	chrome.lit.texture:SetAlpha(LIT)
	chrome.whole = Disc(frame, -5, C.accent, LIT)
	chrome.whole:SetPoint("CENTER")
	chrome.whole:Hide()

	chrome.holeRim = Disc(frame, -3, C.edge)
	chrome.holeRim:SetPoint("CENTER")
	chrome.hole = Disc(frame, -2, C.sunken, HOLE)
	chrome.hole:SetPoint("CENTER")

	return chrome
end

-- The seam on the clockwise edge of slice `at`, made the first time a bar is
-- that wide.
local function Seam(chrome, at)
	local seam = chrome.seams[at]
	if not seam then
		seam = UI.Wedge(chrome.frame, "BACKGROUND", -4, C.sunken)
		chrome.seams[at] = seam
	end
	return seam
end

--------------------------------------------------------------------------
-- Laying it out
--------------------------------------------------------------------------

-- The whole picture for a ring of `count` squares of `size`, drawn on a circle
-- of `radius`, in whatever units the caller's frame is on. The frame is
-- 2 * (radius + size) square, which is what AdHocBars.Arrange sets and the
-- page copies, so the rim lands on the frame's own edge and everything else is
-- measured off the middle.
--
-- The hole is the inner edge of the squares, which is the reach: a push that
-- has not left the hole has not reached the ring and fires nothing. One
-- number, drawn here and compared in the snippet.
function Ring.Lay(chrome, count, radius, size)
	count = math.max(count, 1)
	local rim = math.max(1, size * RIM)
	local outer = radius + size
	local inner = math.max(rim, radius - size / 2)

	chrome.count, chrome.wedge = count, 2 * math.pi / count
	chrome.ground:SetSize((outer - rim) * 2, (outer - rim) * 2)
	if chrome.paper then
		chrome.paper:SetSize((outer - rim) * 2, (outer - rim) * 2)
	end
	chrome.whole:SetSize(outer * 2, outer * 2)
	chrome.holeRim:SetSize((inner + rim) * 2, (inner + rim) * 2)
	chrome.hole:SetSize(inner * 2, inner * 2)

	-- A seam on the edge between every two slices, which for a ring of one is
	-- the single line at the back.
	for at = 1, count do
		UI.Turn(Seam(chrome, at), (at - 0.5) * chrome.wedge, SEAM)
	end
	for at = count + 1, #chrome.seams do
		UI.Turn(chrome.seams[at], nil)
	end

	chrome.at = nil
	UI.Turn(chrome.lit, nil)
	chrome.whole:Hide()
end

-- Light the slice the cursor points into, or none. Answers whether it wrote.
--
-- Called off a tick, so it is guarded on the slice rather than on nothing: a
-- cursor held still inside one slice is most of the frames a ring is up for.
function Ring.Aim(chrome, at)
	if chrome.at == at then
		return false
	end
	chrome.at = at
	if at and chrome.count == 1 then
		chrome.whole:Show()
	elseif at then
		chrome.whole:Hide()
		UI.Turn(chrome.lit, (at - 1) * chrome.wedge, chrome.wedge - SEAM)
	else
		chrome.whole:Hide()
		UI.Turn(chrome.lit, nil)
	end
	return true
end

-- How wide the hole is, for the page to say in words and the harness to hold
-- the drawing to the reach.
function Ring.Hole(chrome)
	return chrome.hole:GetWidth() / 2
end
