local ADDON, ns = ...

local UI = ns.UI
local C, M = UI.Color, UI.Metric

--------------------------------------------------------------------------
-- The feed
--
-- A column of things that happened, newest at the top, older below it, and the
-- older ones still there when you scroll down to look.
--
-- **Why this is not UI/Log.lua.** That file is a column of strings and the
-- client's own ScrollingMessageFrame draws it, which is exactly right for
-- conversation and cannot do this: a message frame holds text and nothing else,
-- so an icon per line is not something it can be asked for. A row here is an
-- icon, a name, a number and a coloured mark down its left edge, which is four
-- regions the client has no line type for.
--
-- **Why this is not UI/Stack.lua and UI/Scroll.lua.** Those lay a column out by
-- asking every row how tall it is and placing them one under the next, which
-- means a row arriving reflows the whole column. UI/Log.lua's header already
-- argues that case and refuses it, and a feed is the same argument again with a
-- worse constant: four hundred entries measured every time a mob drops
-- something.
--
-- **So the rows do not move.** There is one frame per visible row, built once,
-- anchored once, and never anchored again. What arrives is written into a ring
-- of entries, and scrolling is an offset into that ring: the rows keep their
-- positions and repaint from a different place in the list. Ten rows repaint
-- whether the feed holds ten entries or four hundred, so a scroll costs the
-- same as a drop and both cost ten guarded writes.
--
-- That also means there is no clipping to arrange, no canvas to move and no
-- ScrollFrame to probe. The rows exactly fill the space, so there is nothing
-- to clip.
--
-- **An arrival marks and a frame draws.** A feed changes when something happens
-- to you, which is an event, and it changes when you scroll it, which is a
-- gesture. Neither of those is a clock, and a row carries none: a relative
-- timestamp would be the one thing here that has to be redrawn while nothing is
-- happening, which is why the time lives in the tooltip.
--
-- What the tick is for is the other end of that. In a pull the combat log
-- arrives faster than the screen is drawn, so painting on the arrival painted
-- thirteen rows three or four times for one frame the player ever saw. Push
-- marks the feed instead and the tick paints whatever is marked, once, on the
-- frame that is about to be drawn. An idle feed costs one field read a frame,
-- and a feed nobody can see costs nothing at all: the tick hangs off the feed's
-- own frame, so the client stops calling it the moment the column is hidden.
--
-- A feed that has never been built has no frame and no tick, and nothing can
-- mark it. That is the shape on purpose: what is not there is not dirty.
--
-- **A row has three text columns and the middle one is optional.** A name and a
-- number were not enough for the combat log: "Overpower 321" and "Plains
-- Creeper 26" are the same shape and only one of them is a spell, so there was
-- no reading a row and knowing who had done what to whom. The middle column is
-- dim, right aligned against the number, and asked for by the caller in units,
-- so the loot feed keeps two columns and the combat feed gets three without
-- either being a special case in here. All three widths are decided per resize
-- rather than per row, which is why a run of numbers reads as a column.
--
-- **A marker is a break in the timeline, not an entry in it.** Feed:Mark pushes
-- one and it draws as a band across the whole row with a word on it: no icon,
-- no middle column, nothing a thing that happened to you can look like. Here
-- rather than faked in Feeds/Combat.lua because "one set of events ends and
-- another begins" is a thing any feed wants, and a marker built out of an
-- ordinary row is one an ordinary row can be mistaken for.
--------------------------------------------------------------------------

-- Every number is a unit, which is one physical pixel inside a frame
-- ns.UI.Adopt has taken onto the grid, and a whole block of them above zoom 1.
--
-- The icon is 27 for the reason Meter/Window.lua's is: the client stores a
-- spell or item icon at 64 texels, UI/Draw.lua's crop leaves 54 of them, and a
-- draw is one texel per pixel only at 54 and 27. Everything else on a row
-- follows from it.
-- What an icon is drawn at before anybody moves the slider, and the two units
-- of row it leaves round itself. The row is the icon plus the pad rather than a
-- number of its own, because the two were 29 and 27 and a slider that moved one
-- without the other would either crop the art or leave a gap that grew.
local ICON = 27
local ROW_PAD = 2
local ROW_GAP = 1
-- The strip over the rows. It was 16, which was a heading and nothing else in
-- it; the delete list's control is a square you have to be able to hit with a
-- mouse at a UI scale of one half, and 16 left it no air at all.
local HEADER = 20
local RULE = 1
local INSET = 3     -- the stripe to the icon
local STRIPE = 2    -- the coloured mark down the left of a row
local GUTTER = 5    -- the icon to the name
local PAD = 4       -- one text column to the next

-- How small and how large a row's icon can be asked to go.
--
-- The floor is the text, not the art. It was ns.UI.OutlineFloor's: every string
-- on a row carried a rim, a rim wants 14 pixels of glyph under it, and a row
-- shorter than 16 was a row whose name did not fit in it however small the
-- picture got. The rim is gone and the wash under the row is what holds the
-- text off the world, so the floor is no longer a font's minimum; 16 stands
-- until somebody measures a shorter row with the wash actually under it. The
-- ceiling is one step past ns.UI.IconTexels halved, which is 27 and the one
-- size in this range that draws a stored texel per screen pixel; past 40 a feed
-- row is taller than the tooltip describing it.
--
-- Published rather than local because Feeds/Feature.lua puts the stepper on a
-- panel page and a second copy of the range is a second thing to keep in step.
UI.FEED_ICON, UI.FEED_ICON_LOW, UI.FEED_ICON_HIGH = ICON, 16, 40

-- One control cell: the cross and the can on a row, and the height of the
-- delete list's control on the strip. Sixteen units inside a twenty unit
-- header, which is the same two units of air the heading text gets.
local CHIP = 16
-- The mark inside a cell. It was fourteen, which put a mark against the edge
-- of its own square; eleven leaves it two and a half units on each side.
local CHIP_MARK = 11
-- The xmark, which is the letter scripts/bake-glyphs.sh put it on.
local CLEAR = "x"
-- The trash can, on a row beside the cross and on the delete list's control in
-- the strip. scripts/bake-glyphs.sh put it on `t` for the bag window's clear.
local TRASH = "t"
-- The delete list's control: the can, a count beside it and the inset round
-- both. Wide enough for a two digit count at a cell's mark size.
local LIST = 36

-- The number column, fixed rather than grown to fit. A string that sizes itself
-- puts every number at a different distance from the edge, which is a ragged
-- column of damage. Six glyphs at the row size, which is a five figure hit with
-- a crit mark on it.
--
-- 42 while the addon drew in Arial Narrow, whose digits are 0.456 em, so six of
-- them at fourteen pixels came to 38 and the column carried four spare. Noto
-- Sans is 0.572 and the same six come to 48, so the column is 52 and carries
-- the same four. A five figure crit was the string this was sized for and it is
-- the string that would have gone off the left edge of the row.
local AMOUNT = 52

-- Shadowed, every string in this file, and the wash under the row is why.
--
-- A feed looks like it is drawn on a surface, and it is not one this addon can
-- promise anything about: the background is a slider the player drags and it
-- goes to zero. Every string here was rimmed for that, and a rim is a patch for
-- having no ground. There is ground now, painted by the row itself, so the
-- glyph keeps the pixel of every stroke the rim was spending and takes a shadow
-- instead, which is what the character sheet draws in over the same world.
--
-- Both sizes stay at 14 and neither is a setting. The floor that used to hold
-- them there is gone with the rim, and 14 is still what a name and a five
-- figure number want in a 29 pixel row; a size a player could drag is a column
-- whose three text columns stop lining up with each other.
local ROW_TEXT = 14
local HEADER_TEXT = 14

-- How far one notch of the wheel moves. Three is what UI/Log.lua uses, what
-- UI/Scroll.lua uses, and what every window in the game uses.
local WHEEL_ROWS = 3

-- The most rows a feed will ever be asked to draw, and how many entries it
-- keeps behind them. Neither is built to this number: the rows are built up to
-- what the setting asks for, which ships at ten, and the ring fills as things
-- drop. This is the ceiling the setting is clamped to and nothing else.
local MAX_ROWS = 24
local HELD = 400

