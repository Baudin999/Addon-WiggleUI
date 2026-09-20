local ADDON, ns = ...

local Graph = {}
ns.BreakdownGraph = Graph

local UI = ns.UI
local C, M = UI.Color, UI.Metric

--------------------------------------------------------------------------
-- What the level gap does to you, drawn
--
-- The counters were filed under four level bands from the first version of
-- this feature and the only way to read the split was a chip that showed one
-- band at a time. Comparing two of them meant clicking the chip, reading a
-- row, clicking it again, reading the same row, and holding three numbers in
-- your head. That is a graph drawn by hand, badly, and the answer it is drawn
-- for is a slope: in this era the target's level drives miss and dodge hard,
-- and what you want to see is how hard.
--
-- So: the band across the bottom, a chance up the side, one coloured line per
-- outcome. The eye reads the slope and the slope is the whole answer.
--
-- **Three columns and not four.** UNDER, NEAR and HIGH are an ordinal scale
-- and a line across them means something. UNKNOWN is the absence of one, and a
-- point plotted for it draws a slope out of a mob whose level was never seen,
-- which is not a harder mob, it is a mob nobody looked at. Its sample is
-- counted and said in words under the plot instead.
--
-- **A band with no attempts is a hole, not a zero.** A line that dives to the
-- floor at the right hand end because you have never swung at a boss is a line
-- that says your miss rate improves against bosses. Segments are drawn between
-- adjacent bands that both have attempts and nowhere else, so a gap in the
-- record looks like a gap.
--
-- **Six outcomes and no more.** Crit, and the five things that stop a swing
-- often enough to have a shape: missed, dodged, parried, blocked, resisted.
-- The store keeps ten miss types and the rows in the window name all ten;
-- absorb, immune, evade, deflect and reflect happen a handful of times a month
-- and a line through three points, two of which are one event, is noise drawn
-- at the same weight as your dodge rate.
--
-- **frame:CreateLine is real on both of these clients.** Questie draws its
-- waypoint arrows with it and Details' chart library draws its axes with it,
-- both on the 2.5.6 build this ships for. It is still probed, like every other
-- client call in this addon that a build could be missing: a client with no
-- lines draws the plot's furniture and says so, rather than raising.
--
-- Nothing here is on a ticker and nothing here allocates after the first draw.
-- The lines and the dots are pooled, because this redraws on every click in
-- the window's list and the client cannot destroy either.
--------------------------------------------------------------------------

-- The three bands with a slope through them, in the order they are drawn.
-- Taken from Breakdown.lua rather than written here, so the fourth band being
-- left off the axis is a decision this file made about the fourth band and not
-- an accident of typing three numbers.
local UNDER, NEAR, HIGH = 1, 2, 3
local COLUMNS = { UNDER, NEAR, HIGH }

--------------------------------------------------------------------------
-- The six outcomes
--
-- One colour per outcome and the same colour for that outcome whichever
-- ability is selected, so switching rows compares two shapes rather than
-- asking you to re-read a legend.
--
-- A named table with a header in the file that grades the thing, which is what
-- the palette's own rule asks for: these are not surfaces, not text and not
-- controls, so none of them is a palette entry. They are the six values of one
-- categorical scale and the only thing they owe the palette is contrast
-- against the floor they are drawn on.
--
-- That floor is C.sunken, which is the darkest surface every palette has:
-- 0.03 in dark and 0.13 in parchment, the palest of the ten. Each of the six
-- clears 3:1 against the worst of them, which is the ratio Unit/Color.lua
-- holds a token to and the right one here, because a two pixel stroke is
-- recognised rather than read. The harness computes all six rather than
-- trusting this paragraph.
--
-- `crit` is keyed by a word and the other five by the client's own miss type,
-- which is what the store files them under, so the lookup is the store's key
-- and not a second table mapping one to the other.
--------------------------------------------------------------------------