-- How far back Feed:Fold looks for the row an arrival belongs on.
--
-- Sixteen entries is a corpse and the two before it, which is the whole of what
-- a fold is for. The ring is the other number and it is four hundred: a walk of
-- it per arrival is four hundred comparisons on the path a pull drives.
local LOOKBACK = 16

-- How often the box over a parked cursor is filled again.
--
-- With the mouse resting on the top row of a live feed the entry under it
-- changes on every arrival, and following that unthrottled is a Tip.Build, a
-- Scan.Read and a Tooltip.Layout per combat log line. Five times a second is
-- faster than anybody reads a tooltip and it is two orders of magnitude below
-- what a pull was asking for. What it costs is that the box can name the row
-- before last for a fifth of a second, which is a box you are still reading.
local REOPEN = 0.2

-- What the bottom row fades to when there is more underneath it.
--
-- The one piece of decoration in this file, and it is carrying information
-- rather than atmosphere: it is the difference between a feed that has stopped
-- and a feed that continues past the bottom edge. A feed with a scroll bar says
-- the same thing in eight pixels off to the side, which is not where you are
-- looking, and the loot feed has no bar, so there this is the only sign of
-- more. Written once per row per paint, behind a guard, and it costs nothing
-- because it is a function of the row's position rather than of the clock.
local FADE = 0.45

-- How far the palette's painting is dimmed under a row's text. The desert's
-- floor is sand at over half brightness, and a common item's white on that is
-- a name you squint at; at this it is the painting in shade, and the forest's
-- and the arcane floor, which start darker, only get deeper.
local FLOOR_DIM = 0.45

local Feed = {}
Feed.__index = Feed

-- How many screen pixels of art a row icon draws at a given size and zoom, and
-- whether that is one stored texel per pixel.
--
-- Read out of ns.UI.IconSizes rather than typed, so changing the crop in
-- UI/Draw.lua moves this answer instead of leaving a stale number in a panel
-- note. Meter/Window.lua answers the same question about its own rows and the
-- two are deliberately separate: they are allowed to pick different icon sizes,
-- and a shared function would be a shared decision.
--
-- The size is an argument now that it is a setting. It was this file's own
-- constant and the panel note that read it was therefore telling every player
-- the same thing whatever they had dragged the slider to, which is the exact
-- failure a note computed from a constant always has.
function UI.FeedIcons(size, zoom)
	local drawn = (size or ICON) * (zoom or 1)
	for _, exact in ipairs(UI.IconSizes()) do
		if exact == drawn then
			return drawn, true
		end
	end
	return drawn, false
end

--------------------------------------------------------------------------
-- One row
--------------------------------------------------------------------------

-- A button on a row: the cross that takes the row out, and the can that puts
-- its item on the delete list. The addon's own button at a strip cell's size
-- with its mark dimmed, laid over the right end of the row and up on the row
-- under the cursor and no other.
--
-- Over the count rather than beside it. A row has no spare column, and a fourth
-- one would narrow every name in the feed for a control that is up on one row
-- at a time. The count is in the hover beside it.
--
-- The entry is read off the row at the click rather than when the button comes
-- up, because a drop between the two moves every row down one and an entry
-- taken at the hover is the row that used to be there.
--
-- `right` is how far the button's right edge sits in from the row's, in units,
-- so the can stands beside the cross rather than on it.
local function RowButton(feed, row, mark, right, tip, press)
	local unit = feed.unit
	local button = UI.Button(row, { label = mark, glyph = true, size = CHIP_MARK,
		width = CHIP * unit, height = CHIP * unit, tip = tip,
		onClick = function()
			-- One guard for every button on every row of this feed. A bounce lands
			-- on the same button with the next entry already under it.
			if row.shownEntry and feed.ready() then
				press(row.shownEntry)
			end
		end })
	button:SetPoint("RIGHT", row, "RIGHT", -right * unit, 0)
	button.text:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

	-- Off the button and back onto the row is still the row. The other half of
	-- this is the row's own OnLeave.
	local leave = button:GetScript("OnLeave")
	button:SetScript("OnLeave", function(self)
		leave(self)
		if not row:IsMouseOver() then
			feed:Leave()
		end
	end)
	UI.PassCamera(button)
	button:Hide()
	return button
end

-- The buttons a row carries, for a feed that asked for them.
local function RowButtons(feed, row)
	feed.ready = feed.ready or UI.Debounce()
	if feed.removable then
		row.cross = RowButton(feed, row, CLEAR, INSET,
			feed.removeTip or "Take this row out of the feed.",
			function(entry) feed:Remove(entry) end)
	end
	if feed.watch then
		row.trash = RowButton(feed, row, TRASH, INSET + (feed.removable and CHIP or 0),
			feed.watch.row, function(entry) feed:Watch(entry) end)
	end
end

-- Whether the pointer is on one of a row's own buttons, which is still the row.
local function Under(button)
	return button and button:IsShown() and button:IsMouseOver() or false
end

-- The ground the row's strings are read on. Its own function because BuildRow
-- went over a hundred lines when the wash learned to paint.
local function BuildWash(feed, row)
	-- The column has no ground it can promise: the background behind a feed is
	-- a slider that reaches zero, and at zero every row is text over grass. Solid at the stripe and gone by
	-- the end of the text, which makes it a shadow the size of the row rather
	-- than a panel behind the column.
	--
	-- Made before the glow rather than after it. Both are on BACKGROUND and the
	-- client draws that layer in the order the textures were made, so a wash
	-- made second would take the light back out of the left half of whichever
	-- row the cursor is on.
	--
	-- Neither of its two numbers is written here. How wide it is follows the
	-- icon and the text columns, which is ShapeRow's, and how strongly it is
	-- painted is the background slider, which is Feed:Wash's.
	--
	-- Under a palette with a painting the wash is that painting's floor, dimmed
	-- to hold the text and at the shadow's own alpha, so the slider's top is
	-- still never a panel. ShapeRow cuts each row its band of the tile.
	row.floor = UI.Floor()
	local tint = row.floor and { FLOOR_DIM, FLOOR_DIM, FLOOR_DIM, C.shadow[4] } or C.shadow
	row.wash = UI.Wash(row, tint, "LEFT", "BACKGROUND", row.floor and row.floor[1])
	row.wash:SetPoint("TOPLEFT")
	row.wash:SetAlpha(feed.washAt)
end

local function BuildRow(feed, index)
	local unit = feed.unit
	local row = CreateFrame("Frame", nil, feed.frame)
	-- Both numbers are written in Resize, because both follow the icon size and
	-- that is a slider. A row built at one height and never told about the next
	-- one is a column that keeps the size it had at login.
	row:SetSize(1, 1)
	row.index = index

	BuildWash(feed, row)

	-- Behind everything else, and only while the mouse is on it. A feed you can
	-- hover has to answer the hover with something other than a tooltip
	-- appearing off to one side, or there is no telling which row it is about.
	row.glow = ns.Fill(row, "BACKGROUND", C.hover[1], C.hover[2], C.hover[3], 0.5)
	row.glow:SetAllPoints()
	row.glow:Hide()

	-- The timeline itself. One segment per row, separated by the row gap, so a
	-- run of entries reads as a ribbon down the left edge broken into the
	-- things that made it. Its colour is the entry's, which for loot is the
	-- item's quality and for the combat log is what kind of event it was, and
	-- that is most of what you get from a feed at a glance without reading it.
	row.stripe = ns.Fill(row, "ARTWORK", C.edge[1], C.edge[2], C.edge[3], 1)
	row.stripe:SetPoint("TOPLEFT")
	row.stripe:SetPoint("BOTTOMLEFT")
	row.stripe:SetWidth(STRIPE * unit)

	row.icon = UI.Icon(row, "ARTWORK")
	row.icon:SetPoint("LEFT", row, "LEFT", (STRIPE + INSET) * unit, 0)

	-- A ring round the icon, for the one thing about an item that its quality
	-- colour cannot say. A reagent a profession of yours still learns from is
	-- white, the same white as a stack of linen it does not, and the two rows
	-- would otherwise read exactly alike.
	--
	-- A frame rather than four textures anchored to the icon, because ns.Outline
	-- pins its edges to the corners of the frame it is given and the icon is a
	-- texture. Built once per row and shown on the rows that have earned it: the
	-- alternative is building it on the arrival that needs it, on the path a
	-- pull drives.
	row.mark = UI.Box(row, nil, C.edge)
	row.mark:SetPoint("TOPLEFT", row.icon, "TOPLEFT")
	row.mark:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT")
	row.mark:Hide()

	-- A picture the entry lays over its icon, for a feed whose item has one the
	-- client already draws. The path is the entry's `badge`; this file knows it
	-- is a texture and nothing about what it means. OVERLAY because the client
	-- draws its own at that layer over a bag square's icon.
	row.badge = row:CreateTexture(nil, "OVERLAY")
	row.badge:SetAllPoints(row.icon)
	row.badge:Hide()

	-- Every column is given its width in Resize, and never its right edge.
	-- Chaining each one's right edge to the next one's left, which is what this
	-- did with two columns, lets a long name push a number about and makes the
	-- columns disagree row to row. A clipped name is still the right item; a
	-- clipped number is a lie, which is Meter/Window.lua's rule and is why the
	-- number is the column that never gives way.
	--
	-- The name is anchored in Resize rather than here, because where it starts
	-- is behind the icon and the icon is a slider. The other two are pinned to
	-- the right edge and do not move when the picture does.
	row.name = UI.Label(row, ROW_TEXT, C.text, "LEFT", UI.SHADOW)

	row.note = UI.Label(row, ROW_TEXT, C.dim, "RIGHT", UI.SHADOW)
	row.note:SetPoint("RIGHT", row, "RIGHT", -(INSET + AMOUNT + PAD) * unit, 0)
	row.note:Hide()

	row.amount = UI.Label(row, ROW_TEXT, C.text, "RIGHT", UI.SHADOW)
	row.amount:SetPoint("RIGHT", row, "RIGHT", -INSET * unit, 0)

	-- The word on a marker, which starts where the icon would and therefore
	-- cannot be the same font string as the name. Its own string rather than the
	-- name moved, because moving it means a SetPoint on the repaint path and a
	-- second font string per row is both cheaper and incapable of going stale.
	row.caption = UI.Label(row, ROW_TEXT, C.text, "LEFT", UI.SHADOW)
	row.caption:SetPoint("LEFT", row, "LEFT", (STRIPE + INSET) * unit, 0)
	row.caption:Hide()

	row:SetScript("OnEnter", function(self)
		feed:Enter(self.index)
	end)
	row:SetScript("OnLeave", function()
		-- Onto one of the row's own buttons is still on the row. The client hands
		-- the pointer to the child and tells the row it left, and a Leave here
		-- would hide the button from under the click it was reached for.
		if Under(row.cross) or Under(row.trash) then
			return
		end
		feed:Leave()
	end)
	UI.PassCamera(row)
	row:EnableMouse(false)
	RowButtons(feed, row)

	row:Hide()
	return row
end

-- The three regions the strip over the rows is made of, and the line that
-- stands where the rows would be before anything has happened.
--
-- All four are built whether or not anything is going to ask for them, because
-- a frame cannot be destroyed on this client: a heading made the first time
-- somebody switched one on is a heading that can never be unmade, and the pool
-- would grow by one per click. Feed:Chrome shows and hides them.
local function BuildHeader(feed)
	if feed.title then
		feed.heading = UI.Label(feed.frame, HEADER_TEXT, C.dim, "LEFT", UI.SHADOW)
		feed.heading:SetPoint("TOPLEFT", feed.frame, "TOPLEFT",
			INSET * feed.unit, -INSET * feed.unit)
		feed.heading:SetText(feed.title)
	end

	feed.tally = UI.Label(feed.frame, HEADER_TEXT, C.quiet, "RIGHT", UI.SHADOW)
	feed.tally:SetPoint("TOPRIGHT", feed.frame, "TOPRIGHT",
		-INSET * feed.unit, -INSET * feed.unit)

	feed.rule = ns.Fill(feed.frame, "ARTWORK", C.hairline[1], C.hairline[2],
		C.hairline[3], 1)
	feed.rule:SetPoint("TOPLEFT", feed.frame, "TOPLEFT", 0, -HEADER * feed.unit)
	feed.rule:SetHeight(RULE * feed.unit)

	feed.blank = UI.Label(feed.frame, ROW_TEXT, C.quiet, "LEFT", UI.SHADOW)
	feed.blank:SetText(feed.empty or "")
	return feed
end

-- One paint per frame, and none at all on a frame where nothing arrived.
--
-- This is the whole of what the tick does: read a field and, on the frames
-- something happened, draw. In a pull the combat log lands three or four times
-- between two frames of the screen and the column was repainting for each of
-- them, which is thirteen rows drawn three times for one frame anybody saw.
--
-- The frame is the second argument rather than a closure, because
-- scripts/hot.lua walks out from the function ns.UI.Ticker was handed and a
-- closure is a body it cannot name.
-- The scroll bar down the right of the rows, for a feed that asked for one. Its
-- own function because UI.Feed reached a hundred and five lines when the delete
-- list arrived and the gate is a hundred; this is the block of it that stands
-- alone.
local function BuildBar(feed)
	local bar = UI.ScrollBar(feed.frame, function(_, value)
		-- The bar is written back to on every arrival, and that write fires
		-- this. The latch is UI/Scroll.lua's and UI/Log.lua's, and it is here
		-- for the same reason: without it the write and the handler chase each
		-- other for a frame every time something drops.
		if feed.syncing then
			return
		end
		feed:ScrollTo(value)
	end)
	if bar then
		bar:SetPoint("BOTTOMRIGHT")
		bar:Hide()
	end
	return bar
end

local function Repaint(_, frame)
	local feed = frame.feed
	if feed.stale then
		feed:Paint()
	end
end

--------------------------------------------------------------------------
-- Standing one up
--
-- opts.title     the word over the column, and nothing drawn above the rows
--                when there is none
-- opts.empty     what is written where the rows would be before anything has
--                happened
-- opts.held      how many entries this feed keeps, HELD when it does not say
-- opts.bar       true for a scroll bar down the right of the rows. Without one
--                the wheel still scrolls and the rows get the bar's column
-- opts.note      how wide the dim middle column is, in units, and zero for a
--                feed that does not want one
-- opts.onTooltip function(entry), answering the table UI/Tooltip.lua renders for
--                the row under the cursor
-- opts.unit      one design pixel in the parent's units, which the caller
--                already read off the frame it adopted
-- opts.removable the cross on the row under the cursor that takes its entry out
--                of the feed: true, or a table of tip, the sentence the cross
--                says, and gone(entry), called for every entry a sweep takes
--                out while its table still holds it
-- opts.watch     the delete list, or nothing for a feed with none. A table:
--                can(entry), add(entry) answering a match for Feed:Sweep,
--                count(), subject() for the strip control's hover, clear(), and
--                row, the sentence the can on a row says
-- opts.onLayout  function(), called when the strip has to come up or go for the
--                list, so whatever sized the frame can size it again
--------------------------------------------------------------------------