local SERIES = {
	{ key = "crit",  word = "crit",     color = { 0.98, 0.76, 0.24 } },
	{ key = "MISS",  word = "missed",   color = { 0.93, 0.40, 0.38 } },
	{ key = "DODGE", word = "dodged",   color = { 0.38, 0.78, 0.98 } },
	{ key = "PARRY", word = "parried",  color = { 0.62, 0.52, 0.94 } },
	{ key = "BLOCK", word = "blocked",  color = { 0.42, 0.84, 0.52 } },
	{ key = "RESIST", word = "resisted", color = { 0.95, 0.56, 0.26 } },
}

Graph.SERIES = SERIES

-- The plot box, and the furniture round it. The pane is 300 wide inside a
-- window that is already as wide as a table of abilities needs, so these are
-- what fits rather than what a chart would ask for.
local AXIS_W = 26 -- room for "100%" at the small size
local PLOT_H = 116
local FOOT = 3    -- the gap between the box and the words under it
local LEGEND_ROW = 13
local DOT = 5
local STROKE = 2

-- Where the y axis stops. The rates this draws are mostly under a third, and a
-- plot fixed at a hundred would press every line into the bottom quarter and
-- throw away the slope it exists to show. So it grows in steps rather than to
-- the exact maximum: a ceiling that moved to the data would rescale the
-- picture on every click and two abilities could not be compared by eye.
local STEPS = { 10, 20, 25, 50, 100 }

local function Ceiling(most)
	for _, step in ipairs(STEPS) do
		if most <= step then
			return step
		end
	end
	return 100
end

--------------------------------------------------------------------------
-- The rates
--------------------------------------------------------------------------

-- One outcome's chance in one band, as a percentage, or nil where the band has
-- no attempts at all. Both readings come out of Breakdown.lua rather than
-- being divided here, which is the whole reason Split hands back rows.
local function Rate(row, key)
	if not row or ns.Breakdown.Attempts(row) <= 0 then
		return nil
	end
	local fraction
	if key == "crit" then
		fraction = ns.Breakdown.CritRate(row)
	else
		fraction = ns.Breakdown.MissRateOf(row, key)
	end
	-- A landed hit with no crit is a real zero and belongs on the floor; an
	-- outcome that has never happened is also a real zero, for the same reason
	-- the window draws no row for it. Both are zero and neither is a hole:
	-- the hole is the band with nothing in it, which is the test above.
	return (fraction or 0) * 100
end

--------------------------------------------------------------------------
-- The pool
--------------------------------------------------------------------------

local function Segment(plot, index)
	local line = plot.lines[index]
	if line then
		return line
	end
	if not plot.canDraw then
		return nil
	end
	line = plot.box:CreateLine(nil, "OVERLAY")
	line:SetThickness(STROKE)
	plot.lines[index] = line
	return line
end

local function Dot(plot, index)
	local dot = plot.dots[index]
	if dot then
		return dot
	end
	dot = ns.Fill(plot.box, "OVERLAY", 1, 1, 1, 1)
	dot:SetSize(DOT, DOT)
	plot.dots[index] = dot
	return dot
end

-- Whether this outcome has ever happened to this ability, in any band the plot
-- draws. An outcome that never has gets no line at all, which is the rule the
-- rows in the window already follow: a spell nothing has ever dodged does not
-- carry a zero, because the zero is not a measurement, it is the absence of
-- one. Six flat lines along the floor is what the plot looked like without
-- this, and the two that meant something were under them.
--
-- A zero in one band of an outcome that happened in another is a different
-- thing and is drawn. You had attempts there and none of them were dodged,
-- which is the comparison the whole picture is for.
local function Happened(split, key)
	for _, band in ipairs(COLUMNS) do
		local row = split[band]
		local count = row and ((key == "crit") and row.crits or row.miss[key])
		if (count or 0) > 0 then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------
-- One series
--------------------------------------------------------------------------

-- Where a column's points sit across the box. Evenly spaced with half a column
-- of margin at each end, so the first point is not drawn on the axis and the
-- last is not drawn on the frame.
local function ColumnX(plot, index)
	return plot.column * (index - 1) + math.floor(plot.column / 2)
end

local function PointY(plot, percent)
	return UI.Round(plot.box, PLOT_H * percent / plot.ceiling)
end