function UI.Feed(parent, opts)
	opts = opts or {}

	local feed = setmetatable({
		unit = opts.unit or UI.Unit(parent),
		title = opts.title,
		empty = opts.empty,
		note = opts.note or 0,
		onTooltip = opts.onTooltip,
		removable = opts.removable and true or false,
		onRemove = type(opts.removable) == "table" and opts.removable.gone or nil,
		removeTip = type(opts.removable) == "table" and opts.removable.tip or nil,
		watch = opts.watch,
		onLayout = opts.onLayout,
		cap = opts.held or HELD,
		-- The icon size, and the row height that follows it. Both are settings
		-- and both are written by Resize; these are what a feed draws at before
		-- anybody has said otherwise.
		icon = ICON,
		row = ICON + ROW_PAD,
		-- Every entry this feed holds, made as the feed fills and never again. A
		-- ring rather than a list that is trimmed: the four hundred and first drop
		-- overwrites the first rather than allocating a table and dropping another,
		-- so a feed in its steady state allocates nothing at all. It was four
		-- hundred tables per feed at login, for a column that mostly holds a dozen
		-- things by the time you log out.
		ring = {},
		written = 0,
		-- How many of those the ring still holds. It was min(written, cap) until
		-- a row could be taken out: Feed:Remove steps `written` back to keep the
		-- ring's arithmetic, and once the ring has lapped that sum is the cap
		-- however much has gone.
		held = 0,
		offset = 0,
		visible = 0,
		rows = {},
		hovered = nil,
		width = 1,
		-- What ShapeRow is told, filled in by every resize and never rebuilt.
		geom = {},
		-- How strongly the ground under a row is painted. Full until somebody
		-- says otherwise, which Feeds/Stream.lua does from the setting a moment
		-- after this: a feed built by anything else is one drawn over the world
		-- with no slider in front of the player to turn it down.
		washAt = 1,
		-- On screen until told otherwise. Feeds/Stream.lua writes this from the
		-- setting at login, and a feed built by anything else is one somebody is
		-- looking at.
		awake = true,
		-- Whether the column owes the screen a paint. Set by an arrival, and by
		-- a paint that could not run because nobody could see it. Cleared by
		-- the paint that pays it. A gesture and a settings change draw at once
		-- rather than marking: neither of them is on a path that repeats.
		stale = false,
	}, Feed)

	feed.frame = CreateFrame("Frame", nil, parent)
	-- The feed found on its own frame rather than closed over, which is the
	-- shape UI/Ticker.lua asks for and the reason it hands the frame back to the
	-- tick: there is one of these per feed and a ticker takes a named function.
	feed.frame.feed = feed
	UI.Ticker(feed.frame, 0, "feed", Repaint)

	BuildHeader(feed)

	-- What the strip carries beyond its heading, which is the delete list's
	-- control for a feed that has one.
	if opts.watch then
		feed:BuildList()
	end

	if opts.bar then
		feed.bar = BuildBar(feed)
	end

	-- The strip as it was asked for: a title if there is one. Last, because it
	-- anchors the scroll bar as well as the rows, and Feeds/Stream.lua writes
	-- both from settings a moment later.
	feed:Chrome(feed.title ~= nil)
	return feed
end

--------------------------------------------------------------------------
-- The strip over the rows
--
-- One setting and one strip. The title is a word over a column that already
-- says what it holds, which on the loot feed is an item icon, an item name in
-- the item's own quality colour and a stack size. Nothing in that needs the
-- word "Loot" over it, and a window with no chrome on it is one more piece of
-- the screen given back to the game.
--
-- What the strip cannot be is independent of the geometry: everything below it
-- has to know whether there is one, which is why one number is worked out here
-- and Resize and Sync read it rather than each deciding again.
--------------------------------------------------------------------------

function Feed:Chrome(titled)
	titled = (titled and self.heading) and true or false
	-- A delete list with anything on it holds the strip up on its own, because
	-- its control is the only thing on screen saying drops are being refused.
	local count = self.list and self.watch.count() or 0
	local listed = count > 0
	-- And so does an owner that has taken the right end, see Feed:Aside.
	self.head = (titled or listed or self.aside) and (HEADER + RULE) or 0
	self.titled, self.listed = titled, listed

	-- At the strip's own inset, centred on the header's height.
	if self.list then
		self.list.count:SetText(tostring(count))
		self.list:ClearAllPoints()
		self.list:SetPoint("TOPLEFT", self.frame, "TOPLEFT", INSET * self.unit,
			-math.floor((HEADER - CHIP) / 2) * self.unit)
		self.list:SetShown(listed)
	end

	if self.heading then
		if titled then
			self.heading:Show()
		else
			self.heading:Hide()
		end
	end

	-- The tally and the hairline are the strip rather than things on it, so
	-- they go with it entirely. A count floating over the first row with no
	-- rule under it reads as a number that belongs to that row.
	if self.head > 0 then
		self.tally:Show()
		self.rule:Show()
	else
		self.tally:Hide()
		self.rule:Hide()
	end

	self.blank:ClearAllPoints()
	self.blank:SetPoint("TOPLEFT", self.frame, "TOPLEFT",
		(STRIPE + INSET) * self.unit, -(self.head + INSET) * self.unit)
	if self.bar then
		self.bar:ClearAllPoints()
		self.bar:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -self.head * self.unit)
		self.bar:SetPoint("BOTTOMRIGHT")
	end
	return true
end

-- The right end of the strip, handed to the owner.
--
-- It is the count until somebody says otherwise. The loot feed says otherwise:
-- it puts the session's takings there, and this file does not know that is
-- money. Nil gives the end back to the count. Text holds the strip up the way a
-- title does, so an owner that sets it calls Chrome after, and a text that only
-- changes which words are there needs nothing else.
--
-- Answers the string, which is what an owner that wants to hover it anchors a
-- mouse frame to. A font string takes no mouse of its own.
function Feed:Aside(text, color)
	local tone = text and color or C.quiet
	if self.aside ~= text then
		self.aside = text
		self.tally:SetText(text or "")
		-- The count's own guard, told its string is no longer on the screen, so
		-- the paint this books writes it back when the owner lets go.
		self.shownTally = nil
		if not text then
			self.stale = true
		end
	end
	if self.asideTone ~= tone then
		self.asideTone = tone
		self.tally:SetTextColor(tone[1], tone[2], tone[3])
	end
	return self.tally
end

--------------------------------------------------------------------------
-- The delete list
--
-- Items a player has told the feed never to draw again. The list is the
-- caller's and so is the refusing: Feeds/Loot.lua turns a listed item away
-- before it becomes an entry. This file owns the two controls, the can on a
-- row that adds to the list and the control on the strip that says it exists.
--
-- **The strip control is loud on purpose.** A list that quietly eats drops is
-- a feed that looks broken a week later. So it is the one thing on the strip in
-- the danger red, it carries the count, and while the list has anything on it
-- the strip is up even with the title off. Pressed, it empties the list and
-- goes.
--------------------------------------------------------------------------

function Feed:BuildList()
	local unit = self.unit
	local list = UI.Button(self.frame, { label = TRASH, glyph = true, size = CHIP_MARK,
		width = LIST * unit, height = CHIP * unit, tone = C.danger,
		onClick = function() self:Unwatch() end })
	list.text:ClearAllPoints()
	list.text:SetPoint("LEFT", list, "LEFT", INSET * unit, 0)
	-- The size raw rather than in units: inside a frame ns.UI.Adopt has taken
	-- onto the grid a font size already is a pixel height. Multiplied, SetFont
	-- is asked for a fraction, refuses it and draws nothing at all.
	list.count = UI.Label(list, CHIP_MARK + 1, C.text, "RIGHT", UI.SHADOW)
	list.count:SetPoint("RIGHT", list, "RIGHT", -INSET * unit, 0)

	-- Its own hover rather than the button's: a title over the items, and the
	-- hotter red rather than the grey every other button goes.
	list:SetScript("OnEnter", function(this)
		UI.Tint(this.bg, C.dangerHover)
		ns.Tip.Settle(this, self.watch.subject(), "control", true, ns.Tip.HOLD)
	end)
	list:SetScript("OnLeave", function(this)
		UI.Tint(this.bg, this.tone)
		ns.Tip.Close()
	end)
	UI.PassCamera(list)
	list:Hide()
	self.list = list
	return list
end

-- The list said something different from what it last said. The count on the
-- control is written, and the strip comes up or goes when the list starts or
-- ends, through whatever sized the frame where there is one.
function Feed:Watched()
	local list = self.list
	if not list then
		return false
	end
	local count = self.watch.count()
	list.count:SetText(tostring(count))
	if (count > 0) ~= self.listed then
		if self.onLayout then
			self.onLayout()
		else
			self:Chrome(self.titled)
			self:Resize(self.width, self.visible, self.icon)
		end
	end
	return count > 0
end

-- The entry's item onto the list and every row of it out of the feed, which is
-- what the can on a row is pressed for. Answers how many rows went.
function Feed:Watch(entry)
	local watch = self.watch
	if not (watch and entry and watch.can(entry)) then
		return 0
	end
	local gone = self:Sweep(watch.add(entry))
	ns.Tip.Close()
	self:Watched()
	return gone
end

-- The list emptied, which is what the strip control is pressed for. The control
-- goes from under the cursor that pressed it, so its box goes with it.
function Feed:Unwatch()
	if not self.watch then
		return false
	end
	self.watch.clear()
	ns.Tip.Close()
	self:Watched()
	return true
end

--------------------------------------------------------------------------
-- What is in it
--
-- The ring counts from the newest backwards, because that is the only order a
-- feed is ever read in: row one is the newest, row two is the one before it,
-- and the offset is how many have been scrolled past.
--------------------------------------------------------------------------

-- How many entries the feed is holding, which is what the column is a view of
-- and what the scrollbar measures against.
function Feed:Count()
	return self.held
end

-- The nth entry counting back through the ring, where zero is the one that
-- arrived last. This is what row n draws when the view is at the top, and what
-- the offset counts in.
function Feed:Held(n)
	if n < 0 or n >= self:Count() then
		return nil
	end
	return self.ring[((self.written - 1 - n) % self.cap) + 1]
end

-- The slot the next entry goes in, wiped and handed over for the caller to
-- fill. The feed owns it: filling it and then not calling Push leaves it to be
-- wiped again by the next caller, and holding on to it past a Push is holding a
-- table the ring will write over.
--
-- Two calls rather than one that takes the fields, because the fields differ
-- per feed. A loot row is an item and a stack size; a combat row is a spell, a
-- number and four things only the tooltip reads. Passing either as arguments
-- would fix one feed's shape into this file, and passing a table would
-- allocate one per event on a path the combat log drives.
function Feed:Entry()
	local at = (self.written % self.cap) + 1
	local slot = self.ring[at]
	if not slot then
		-- The first time round the ring, which is the only time this allocates.
		-- Past the cap every slot is one that has been here since.
		slot = {}
		self.ring[at] = slot
		return slot
	end
	-- Past the cap this slot is holding the oldest entry, and wiping it is the
	-- moment that entry leaves the feed.
	for key in pairs(slot) do
		slot[key] = nil
	end
	return slot
end

-- Make the filled slot the newest, and mark the column.
--
-- Marked rather than drawn. This runs on the path the combat log drives and
-- Repaint above is what turns however many arrivals landed between two frames
-- into the one paint the player was ever going to see. Everything below this
-- line is table writes, which is what makes a hidden feed and a busy one cost
-- nearly the same.
--
-- The offset moves with it when you are reading history. Everything below the
-- top has just been pushed one row down the list, so leaving the offset alone
-- would scroll the feed under your eyes every time a mob died. At the top,
-- where the offset is zero, the new entry simply arrives, which is the whole
-- point of being at the top.
function Feed:Push()
	local slot = self.ring[(self.written % self.cap) + 1]
	slot.at = GetTime()
	self.written = self.written + 1
	self.held = math.min(self.held + 1, self.cap)

	if self.offset > 0 and self.offset < self:Room() then
		self.offset = self.offset + 1
	end

	self.stale = true
	return slot
end

-- Add to an entry the feed is already holding, rather than push a second row
-- saying the same thing.
--
-- The caller has taken a slot from Feed:Entry and filled it. This walks back
-- from the newest through LOOKBACK held entries, hands each of them and that
-- filled slot to `match`, and on the first yes marks the column and returns the
-- entry it stopped at. Nil is nobody having taken it, and the caller pushes as
-- it always did.
--
-- What the caller may do with what comes back is write its own fields on it,
-- `at` included, because a row that folded is a row about the last one that
-- arrived. What it may not do is keep the entry past the call, for the reason
-- Feed:Entry gives: it is a ring slot, and the push a lap from now writes over
-- it.
--
-- Nothing is pushed. `written` does not move, so the row keeps its place and
-- the offset keeps its place under somebody reading history. An entry that
-- folded and then jumped to the newest row would reorder the column under their
-- eyes, which is what Feed:Push's offset arithmetic is written to prevent, and
-- the number on the bandage row climbs where the row already is.
function Feed:Fold(match)
	local fresh = self.ring[(self.written % self.cap) + 1]
	if not fresh then
		return nil
	end

	local depth = math.min(self:Count(), LOOKBACK)
	for back = 0, depth - 1 do
		local slot = self:Held(back)
		-- Once round the ring, the oldest held slot is the one the caller has
		-- just filled. It is the entry that left rather than one to fold into,
		-- and only a cap shorter than the lookback walks that far.
		if slot == fresh then
			break
		end
		if match(slot, fresh) then
			self.stale = true
			return slot
		end
	end
	return nil
end

-- A break in the timeline rather than a thing that happened.
--
--   kind      what this marker is. Nothing here reads it; it is carried so the
--             tooltip can say which of the two it is looking at.
--   label     the word on the band
--   trailing  the right hand side, which at the end of a fight is how long it
--             lasted and at the start of one is nothing
--   band      the band's colour, and the whole of how a marker is told apart
--             from an entry at a glance
--
-- Loose arguments rather than a table, for the reason Feed:Entry is two calls:
-- a marker arrives on the same event path a pull does.
function Feed:Mark(kind, label, trailing, band)
	local slot = self:Entry()
	slot.mark = kind or true
	slot.name = label or ""
	slot.amount = trailing or ""
	slot.stripe = band or C.chrome
	return self:Push()
end

function Feed:Clear()
	self.written, self.held, self.offset = 0, 0, 0
	self:Paint()
	return true
end