-- The line and the dots for one outcome, over the three bands. Returns how
-- many of each it used, so the caller can hide the rest of the pool without
-- either of them knowing how the other counts.
local function DrawSeries(plot, series, split, lineAt, dotAt)
	local lastX, lastY
	for index, band in ipairs(COLUMNS) do
		local percent = Rate(split[band], series.key)
		if percent then
			local x, y = ColumnX(plot, index), PointY(plot, percent)

			local line = lastX and Segment(plot, lineAt + 1)
			if line then
				lineAt = lineAt + 1
				line:SetStartPoint("BOTTOMLEFT", plot.box, lastX, lastY)
				line:SetEndPoint("BOTTOMLEFT", plot.box, x, y)
				line:SetColorTexture(series.color[1], series.color[2], series.color[3], 0.9)
				line:Show()
			end

			dotAt = dotAt + 1
			local dot = Dot(plot, dotAt)
			dot:SetPoint("CENTER", plot.box, "BOTTOMLEFT", x, y)
			dot:SetColorTexture(series.color[1], series.color[2], series.color[3], 1)
			dot:Show()

			lastX, lastY = x, y
		else
			-- The hole. Nothing is carried across it, so the next band that has
			-- attempts starts a new run rather than being joined to the last
			-- one you fought.
			lastX, lastY = nil, nil
		end
	end
	return lineAt, dotAt
end

--------------------------------------------------------------------------
-- Building it
--------------------------------------------------------------------------