-- Every entry `match` says yes to out of the feed, and the gaps they leave
-- closed. Answers how many went.
--
-- One walk from the newest back sorts the ring into what stays and what goes,
-- and both are written back in the order they were: what stays at the old end,
-- and what went after it, where Feed:Entry wipes and hands those tables out
-- again. So a sweep allocates two lists for a click and nothing for a drop, and
-- the ring keeps the order it was written in. `written` steps back by what
-- went, which keeps Feed:Held's arithmetic true, and `held` is the count.
--
-- The offset steps back by what went from above the view, for the reason
-- Feed:Push moves it: taking out a row you have scrolled past would otherwise
-- move the one you are reading.
function Feed:Sweep(match)
	local count = self:Count()
	local kept, gone, above = {}, {}, 0
	for back = 0, count - 1 do
		local slot = self:Held(back)
		if match(slot) then
			gone[#gone + 1] = slot
			if back < self.offset then
				above = above + 1
			end
		else
			kept[#kept + 1] = slot
		end
	end
	if #gone == 0 then
		return 0
	end
	-- What the caller does with an entry that went, while its table still says
	-- what it was. The next Feed:Entry wipes it.
	if self.onRemove then
		for index = 1, #gone do
			self.onRemove(gone[index])
		end
	end

	local ring, cap = self.ring, self.cap
	local base = self.written - count
	for index = 1, #kept do
		ring[((base + #kept - index) % cap) + 1] = kept[index]
	end
	for index = 1, #gone do
		ring[((base + #kept + index - 1) % cap) + 1] = gone[index]
	end
	self.written, self.held = base + #kept, #kept
	self.offset = math.max(0, math.min(self.offset - above, self:Room()))
	self:Paint()
	return #gone
end

-- One entry out, which is the cross on a row. By identity, so it is the entry
-- the row was drawing rather than another one saying the same thing.
function Feed:Remove(entry)
	return self:Sweep(function(slot)
		return slot == entry
	end) > 0
end

--------------------------------------------------------------------------
-- Where you are in it
--------------------------------------------------------------------------

-- How many entries are off the bottom of the view, which is how far the offset
-- is allowed to go.
function Feed:Room()
	return math.max(0, self:Count() - self.visible)
end

function Feed:Live()
	return self.offset <= 0
end

function Feed:Offset()
	return self.offset
end

-- One drawn row, for scripts/harness.lua and for a macro.
--
-- Handed out for the reason Meter/Window.lua hands out a pane: the harness has
-- to measure what was actually drawn, and the alternative is this file
-- publishing its whole pool or the harness asserting against the entry list,
-- which would be asserting that the data is right rather than that it reached
-- the screen. Those are different claims and the second one is the one a
-- screenshot would show.
function Feed:Row(index)
	return self.rows[index]
end

function Feed:ScrollTo(value)
	local room = self:Room()
	local want = math.max(0, math.min(math.floor((value or 0) + 0.5), room))
	if want == self.offset then
		return false
	end
	self.offset = want
	self:Paint()
	return true
end

function Feed:Scroll(rows)
	return self:ScrollTo(self.offset + rows)
end

function Feed:ToTop()
	return self:ScrollTo(0)
end

--------------------------------------------------------------------------
-- Size, and whether it answers the mouse
--------------------------------------------------------------------------

-- On a feed with a bar the bar column is reserved whether or not the bar is
-- showing, which is the rule UI/Scroll.lua and UI/Log.lua both state: handing
-- the width back when the content fits would rewrap the rows, which can make
-- them not fit, which brings the bar back. A layout that can argue with itself
-- is a layout that flickers. A feed built without one has no column to reserve
-- and the rows run to the frame's edge.

-- Whether the middle column is drawn on this row, which is a question about the
-- string as well as about the width.
--
-- A note is drawn whole or it is not drawn. The column is a width and the note
-- is a measurement, and nothing here compared the two until this: a stream asks
-- for the room it believes its widest string wants, Resize hands back half of
-- what is left after the number at most, and a font string given less than its
-- string needs drops the end of it without saying so. Feeds/Combat.lua asks for
-- 96 units and "from Plains Creeper" measures 131 in the shipped face at a
-- row's text size, so that column has clipped at every width that feed has ever
-- been drawn at.
--
-- Measured rather than declared, and that is why the rule is here rather than a
-- shorter string in the two streams. `geom.note` is clamped to half the free
-- width in Resize, so the same string fits at one feed width and clips at the
-- next one down, and a number a stream wrote once cannot answer a question the
-- player moves.
--
-- What it does not do is give the room back to the name. The columns line up
-- down the feed, and a name that grew on the rows whose note went missing is a
-- feed with a ragged number column on it.
--
-- Asked on the three moves that can change the answer rather than on every
-- paint: the resize, a new note written to the row and the swap back out of a
-- marker. A row repainting the note it already has pays nothing.
local function Noted(row)
	if row.noted and not row.shownMark
		and (row.note:GetStringWidth() or 0) <= row.notemax then
		row.note:Show()
	else
		row.note:Hide()
	end
end

-- One row given the geometry the resize worked out, which is every number about
-- a row that is not the entry on it.
--
-- Its own function because the resize now decides five things rather than
-- three: the icon is a setting, the row height follows the icon, and the name
-- starts after both. Twenty four rows of that inside the arithmetic that
-- produced it is a function nobody reads to the end.
local function ShapeRow(feed, row, index, geom)
	local unit = feed.unit

	row:SetSize(geom.content * unit, feed.row * unit)
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", feed.frame, "TOPLEFT", 0,
		-(feed.head + (index - 1) * (feed.row + ROW_GAP)) * unit)

	row.icon:SetSize(feed.icon * unit, feed.icon * unit)
	ns.EdgeSize(row.mark.edges, ns.Pixel(row.mark))

	-- The wash stops where the last text column does rather than at the row's
	-- own right edge. The three units between the two are the inset the number
	-- is held off the edge by, and a wash that took them would be solid at the
	-- stripe and still painting past everything there is to read, which is a
	-- panel with one soft edge.
	--
	-- Sized rather than pinned to both corners, because the row's own height is
	-- a setting and a texture given two anchors is one whose height nothing in
	-- this file ever wrote down.
	row.wash:SetSize(geom.wash * unit, feed.row * unit)
	if row.floor then
		UI.FloorBand(row.wash, row.floor,
			feed.head + (index - 1) * (feed.row + ROW_GAP), geom.wash, feed.row)
	end

	row.name:ClearAllPoints()
	row.name:SetPoint("LEFT", row, "LEFT",
		(STRIPE + INSET + feed.icon + GUTTER) * unit, 0)
	row.name:SetWidth(geom.name * unit)
	row.amount:SetWidth(AMOUNT * unit)
	row.caption:SetWidth(geom.caption * unit)

	row.noted = geom.note > 0
	row.notemax = geom.note * unit
	if row.noted then
		row.note:SetWidth(row.notemax)
	end
	-- Written from here rather than left to the repaint, because whether
	-- there is a middle column at all is decided by the width and a row that
	-- is not repainting is a row that would keep the last answer. The width it
	-- is decided against is kept on the row, because the other two callers of
	-- Noted run nowhere near the geometry that produced it.
	Noted(row)

	-- What the stripe is on an entry and what it becomes on a marker, held
	-- on the row so the repaint can swap between them without knowing the
	-- feed's width.
	row.rib = STRIPE * unit
	row.band = geom.content * unit
end

-- Everything a setting can move about a column: how wide it is, how many rows
-- it draws and how large the picture on each of them is.
--
-- The icon is the third argument rather than a fourth call, because the row
-- height, the name's left edge and the frame's own height all follow from it
-- and a feed that learned about a new icon size in a separate pass would be a
-- feed with two of the three written and one still on the old number.
function Feed:Resize(width, rows, icon)
	local unit = self.unit
	rows = math.max(1, math.min(rows or 1, MAX_ROWS))
	icon = math.max(UI.FEED_ICON_LOW, math.min(icon or ICON, UI.FEED_ICON_HIGH))

	self.width = width
	self.visible = rows
	self.icon = icon
	self.row = icon + ROW_PAD

	local height = self.head + rows * (self.row + ROW_GAP) - ROW_GAP
	self.frame:SetSize(width * unit, height * unit)

	local content = math.max(width - (self.bar and (M.bar + M.gutter) or 0), 1)
	if self.rule then
		self.rule:SetWidth(width * unit)
	end

	-- The three text columns, decided here and written to every row, so the
	-- names line up down the feed and so do the numbers. The number column is
	-- fixed and the other two share what is left; the middle one never takes
	-- more than half of that, because a feed narrowed to its minimum has to
	-- leave the name enough room to still be a name.
	local free = content - (STRIPE + INSET + icon + GUTTER) - INSET - AMOUNT - PAD
	local note = 0
	if self.note > 0 then
		note = math.max(0, math.min(self.note, math.floor((free - PAD) / 2)))
	end

	-- One table, kept and written over. A resize is not on a ticker, but it is
	-- on the rescale path and on every stepper click, and a table per click is
	-- garbage for nothing when the fields are the same five every time.
	local geom = self.geom
	geom.content = content
	geom.note = note
	geom.name = math.max(free - (note > 0 and note + PAD or 0), 1)
	geom.caption = math.max(content - STRIPE - INSET * 2 - AMOUNT - PAD, 1)
	-- Where the text ends, which is the right edge of the number column and one
	-- inset short of the row. Worked out here with the other four rather than in
	-- ShapeRow, because it is the sum of everything above it and a second file
	-- adding those numbers up again is the one that goes stale when a column
	-- moves.
	geom.wash = math.max(content - INSET, 1)

	-- The rows this feed is set to draw, built here the first time it is set to
	-- draw that many. Twenty four were built at login whatever the setting said,
	-- and the setting ships at ten. A row that has been built is kept, because a
	-- frame cannot be destroyed on this client and a pool that shrank would build
	-- a new one every time the stepper went back up.
	for index = #self.rows + 1, rows do
		self.rows[index] = BuildRow(self, index)
	end
	for index = 1, #self.rows do
		local row = self.rows[index]
		ShapeRow(self, row, index, geom)
		if index > rows then
			row.shownEntry = nil
			row:Hide()
		end
	end

	-- The offset can be past the end after a shrink, which is a feed that draws
	-- a screen of nothing at the bottom of its own history.
	if self.offset > self:Room() then
		self.offset = self:Room()
	end

	self:MouseRows()
	self:Paint()
	return width * unit, height * unit
end

-- How strongly the ground under each row is painted.
--
-- This is the background slider, and it paints a gradient under the text rather
-- than a panel behind the column. The two are the same request and only one of
-- them is a picture: a panel at any strength covers whatever the player is
-- standing on all the way across the feed, and a wash covers the letters and
-- lets go by the end of them.
--
-- The alpha of the texture rather than the alpha of the colour, because the
-- ramp is built once when the row is and rebuilding it per drag is a gradient
-- made twenty four times for a number the client will multiply for nothing.
-- What that costs is that full strength is ns.UI.Color.shadow's own alpha and
-- not black: a wash is a shadow and a slider that reached opaque would be the
-- panel again at the top of its range.
--
-- Rows built after this take it in BuildRow, which is why the number is held on
-- the feed. A stepper that makes four more rows would otherwise leave them at
-- full strength under a column the player had turned down.
function Feed:Wash(strength)
	strength = math.max(0, math.min(strength or 1, 1))
	if self.washAt == strength then
		return false
	end
	self.washAt = strength
	for index = 1, #self.rows do
		self.rows[index].wash:SetAlpha(strength)
	end
	return true
end

-- Whether the rows take the mouse at all.
--
-- A setting rather than always on, and the note in Meter/Window.lua is the
-- reason: a mouse enabled frame swallows every button that lands on it, and a
-- feed is a tall rectangle sitting where a right button drag to turn the camera
-- starts. ns.UI.PassCamera hands those two buttons back where the client will
-- take them, and where it will not this is the switch that gets the camera
-- back at the price of the tooltips.
-- Which rows take the mouse: the ones being drawn, and only while the setting
-- is on. Its own function because two things move it and each would otherwise
-- leave the other stale. Turning the setting off has to reach every row, and
-- so does growing the feed from eight rows to twelve, and a Mouse that returned
-- early because the setting had not changed would leave the four new rows
-- inert. That is a bug you find by hovering the bottom of a feed you have just
-- made taller, which is to say not for weeks.
function Feed:MouseRows()
	for index = 1, #self.rows do
		self.rows[index]:EnableMouse(self.mouse and index <= self.visible or false)
	end
	-- And the strip's control goes with them. The setting says this feed is a
	-- picture, and a picture with a clickable square on it is a feed that still
	-- takes the button somebody turned the setting off to get back.
	if self.list then
		self.list:EnableMouse(self.mouse and true or false)
	end
end

function Feed:Mouse(on)
	on = on and true or false
	if self.mouse == on then
		return false
	end
	self.mouse = on
	self:MouseRows()

	if type(self.frame.EnableMouseWheel) == "function" then
		self.frame:EnableMouseWheel(on)
		if on then
			self.frame:SetScript("OnMouseWheel", function(_, delta)
				-- Down the wheel is down the list, which is backwards in time.
				-- Shift is the whole way, the same shortcut UI/Log.lua keeps
				-- from the client's own chat.
				if IsShiftKeyDown and IsShiftKeyDown() then
					self:ScrollTo(delta > 0 and 0 or self:Room())
					return
				end
				self:Scroll(-delta * WHEEL_ROWS)
			end)
		else
			self.frame:SetScript("OnMouseWheel", nil)
		end
	end

	if not on then
		self:Leave()
	end
	return true
end

-- How strongly one row paints the grade of what is on it.
--
-- Two things decide it and they change at different times, which is why this is
-- a function and not a line in the repaint: the colour is the entry's and moves
-- when a drop lands, the strength is the cursor's and moves when the mouse
-- does. Character/Paperdoll.lua splits the sheet's quality band the same way,
-- and rests it at the same M.rest, because a quality is one picture whichever
-- window you meet it in.
--
-- What rests is what says a grade. Two things on a row say something else and
-- both stay at full: a marker's band, which is a break in the timeline rather
-- than a thing that happened, and a ring the entry has claimed with `look`.
-- `look` is the entry's word rather than this file's test for a quest, so a
-- feed can put a ring on a row for any reason it likes and still say the ring
-- is the reason to read the row.
--
-- Nothing sets a strength when a row is built. A row is hidden until it has an
-- entry, and taking one puts its mark somewhere it was not, so Marked reaches
-- here before the row is ever on screen.
--
-- Both writes are guarded like every other write in this file, and the reopen
-- in Paint is why rather than the arrival: it re-enters the row under the
-- cursor five times a second for as long as a fight lasts, and every one of
-- those is the same alpha the row already has.
local function Tone(row)
	local stripe = (row.lit or row.shownMark) and 1 or M.rest
	if row.shownStripeAt ~= stripe then
		row.shownStripeAt = stripe
		row.stripe:SetAlpha(stripe)
	end

	local ring = (row.lit or row.shownLook) and 1 or M.rest
	if row.shownRingAt ~= ring then
		row.shownRingAt = ring
		row.mark:SetAlpha(ring)
	end
end

--------------------------------------------------------------------------
-- The mouse
--------------------------------------------------------------------------

-- cold: filling a box is a hover, and the one caller that is not is the reopen
-- in Paint, which is behind a fifth of a second
function Feed:Enter(index)
	local row = self.rows[index]
	if not row then
		return false
	end
	self.hovered = index
	row.glow:Show()
	-- And the row's own colour to full, which is the other half of the answer
	-- the glow gives. The column rests its stripes so thirteen qualities read as
	-- a ribbon rather than as thirteen lights; the row you are pointing at is
	-- the one you have asked to read.
	row.lit = true
	Tone(row)
	-- When the box was last filled, which is what the reopen in Paint throttles
	-- against. Stamped here rather than there so one place owns it: a hover is a
	-- fill, and a reopen a frame after one is the case the throttle is for.
	self.reopenedAt = GetTime()

	local entry = row.shownEntry
	-- The buttons come up on the row being read, and never on a marker, which is
	-- a break in the timeline rather than a thing that happened to take out. The
	-- can asks the list too, because coin has no item to put on it.
	local item = entry ~= nil and not entry.mark
	if row.cross then
		row.cross:SetShown(item)
	end
	if row.trash then
		row.trash:SetShown(item and self.watch.can(entry) and true or false)
	end
	-- What the row was showing when this tooltip was filled, so Paint can tell a
	-- repaint that moved the entry under the cursor from one that did not. Both
	-- halves: the ring hands the same table back a full lap later, and the push
	-- time is the only thing that tells that apart from nothing having changed.
	self.hoveredEntry = entry
	self.hoveredAt = entry and entry.at

	if not entry or not self.onTooltip then
		-- A row with nothing on it takes the box down at once rather than
		-- letting the last row's box linger over it. Entering a thing always
		-- replaces what is on screen, and a blank row replaces it with nothing.
		ns.Tip.Close(true)
		return false
	end
	return ns.Tip.Open(row, self.onTooltip(entry), "row")
end

function Feed:Leave()
	if self.hovered then
		local row = self.rows[self.hovered]
		if row then
			row.glow:Hide()
			if row.cross then
				row.cross:Hide()
			end
			if row.trash then
				row.trash:Hide()
			end
			row.lit = nil
			Tone(row)
		end
		self.hovered = nil
	end
	self.hoveredEntry, self.hoveredAt = nil, nil
	ns.Tip.Close()
	return true
end

--------------------------------------------------------------------------
-- Painting
--
-- Every write is guarded on what the row already carries. This is not a ticker,
-- so the guards are not buying frames off a hot path; they are buying the case
-- a feed is actually in most of the time, which is one entry arriving at the
-- top of a column that is otherwise exactly what it already was. Without them
-- every drop would rewrite ten icons, twenty strings and ten colours to move
-- one row down by one.
--------------------------------------------------------------------------

local function Blank(row)
	if row.shownEntry ~= nil then
		row.shownEntry = nil
		row:Hide()
	end
end

-- A row turned from a thing that happened into a break in the timeline, or
-- back.
--
-- A marker drops everything a row uses to say what happened and its stripe
-- becomes the whole row. That is a shape an entry cannot take, and it has to
-- be, because the one thing worse than not marking where a fight started is a
-- mark that reads as a hit for nothing.
--
-- The fields the swap invalidates are cleared with it. Without that a marker
-- whose word matched the name already on the row would keep the row's own
-- string: a guard holding on a value that is right and a widget that is not.
--
-- Its own function because PaintRow reached thirty four branches and the gate
-- is thirty. This is the half of it that runs about twice a fight; everything
-- left in PaintRow runs on every arrival.
local function Marked(row, mark)
	if row.shownMark == mark then
		return false
	end

	row.shownMark = mark
	row.shownName, row.shownColor, row.shownIcon, row.shownNote = nil, nil, nil, nil
	row.stripe:SetWidth(mark and row.band or row.rib) -- unguarded: the return above compares the mark against what is drawn
	Tone(row)
	if mark then
		row.icon:Hide()
		row.name:Hide()
		row.note:Hide()
		row.caption:Show()
	else
		row.icon:Show()
		row.name:Show()
		row.caption:Hide()
		Noted(row)
	end
	return true
end

-- The ring round the icon, and how strongly it is painted.
--
-- On the loot feed the ring means a reagent and on any other feed it means
-- whatever the capture file decided to say with it. A marker has no icon, so it
-- can never have one round it.
--
-- Whether it rests with the stripe is the entry's `look` and not a test for a
-- quest in here. An entry that claims its ring is saying the ring is why the
-- row is worth reading, and that is a thing a feed is allowed to mean for a
-- reason other than a quest.
--
-- Its own function for the reason Marked is one. This is four branches of
-- PaintRow's thirty and it changes about once a pickup, while everything left
-- in PaintRow runs on every arrival.
local function Ringed(row, mark, entry)
	local ring = (not mark) and entry.ring or nil
	local look = ring and entry.look or nil
	if row.shownRing == ring and row.shownLook == look then
		return false
	end

	row.shownRing, row.shownLook = ring, look
	if ring then
		ns.Recolor(row.mark.edges, ring)
		row.mark:Show()
	else
		row.mark:Hide()
	end
	Tone(row)
	return true
end

-- The picture over the icon, off the entry's `badge`. A marker has no icon, so
-- it has none, the same as the ring. Its own function for the reason Ringed is.
local function Badged(row, mark, entry)
	local badge = (not mark) and entry.badge or nil
	if row.shownBadge == badge then
		return false
	end

	row.shownBadge = badge
	if badge then
		row.badge:SetTexture(badge)
		row.badge:Show()
	else
		row.badge:Hide()
	end
	return true
end

local function PaintRow(row, entry, faded)
	if row.shownEntry ~= entry or not row:IsShown() then
		row.shownEntry = entry
		row:Show()
	end

	local mark = entry.mark or false
	Marked(row, mark)

	local label = mark and row.caption or row.name

	if not mark and row.shownIcon ~= entry.icon then
		row.shownIcon = entry.icon
		row.icon:SetTexture(entry.icon)
	end

	Ringed(row, mark, entry)
	Badged(row, mark, entry)

	if row.shownName ~= entry.name then
		row.shownName = entry.name
		label:SetText(entry.name or "")
	end

	if not mark and row.shownNote ~= entry.note then
		row.shownNote = entry.note
		row.note:SetText(entry.note or "")
		-- Measured on the write, which is the only place a repaint can change
		-- what the column is being asked to hold.
		Noted(row)
	end

	if row.shownAmount ~= entry.amount then
		row.shownAmount = entry.amount
		row.amount:SetText(entry.amount or "")
	end

	local color = entry.color or C.text
	if row.shownColor ~= color then
		row.shownColor = color
		label:SetTextColor(color[1], color[2], color[3])
	end

	local tone = entry.tone or C.text
	if row.shownTone ~= tone then
		row.shownTone = tone
		row.amount:SetTextColor(tone[1], tone[2], tone[3])
	end

	local stripe = entry.stripe or color
	if row.shownStripe ~= stripe then
		row.shownStripe = stripe
		row.stripe:SetColorTexture(stripe[1], stripe[2], stripe[3], stripe[4] or 1)
	end

	local alpha = faded and FADE or 1
	if row.shownAlpha ~= alpha then
		row.shownAlpha = alpha
		row:SetAlpha(alpha)
	end
end

-- Whether anybody can see this, and the whole reason a hidden feed is cheap.
--
-- Everything above the repaint still runs while it is asleep: an arrival wipes
-- a ring slot, fills it and pushes it, and that is a handful of table writes.
-- What does not run is Feed:Paint, and Paint is the expensive half by an order
-- of magnitude. It writes five regions on every one of up to twenty four rows
-- on every arrival, and in a pull arrivals come faster than frames do. A column
-- nobody is looking at, redrawing itself two hundred times a second, is the
-- clearest case of work nobody asked for in the addon.
--
-- The skipped redraw is not lost. Anything that would have painted while asleep
-- leaves the feed stale, and waking it paints once, so what comes back is the
-- list as it is now rather than as it was when it went away.
function Feed:Awake(on)
	on = on and true or false
	if self.awake == on then
		return false
	end
	self.awake = on
	if on and self.stale then
		self:Paint()
	end
	return true
end

function Feed:Paint()
	if not self.awake then
		self.stale = true
		return false
	end
	self.stale = false

	local count = self:Count()
	local room = self:Room()

	-- Show and Hide rather than SetShown. Every frame on both clients answers
	-- SetShown and this is a font string, which is a region rather than a frame,
	-- and nothing installed here proves a region takes it on 2.5.6. The two
	-- calls are the same write and cannot be refused.
	local blank = count == 0 and (self.empty or "") ~= ""
	if self.blank and self.shownBlank ~= blank then
		self.shownBlank = blank
		if blank then
			self.blank:Show()
		else
			self.blank:Hide()
		end
	end

	for index = 1, self.visible do
		local entry = self:Held(self.offset + index - 1)
		if entry then
			-- The last row fades only while there is something under it to fade
			-- into. At the bottom of the history there is nothing below and a
			-- dimmed final row would be saying so falsely.
			PaintRow(self.rows[index], entry,
				index == self.visible and self.offset < room)
		else
			Blank(self.rows[index])
		end
	end
	for index = self.visible + 1, #self.rows do
		Blank(self.rows[index])
	end

	-- The count, which is what the feed holds, unless the owner has the end.
	if self.tally and not self.aside then
		local held = count > 0 and tostring(count) or ""
		if self.shownTally ~= held then
			self.shownTally = held
			self.tally:SetText(held)
		end
	end

	-- The row under the cursor may have been repainted with a different entry on
	-- it, and then the tooltip beside it is about something that has moved on.
	-- It is reopened rather than closed, because a tooltip vanishing when a mob
	-- dies somewhere else is worse than one that follows the row it is on.
	--
	-- Guarded, and this guard buys more than the usual one. Filling a tooltip
	-- builds a table and a string or two, which a hover can afford; reopening it
	-- unconditionally made that one fill per combat log event for as long as the
	-- cursor rested anywhere on the feed. The row under the cursor mostly does
	-- not move: the mouse is on row seven and the arrival lands on row one.
	--
	-- And throttled under the guard, because the one place the guard does not
	-- hold is the case a live feed spends its time in: the cursor parked on row
	-- one, where every arrival moves the entry under it. Refused, the feed is
	-- left marked so the next frame looks again, which is what keeps the box
	-- from settling on the row before last after the pull stops.
	if self.hovered and self.hovered <= self.visible then
		local row = self.rows[self.hovered]
		if row.shownEntry ~= self.hoveredEntry
			or (row.shownEntry and row.shownEntry.at ~= self.hoveredAt) then
			if GetTime() - (self.reopenedAt or 0) >= REOPEN then
				self:Enter(self.hovered)
			else
				self.stale = true
			end
		end
	end

	self:Sync()
	return true
end

-- Puts the bar back in step with the offset. Called after anything that could
-- move either, which is an arrival, a scroll and a resize.
--
-- Every write here is compared first, the same as every write on a row. It was
-- four unconditional writes on a widget nobody had touched, and in a pull that
-- is a thumb resized, a range rewritten and a value pushed back for every line
-- in the zone. The steady state of a feed at the top of its own history is a
-- bar whose range grows by one and whose thumb and value do not move at all.
--
-- The range, the thumb size and whether the bar is up are compared against what
-- this file last wrote, because nothing else writes them. The value is compared
-- against the widget, because a drag writes that one from the other end and a
-- clamped drag leaves the thumb somewhere this file never put it.
function Feed:Sync()
	local bar = self.bar
	if not bar then
		return false
	end

	local room = self:Room()
	if room <= 0 then
		if self.barShown ~= false then
			self.barShown = false
			bar:Hide()
		end
		return false
	end

	local height = self.visible * (self.row + ROW_GAP) - ROW_GAP
	local size = math.max(M.thumb,
		UI.Round(self.frame, height * self.unit * self.visible / math.max(self:Count(), 1)))
	if self.thumbAt ~= size then
		self.thumbAt = size
		bar.thumb:SetSize(M.bar, size)
	end

	self.syncing = true
	if self.roomAt ~= room then
		self.roomAt = room
		bar:SetMinMaxValues(0, room)
	end
	if bar:GetValue() ~= self.offset then
		bar:SetValue(self.offset)
	end
	self.syncing = nil

	if self.barShown ~= true then
		self.barShown = true
		bar:Show()
	end
	return true
end

--------------------------------------------------------------------------

-- One line for a status command or a panel note. What is worth saying is where
-- you are in it, because a feed that looks stuck is nearly always a feed you
-- scrolled down an hour ago and left there.
function Feed:Describe()
	local count = self:Count()
	if count == 0 then
		return "empty"
	end

	local line = ("%d held"):format(count)
	if not self:Live() then
		line = line .. (", scrolled back %d"):format(self.offset)
	end
	return line
end