local function BuildBox(plot, parent, width)
	-- A whole number of pixels per column, and the box is three of them rather
	-- than whatever was left over. Every offset in this file is measured off
	-- the column, so a column of 87 and a third puts a third of a pixel under
	-- every label and every point, which is the one thing UI/Pixel.lua's grid
	-- exists to stop.
	plot.column = math.floor((width - AXIS_W) / #COLUMNS)
	plot.plotWidth = plot.column * #COLUMNS
	plot.box = UI.Box(parent, C.sunken, C.hairline)
	plot.box:SetSize(plot.plotWidth, PLOT_H)
	plot.box:SetPoint("TOPLEFT", parent, "TOPLEFT", AXIS_W, 0)

	-- Three gridlines and three labels for them: the floor, the ceiling and the
	-- middle. More would be a grid to read and the thing being read here is a
	-- direction.
	plot.grid, plot.ticks = {}, {}
	for index = 1, 3 do
		local at = UI.Round(plot.box, PLOT_H * (index - 1) / 2)

		local rule = UI.Rule(plot.box, C.hairline)
		rule:SetPoint("BOTTOMLEFT", plot.box, "BOTTOMLEFT", 0, at)
		rule:SetPoint("BOTTOMRIGHT", plot.box, "BOTTOMLEFT", plot.plotWidth, at)
		plot.grid[index] = rule

		local tick = UI.Label(parent, M.small, C.quiet, "RIGHT", UI.FLAT)
		tick:SetWidth(AXIS_W - 4)
		tick:SetPoint("RIGHT", plot.box, "BOTTOMLEFT", -4, at)
		plot.ticks[index] = tick
	end
end

local function BuildAxis(plot, parent)
	plot.columns, plot.counts = {}, {}
	local column = plot.column
	for index = 1, #COLUMNS do
		local word = UI.Label(parent, M.small, C.dim, "CENTER", UI.FLAT)
		word:SetWidth(column)
		word:SetPoint("TOPLEFT", plot.box, "BOTTOMLEFT", column * (index - 1), -FOOT)
		word:SetText(ns.Breakdown.BandAxis(COLUMNS[index]))
		plot.columns[index] = word

		-- The sample under the band it belongs to. A line through three points
		-- says nothing about which of them is worth believing, and six attempts
		-- against a boss is a line you should not act on.
		local count = UI.Label(parent, M.small, C.quiet, "CENTER", UI.FLAT)
		count:SetWidth(column)
		count:SetPoint("TOPLEFT", word, "BOTTOMLEFT", 0, -1)
		plot.counts[index] = count
	end
end

local function BuildLegend(plot, parent, width)
	plot.keys = {}
	local half = math.floor(width / 2)
	for index, series in ipairs(SERIES) do
		local key = {}
		local row = math.floor((index - 1) / 2)
		local x = ((index - 1) % 2) * half

		key.swatch = ns.Fill(parent, "ARTWORK",
			series.color[1], series.color[2], series.color[3], 1)
		key.swatch:SetSize(DOT, DOT)
		key.swatch:SetPoint("TOPLEFT", plot.counts[1], "BOTTOMLEFT",
			x, -(M.rowGap + row * LEGEND_ROW + 4))

		key.word = UI.Label(parent, M.small, C.dim, "LEFT", UI.FLAT)
		key.word:SetPoint("LEFT", key.swatch, "RIGHT", M.rowGap, 0)
		key.word:SetText(series.word)
		plot.keys[index] = key
	end
end

-- A plot of a fixed width, which is the pane's. Height is this file's: the
-- caller places the top left corner and everything below it follows from the
-- box, so a pane that grew would only ever grow under the legend.
function Graph.New(parent, width)
	local plot = { lines = {}, dots = {}, ceiling = STEPS[1] }

	plot.frame = CreateFrame("Frame", nil, parent)
	plot.frame:SetSize(width, Graph.Height())

	BuildBox(plot, plot.frame, width)

	-- Probed rather than assumed, the way every other client call in this addon
	-- that a build could be missing is probed. A client without lines still
	-- gets the box, the grid, the axis and the dots, which is a scatter of six
	-- colours over three columns and is most of the answer.
	plot.canDraw = type(plot.box.CreateLine) == "function"

	BuildAxis(plot, plot.frame)
	BuildLegend(plot, plot.frame, width)
	return plot
end

-- What a plot takes, so the window can place what goes under it without
-- knowing how this file stacks its own parts.
function Graph.Height()
	return PLOT_H + FOOT + M.small * 2 + M.rowGap
		+ math.ceil(#SERIES / 2) * LEGEND_ROW + 4
end

--------------------------------------------------------------------------

-- Everything the selection can move. split is what ns.Breakdown.Split handed
-- back: a row per band, of the shape the derived figures read.
function Graph.Draw(plot, split)
	local most = 0
	for _, series in ipairs(SERIES) do
		if Happened(split, series.key) then
			for _, band in ipairs(COLUMNS) do
				local percent = Rate(split[band], series.key)
				if percent and percent > most then
					most = percent
				end
			end
		end
	end
	plot.ceiling = Ceiling(most)


	for index = 1, 3 do
		plot.ticks[index]:SetText(("%d%%"):format(plot.ceiling * (index - 1) / 2 + 0.5))
	end

	for index, band in ipairs(COLUMNS) do
		plot.counts[index]:SetText(("%d"):format(ns.Breakdown.Attempts(split[band])))
	end

	local lineAt, dotAt = 0, 0
	for index, series in ipairs(SERIES) do
		local here = Happened(split, series.key)
		if here then
			lineAt, dotAt = DrawSeries(plot, series, split, lineAt, dotAt)
		end
		-- The legend keeps its shape whichever ability is picked, so it can be
		-- learned once. What changes is which of the six are lit.
		local key = plot.keys[index]
		key.swatch:SetAlpha(here and 1 or 0.25)
		local word = here and C.dim or C.quiet
		key.word:SetTextColor(word[1], word[2], word[3])
	end

	for index = lineAt + 1, #plot.lines do
		plot.lines[index]:Hide()
	end
	for index = dotAt + 1, #plot.dots do
		plot.dots[index]:Hide()
	end
	return lineAt, dotAt
end

-- How many segments and how many points the last draw put on the box, for
-- scripts/harness and for anything else that has to prove a hole in the record
-- came out as a hole rather than as a line to the floor.
function Graph.Drawn(plot)
	local lines, dots = 0, 0
	for _, line in ipairs(plot.lines) do
		if line:IsShown() then lines = lines + 1 end
	end
	for _, dot in ipairs(plot.dots) do
		if dot:IsShown() then dots = dots + 1 end
	end
	return lines, dots
end
