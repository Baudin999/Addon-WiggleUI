local ADDON, ns = ...

local Column = {}
ns.QuestColumn = Column

local UI = ns.UI
local C = ns.UI.Color
local M = ns.UI.Metric
local Log = ns.QuestLog
local Party = ns.QuestParty

--------------------------------------------------------------------------
-- The addon's own quest tracker
--
-- A column over the world: the name of every quest you are standing in the
-- middle of, what each one still wants under it, and a gold bar down the left
-- of the ones you have pinned. It is placeable, it is the third thing this
-- addon draws over the world after the loot feed and the experience rails, and
-- the ground under it was settled by those two: UI/Placeable.lua owns the drag,
-- UI/Stack.lua owns the rows and UI.Wash is what makes text legible over grass
-- without a panel round it.
--
-- Not to be confused with Quests/Tracker.lua, which is next door and is about
-- somebody else's tracker: that file points Questie's clicks at this addon's
-- window. This file is the tracker.
--
-- **The quests on it come from ns.QuestLog's zones and nothing else.**
-- Quests/Log.lua turns the client's flat run of rows into zones holding quests
-- and caches the answer, and until now the quest window's left column was its
-- only reader. Log.Zones() is the one door this file goes through. A tracker
-- that read the client's log itself would be the sheet and the loot feed
-- again: two pictures of one thing, drifting apart in the details nobody looks
-- at until they are side by side. One reading, two drawings.
--
-- **It scopes on the client's log header, and the pin is the one exception.**
-- A pinned quest is on this column wherever you are standing, which is the
-- thing pinning is for: the rule takes everything off the tracker when you walk
-- out of the zone, and the pin is how a player asks for one quest back. It is
-- read through Log.Pins() and never off the saved table.
--
-- **The scope is two joins, and the name is the cheap one.** zone.name is the
-- string the client filed the quest under and ns.QuestHere.Now().name is
-- C_Map's name for the map you are standing on; both come out of the same
-- client in the same language, which is what makes comparing them safe, and
-- they are equal in most of the game. They are not equal in the one zone every
-- character starts in. The client files the first quests of every race under a
-- subzone, Northshire Valley or Coldridge Valley or Deathknell, and vanilla
-- draws no map of any of them, so C_Map answers Elwynn Forest and a tracker
-- that only compared names was blank for the first two levels of every
-- character. So a zone also lands on the column when its own area folds up to
-- the area you are standing in, which is ns.QuestWhere.Sort against
-- ns.QuestHere.Now().area, and both of those are numbers. Core/Here.lua's
-- header says why every join in that file is one.
--
-- The header is a sort category rather than a place: a dungeon quest is filed
-- under the dungeon and a class quest under the class, and neither says where
-- the thing you still have to do is standing. Item 93 is that argument and it
-- is a different item. Nothing here asks Where.Nearest, which walks hundreds of
-- coordinate transforms per quest and has exactly one caller.
--
-- **Nothing is on a ticker.** The log changes on events and this redraws on
-- them. Questie's own quest updates are not wanted here either, and that is
-- worth saying because Quests/Window.lua hangs a second redraw off them: what
-- that callback buys that file is the order its right column is drawn in, since
-- two of its three lines are Questie's answers and the client's event arrives
-- before Questie has finished thinking. Every quest name and every objective on
-- this column is the client's own, so the client's own events are already the
-- right grain, and a second source registered for a redraw that would say the
-- same thing is one more thing to keep in step. The foot line is Questie's and
-- it does not change that: it holds itself still for twenty seconds at a time,
-- so a redraw hung off Questie would repaint the same sentence.
--
-- **It follows ns.QuestTrackerOff.Wanted().** One switch, one tracker: the box
-- that takes Questie's tracker off the screen is the box that puts this one up,
-- so there is never a moment where both are drawn and no rule about which one a
-- quest name belongs to. It is not questsHideBlizz, which is about the client's
-- own window and the L key.
--
-- **And a tab per zone down its left edge.** The scope above is the right
-- default and it was the whole of the feature for too long: a log with quests
-- in six zones was a tracker you could read one sixth of, and the only way to
-- see the rest was to walk there. The pin is what that left players doing and
-- it is the wrong shape for the question. A pin is for the one quest you always
-- want in front of you; looking at Westfall for a moment is not that.
--
-- So every zone your log has quests in is on the tracker, with how many quests
-- you still have there beside its name and a gold dot where one of them is
-- ready to hand in, and pressing one draws that zone.
--
-- **They are drawn as a harmonica, and the turned strip is the other setting.**
-- A harmonica is a plate per zone stacked down the column, each with its name
-- written the way round every other word here is, and the open one's quests
-- under it. A closed plate costs one line. The turned strip is what this was:
-- one tab per zone down the left edge, each label rotated a quarter turn so the
-- whole strip costs fifteen pixels of width and no height at all.
--
-- The harmonica ships. The turn is the cheaper control and it is the one you
-- have to tilt your head to read, on the frame in this addon that is looked at
-- most often; a plate says its zone's name in the same direction as the quest
-- names under it, so the tracker is one thing being read rather than two. What
-- the turn buys is width, which is why it is still here: a player who has put
-- this column down the edge of a tall screen is spending something a player
-- with it in a corner over the world is not.
--
-- A harmonica is not a strip and is not drawn by one. The plates are rows in
-- the same stack the quest names are in, because that is what makes the open
-- zone's quests sit under its own plate and the next plate sit under them. The
-- turned strip stands beside that stack and UI.SideTabs draws it; in a
-- harmonica it holds no tabs and is not on the screen.
--
-- **Walking and clicking are two gestures and the second outranks the first.**
-- Where you are standing is what the column draws until you press a tab, and
-- then that zone until you walk into another one that has quests. Walking means
-- "I am here now" and a click means "show me there", and a click that a
-- subzone boundary undid would be a control you cannot use while moving. That
-- is why the choice is dropped against the scoped zone changing rather than
-- against ZONE_CHANGED, which fires every time you cross a road.
--
-- Walking somewhere with no quests in it drops nothing. Standing in Ironforge
-- reading Westfall is exactly what the plates are for.
--
-- **So it stops hiding itself.** The old rule was that a tracker with no quests
-- on it is not drawn, which was right while the tracker was only ever the zone
-- under your feet: a rectangle of shade saying you are not on a quest here is a
-- thing you already know. It is wrong the moment there are tabs on it, because
-- standing in a city would take away the control you use to look at anywhere
-- else. It is up whenever your log has a quest in it, and down when the log is
-- empty.
--------------------------------------------------------------------------

-- The column's width, in design units. Wide enough for a quest name at twelve
-- and no wider: this stands over the middle of somebody's game all evening, and
-- every pixel of it is a pixel of the world they do not get.
local WIDTH = 220

-- A quest's name, and one row under it per thing the quest still wants.
-- Furniture sizes, the chat window's argument: a window you open, read and shut
-- is aimed at once, and this is read at a glance a hundred times a night.
local TITLE = 16
local LINE = 14
local TITLE_TEXT = 12
local LINE_TEXT = 11

-- The mark on a pinned quest: a bar down the left edge of its name, in the
-- addon's heading gold. Two pixels, which is the width UI.List draws the
-- selected row's mark at, so the two read as one interface.
--
-- A bar rather than a glyph, and that is not a compromise. Media/Glyphs.ttf is
-- a subset of seventeen marks and none of them is a pin, so a glyph here would
-- mean rebaking the font and moving the list scripts/check.sh holds it to. A
-- gold edge says "yours" at a glance over grass, which is the whole job.
local PIN = 2

-- The air to the left of every row's text: the pin's own two pixels with a gap
-- either side, so an unpinned name starts where a pinned one does and the
-- column has one left edge rather than two.
local LEAD = M.rowGap + PIN + M.rowGap

-- The column a quest's tick stands in, left of its name. The quest window's own
-- width for the same mark, and reserved on every quest finished or not, so the
-- names keep one left edge the way the window's levels do.
local MARK = 10

-- The line over the quests saying how full your log is, and the air under it.
--
-- Chrome rather than a row, which is why it is anchored above the stack instead
-- of added to it. Every cell in that stack is a quest or a thing a quest still
-- wants, and a line that is neither would be a row a click has to be taught to
-- ignore and a row every count of the column has to subtract.
local TALLY = 13
local TALLY_TEXT = 11

-- A zone's own label size, and the air between the turned strip and the words
-- beside it. Eleven rather than the twelve a quest name is drawn at, because a
-- zone is furniture either way it is drawn: it says where you are looking and
-- the quest names are what you are reading.
local ZONE_TEXT = 11
local ZONE_GAP = M.rowGap

-- One plate of the harmonica, which is a row in the stack with the same air
-- round its label that a quest name has round its own.
local ZONE = 16

-- The mark in a plate's corner saying a quest is ready to hand in somewhere you
-- are not looking. Three pixels, which is what the turned strip's tabs carry.
local DOT = 3

-- The longest and the shortest one zone tab is allowed to be, down the strip.
--
-- A tab is as long as its own label and a zone is called Eastern Plaguelands,
-- so ten of them is a strip taller than the monitor. The longest is what a tab
-- gets when there is room for it: 130 units holds about twenty characters at
-- eleven, which is every zone name in either of these games. The shortest is
-- the floor a share of the screen may not go below, because a strip of tabs
-- with two letters on each is a strip you cannot read, and a player with quests
-- in fifteen zones is better served by a strip that runs long than by one that
-- says nothing.
local ZONE_LONGEST = 130
local ZONE_SHORTEST = 54

-- How much of the screen the strip may take, in this frame's own units.
--
-- Four fifths, which is the same kind of margin UI/Window.lua keeps off the
-- edge of a monitor and for the same reason: the tracker is anchored fifteen
-- pixels down from the top by default, and a strip that ran to the last pixel
-- of the panel would hang off the bottom of a windowed client.
local ZONE_SHARE = 0.8

local function Room()
	local zoom = ns.Zoom("questsZoom")
	local tall
	if UI.Supported() and zoom > 0 then
		tall = UI.ScreenHeight() / zoom
	else
		tall = UIParent:GetHeight() or 0
	end
	return math.max(math.floor(tall * ZONE_SHARE), ZONE_SHORTEST)
end

-- How the zones are drawn: a plate each down the column, or a tab each down a
-- turned strip beside it. Anything but the word for the strip is the harmonica,
-- so a saved file written before this setting existed comes up the way it ships
-- rather than the way it happened to be missing.
local function Harmonica()
	return ns.db.questsTabs ~= "turned"
end

--------------------------------------------------------------------------

local frame, stack, place, wash, tally, side, body
local heads, lines, plates = {}, {}, {}

-- What a strip with nothing on it is handed. One table rather than a fresh one
-- per paint: UI.SideTabs reads the list and never keeps it.
local NONE = {}
local built = false

-- The zone a tab was pressed on, or nothing for "wherever I am standing".
--
-- A zone's name rather than its index, for the reason Quests/Log.lua gives
-- about quest keys: an index into the log's zones is a position, and handing in
-- the last quest in Elwynn moves every zone under it by one.
local chosen = nil

-- The scoped zone the last paint found under your feet, so the paint after it
-- can tell walking somewhere new from the log changing under you.
--
-- Written on every paint, nil included, and that is what makes walking through
-- a city work. Going from Westfall to Stormwind records nothing underfoot and
-- keeps whatever tab you pressed, because a zone with no quests in it is not
-- somewhere you arrived to do anything. Coming back out into Westfall is then a
-- change from nothing to Westfall, which is arriving, and takes the choice back.
local stoodIn = nil

-- Whether Paint is the thing that moved the strip's selection.
--
-- Selecting a tab calls back, the callback repaints, and the repaint selects.
-- It is the same latch Quests/Window.lua keeps between its list and its paint,
-- and without it the first press on a zone would read the log twice.
local painting = false

--------------------------------------------------------------------------
-- The model
--------------------------------------------------------------------------

-- Where you are standing, as this client's own name for it.
--
-- ns.QuestHere memoises on the map id, so this is a table lookup on a paint
-- path and a fresh reading the first time after you walk into somewhere new.
local function Standing()
	local here = ns.QuestHere.Now()
	return here and here.name or nil
end

-- Whether a quest carries the player's own mark.
--
-- One line and it is a seam. Item 95 moves the pin off the client's five watch
-- slots onto a store of this addon's own, keyed on the quest id, and renames the
-- field; this is the only place the tracker reads it.
local function Pinned(quest)
	return quest.pinned and true or false
end

-- The area a zone's quests are filed under, or nothing.
--
-- Off the first quest, because a zone is one header and every quest under it
-- carries the same one. It is a question for Questie's database rather than for
-- the client, so ns.QuestWhere holds it and the answer is held there too: this
-- runs once a zone on every paint.
local function Under(zone)
	local first = zone.quests[1]
	return first and ns.QuestWhere.Sort(first.id) or nil
end

-- Which of the log's headers count as where you are standing, as a set of the
-- header strings themselves, or nothing on a client that will not say where you
-- are. Two joins: the client's own name for this map against the header, and
-- the header's area folded up against this map's area.
--
-- A set rather than a test, because the reading has to answer the same question
-- the scope does and it holds a header string per quest rather than a zone. Two
-- copies of a rule that says which quests are in front of you is how the column
-- and its own reading disagree, which is the shape a player reads as the number
-- being wrong.
local function Scope()
	local at = ns.QuestHere.Now()
	local name, area = at and at.name or nil, at and at.area or nil
	if not name and not area then
		return nil
	end
	local scope = {}
	for _, zone in ipairs(Log.Zones()) do
		if (name and zone.name == name) or (area and Under(zone) == area) then
			scope[zone.name] = true
		end
	end
	return scope
end

-- The first zone in the log that the scope names, or nothing.
--
-- One name out of a set, and it is only ever asked one question: has the ground
-- under your feet changed since the last paint. The set is what draws, because
-- a level 2 human is standing in two headers at once and both belong on the
-- column; one name out of it is enough to tell Westfall from Elwynn, which is
-- all the choice has to survive.
local function Underfoot(scope)
	if not scope then
		return nil
	end
	for _, zone in ipairs(Log.Zones()) do
		if scope[zone.name] then
			return zone.name
		end
	end
	return nil
end

-- Which zones the column is drawing, as a set of the log's own header strings.
--
-- The zone you pressed, or the scope under your feet. One door, so the rows,
-- the reading on the options page and the tab that lights up cannot disagree
-- about what the column is looking at.
function Column.Showing()
	if chosen then
		return { [chosen] = true }
	end
	return Scope()
end

-- Every zone your log has quests in, as the strip draws them: the header's own
-- name, how many quests are still under it, and whether one of those is ready
-- to hand in.
--
-- Off Log.Zones in the log's own order, which is the order the quest window's
-- left column draws them in, so the two windows list your zones the same way
-- round. A zone with nothing under it is one the client half handed over and is
-- not a tab.
function Column.Tabs()
	local out = {}
	for _, zone in ipairs(Log.Zones()) do
		if #zone.quests > 0 then
			out[#out + 1] = {
				key = zone.name,
				label = Column.Zoned(zone),
				dot = zone.done > 0,
			}
		end
	end
	return out
end

-- What a zone is called on the tracker: its own name and how many quests you
-- still have under it.
--
-- One function for both drawings. A plate and a tab are the same label on two
-- different shapes, and two format strings is how the harmonica and the strip
-- come to disagree about whether the number is there.
function Column.Zoned(zone)
	return ("%s %d"):format(zone.name, #zone.quests)
end

-- The zone a tab was pressed on, or nothing to go back to where you are
-- standing. Answers whether anything moved.
function Column.Choose(name)
	if painting or chosen == name then
		return false
	end
	chosen = name
	Column.Paint()
	return true
end

-- The quests on the tracker right now: the ones under whichever zone it is
-- showing, in the log's own order, and then whatever you have pinned that is
-- not already among them.
--
-- The pins are the exception to the scope and they are the whole of why the pin
-- exists. Everything else comes off the tracker when you walk out of the zone,
-- which is the rule; a pinned quest is the one you asked to keep in front of
-- you, so it is here in Silithus as well as in Westfall.
--
-- After the zone rather than before it. What is under your feet is what you can
-- act on now, and a group of five pins pushing this zone's quests off the top
-- of the column would be the tracker answering a question you asked once with
-- one you ask every time you look at it.
--
-- Read through Log.Pins, which returns the pinned quests that are in the log,
-- oldest pin first. The saved table is never walked here: it holds keys, some
-- of them for quests you handed in an hour ago.
function Column.Quests()
	local out, here = {}, {}
	local scope = Column.Showing()
	if scope then
		for _, zone in ipairs(Log.Zones()) do
			if scope[zone.name] then
				for _, quest in ipairs(zone.quests) do
					out[#out + 1] = quest
					here[quest.key] = true
				end
			end
		end
	end
	for _, quest in ipairs(Log.Pins()) do
		if not here[quest.key] then
			out[#out + 1] = quest
		end
	end
	return out
end

--------------------------------------------------------------------------
-- The rows
--------------------------------------------------------------------------

-- Clicking a row opens the quest log on that quest.
--
-- Quests/Tracker.lua already wrote this: it is the swap that made a click in
-- Questie's tracker open this addon's window instead of the one in the attic,
-- and Tracker.Open is the whole of it. So a click here is one call and no new
-- path, and a quest the client cannot place answers false rather than opening
-- the window on whatever it showed last.
--
-- An objective row carries the id of the quest above it, so clicking the line
-- that says how many trappers are left opens the quest those trappers are for.
local function Press(row)
	if row.quest then
		ns.QuestTracker.Open(row.quest)
	end
end

-- One row of the column, made once and reused for whatever lands on it next.
--
-- Two pools rather than one, because a quest's name and one of its objectives
-- are drawn at different sizes and a shared pool would set the font object on
-- every row of every paint.
--
-- Shadowed rather than outlined, which is what UI/Feed.lua's rows over the
-- world are and for the same reason: the wash under this column is a gradient
-- and the right of it is the world, so there is no surface here whose colour
-- the addon can promise. An outline would be honest too and it has a fourteen
-- pixel floor, which is a tracker half again as tall for a rim nothing needs
-- over a wash.
local function Take(pool, at, size, indent)
	local row = pool[at]
	if row then
		return row
	end
	row = CreateFrame("Button", nil, stack.frame)
	row.mark = ns.Fill(row, "ARTWORK", C.heading[1], C.heading[2], C.heading[3], 1)
	row.mark:SetPoint("TOPLEFT")
	row.mark:SetPoint("BOTTOMLEFT")
	row.mark:SetWidth(PIN)
	row.mark:Hide()

	row.text = UI.Label(row, size, C.text, "LEFT", UI.SHADOW)
	row.text:SetPoint("LEFT", indent, 0)
	row.text:SetPoint("RIGHT", -M.rowGap, 0)

	-- The left button and the up edge, written out rather than left to the
	-- widget's default. A row is a Button and a Button that registers nothing
	-- answers the left button on the up edge already, so this changes no
	-- behaviour and says what the behaviour is, which is the thing that goes
	-- wrong first in this addon when nobody writes it down.
	UI.Press.Clicks(row, "up", "LeftButton")
	row:SetScript("OnClick", Press)

	-- The right button and the middle one to the camera, on a client that will
	-- take the call. 2.5.6 will not: SetPassThroughButtons arrived in 10.1.5,
	-- UI.PassCamera pcalls it and answers false here, and the rows keep every
	-- button they are given. So a right drag begun on this column stops dead on
	-- the live client. It is worth it: the rows are the whole of the feature, a
	-- tracker you cannot click is a picture, and the frame is one you drag to
	-- wherever your camera hand is not.
	UI.PassCamera(row)

	pool[at] = row
	return row
end

-- Every row the pool is holding past the end of this paint. This client cannot
-- destroy a frame, so a column that shrank has rows to put away by hand.
local function Spare(pool, used)
	for at = used + 1, #pool do
		pool[at]:Hide()
	end
end

-- Whether the rows answer the pointer at all. They give it up while the frame
-- is unlocked, for the reason Progress/Rails.lua gives: a row that took the
-- press would swallow the drag that is the whole point of unlocking.
local function Mouse(pool, on)
	for _, row in ipairs(pool) do
		row:EnableMouse(on)
	end
end

--------------------------------------------------------------------------
-- The plates
--------------------------------------------------------------------------

-- What a plate looks like, in the three states a tab on the turned strip has
-- and in the same three fills, so one zone drawn two ways reads as one control.
local function Shade(row)
	local fill, tone = C.chrome, C.dim
	if row.open then
		fill, tone = C.selected, C.heading
	elseif row.hovered then
		fill, tone = C.hover, C.text
	end
	UI.Tint(row.bg, fill)
	row.text:SetTextColor(tone[1], tone[2], tone[3])
	row.mark:SetShown(row.open and true or false)
end

local function Unfold(row)
	Column.Choose(row.key)
end

local function Lit(row)
	row.hovered = true
	Shade(row)
end

local function Unlit(row)
	row.hovered = nil
	Shade(row)
end

-- One plate, made once and reused for whatever zone lands on it next.
--
-- Not off Take above, which builds a line of text. A plate is a control: it
-- carries a fill the pointer answers, a dot in the corner nothing else uses and
-- a press that opens a zone rather than a quest.
--
-- Its accent is the two pixels a pinned quest's mark is, in the same column of
-- the row, so the tracker keeps one left edge whichever kind of row is at the
-- top of it. In the accent colour rather than the pin's gold, because the two
-- say different things: this one is the zone you are reading and that one is a
-- quest that is yours.
local function Slab(at)
	local row = plates[at]
	if row then
		return row
	end
	row = CreateFrame("Button", nil, stack.frame)
	row.bg = ns.Fill(row, "BACKGROUND", C.chrome[1], C.chrome[2], C.chrome[3], 1)
	row.bg:SetAllPoints()

	row.mark = ns.Fill(row, "ARTWORK", C.accent[1], C.accent[2], C.accent[3], 1)
	row.mark:SetPoint("TOPLEFT")
	row.mark:SetPoint("BOTTOMLEFT")
	row.mark:SetWidth(PIN)

	-- A quest ready to hand in, somewhere you are not looking. The same three
	-- pixels of heading gold the turned strip puts in the corner of a tab, in
	-- the corner of a plate instead.
	row.dot = ns.Fill(row, "OVERLAY", C.heading[1], C.heading[2], C.heading[3], 1)
	row.dot:SetSize(DOT, DOT)
	row.dot:SetPoint("RIGHT", -M.rowGap, 0)

	row.text = UI.Label(row, ZONE_TEXT, C.dim, "LEFT", UI.SHADOW)
	row.text:SetPoint("LEFT", LEAD, 0)
	row.text:SetPoint("RIGHT", -(M.rowGap * 2 + DOT), 0)

	UI.Press.Clicks(row, "up", "LeftButton")
	row:SetScript("OnClick", Unfold)
	row:SetScript("OnEnter", Lit)
	row:SetScript("OnLeave", Unlit)
	UI.PassCamera(row)

	plates[at] = row
	return row
end

--------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------

-- One line under a quest's name. The text is pointed at its indent on every
-- paint rather than once when the row was made, because a pooled row that was a
-- party member's line last paint may be an objective this one.
local function Beneath(quest, line, text, shade, indent)
	line = line + 1
	local under = Take(lines, line, LINE_TEXT, indent)
	under.quest = quest.id
	under.text:SetPoint("LEFT", indent, 0)
	under.text:SetText(text or "")
	under.text:SetTextColor(shade[1], shade[2], shade[3])
	under:Show()
	stack:Add(under, { height = LINE })
	return line
end

-- One quest's name and a row under it per thing the quest still wants. Answers
-- the two counts it moved on, because the pools are trimmed on them.
--
-- The group is drawn off the quest's `party`, which Quests/Log.lua read through
-- Quests/Party.lua: the same list the quest window draws, so the tracker and
-- the window cannot name different people. Who is on it goes under the name,
-- because the client can say who when Questie cannot say how far. How far goes
-- under each objective, a line per member Questie has heard from, which is
-- Questie's own tooltip on the column you are already reading.
local function Quest(quest, head, line)
	head = head + 1
	local row = Take(heads, head, TITLE_TEXT, LEAD + MARK)
	local tone = Log.Tint(quest)
	-- The quest window's tick, in its glyph face and its colour. Made here rather
	-- than in Take because only a quest's name carries one and the objective
	-- lines share that pool's constructor.
	if not row.tick then
		row.tick = UI.Glyph(row, M.glyph, C.tick, "LEFT")
		row.tick:SetPoint("LEFT", LEAD, 0)
		row.tick:SetWidth(MARK)
		row.tick:SetText(Log.TICK)
	end
	row.tick:SetShown(quest.complete and true or false)
	row.quest = quest.id
	row.text:SetText(Log.Label(quest, ns.QuestWhere.Tag(quest.id)))
	row.text:SetTextColor(tone[1], tone[2], tone[3])
	row.mark:SetShown(Pinned(quest))
	row:Show()
	stack:Add(row, { height = TITLE })

	local party = quest.party or {}
	local with = Party.With(party)
	if with then
		line = Beneath(quest, line, with, C.quiet, LEAD + M.indent)
	end

	for at, step in ipairs(Log.Objectives(quest.key) or {}) do
		line = Beneath(quest, line, step.text, step.done and C.quiet or C.dim, LEAD + M.indent)
		for _, member in ipairs(party) do
			local said, done = Party.Step(member, step.index or at)
			if said then
				line = Beneath(quest, line, said, done and C.quiet or C.dim, LEAD + M.indent * 2)
			end
		end
	end
	return head, line
end

-- The quests of an open zone, under its own plate, and nothing under a closed
-- one. Every quest it draws is noted, because the pass below has to be able to
-- tell a pin it has already drawn here from one it still owes a row.
local function Quests(zone, open, head, line, drawn)
	if not open then
		return head, line
	end
	for _, quest in ipairs(zone.quests) do
		head, line = Quest(quest, head, line)
		drawn[quest.key] = true
	end
	return head, line
end

-- The harmonica: a plate per zone your log has quests in, in the log's own
-- order, with the open ones unfolded under their own plates.
--
-- Off Log.Zones rather than off Column.Tabs, because this needs the quests as
-- well as the label and Tabs throws them away. Both label the plate through
-- Column.Zoned, which is the part that would drift.
local function Folded(head, line)
	local showing = Column.Showing() or {}
	local at, drawn = 0, {}
	for _, zone in ipairs(Log.Zones()) do
		if #zone.quests > 0 then
			at = at + 1
			local open = showing[zone.name] and true or false
			local row = Slab(at)
			row.key = zone.name
			row.open = open
			row.text:SetText(Column.Zoned(zone))
			row.dot:SetShown(zone.done > 0 and not open)
			Shade(row)
			row:Show()
			stack:Add(row, { height = ZONE })
			head, line = Quests(zone, open, head, line, drawn)
		end
	end
	return head, line, at, drawn
end

-- The column, filled in from the model. Answers how many quests went on it.
--
-- Two shapes and one list of quests. A harmonica lays the plates first and
-- unfolds the open ones as it goes, so what is left of Column.Quests by the
-- time the loop below runs is the pins from somewhere you are not standing;
-- with the turned strip nothing has been drawn yet and that loop draws the lot.
-- Either way the pins land at the foot, which is where they have always been
-- and is the whole of why they are ordered after the zone.
local function Fill()
	stack.cells = {}

	local quests = Column.Quests()
	local head, line, at, drawn = 0, 0, 0, nil
	if Harmonica() then
		head, line, at, drawn = Folded(head, line)
	end
	for _, quest in ipairs(quests) do
		if not (drawn and drawn[quest.key]) then
			head, line = Quest(quest, head, line)
		end
	end

	Spare(heads, head)
	Spare(lines, line)
	Spare(plates, at)
	return #quests
end

-- Everything the tracker draws, from the model rather than from the client.
--
-- The log is read here. That is a second Log.Read in the sessions where the
-- quest window is also open, and it is the price of a tracker that is up while
-- the window is shut: the window reads only while it is showing, so with it
-- closed nobody else would have read at all. Both drawings still come off the
-- one set of zones that read leaves behind, which is the part that matters.
function Column.Paint()
	if not built or painting then
		return false
	end
	painting = true
	Log.Read()

	-- Walking somewhere new, which is the one thing that undoes a press on a
	-- tab. Read here rather than off a zone event, because ZONE_CHANGED fires
	-- every time you cross a road inside one zone and a choice a road undid
	-- would be a control you cannot use while moving.
	local here = Underfoot(Scope())
	if here and here ~= stoodIn then
		chosen = nil
	end
	stoodIn = here

	-- The zones, as tabs on the turned strip or as plates in the stack, and
	-- never as both. A harmonica draws its own in Fill below, so the strip is
	-- handed nothing, takes no width and goes off the screen; one empty table
	-- rather than a fresh one, because this runs on every quest update.
	local tabs = Harmonica() and NONE or Column.Tabs()
	side:Set(tabs)
	-- What one tab may be, which is the screen divided by how many of them
	-- there are and never more than a zone name needs. A log with quests in
	-- fifteen zones gets fifteen short tabs rather than a strip off the bottom
	-- of the monitor.
	local longest = ZONE_LONGEST
	if #tabs > 0 then
		longest = math.min(longest,
			math.max(math.floor(Room() / #tabs), ZONE_SHORTEST))
	end
	local strip, down = side:Resize(longest)
	local lead = #tabs > 0 and (strip + ZONE_GAP) or 0
	side.frame:SetShown(#tabs > 0)
	side:Select(chosen or here)

	Fill()
	tally.text:SetText(("%s quests"):format(Log.Full()))
	stack:SetWidth(WIDTH)
	local height = stack:Reflow()

	-- The words, measured, and the body given it. A frame with no height has
	-- no rectangle on this client and lays nothing inside it out, so this is
	-- the tally and the rows arriving on the screen rather than a tidy number.
	local told = math.max(TALLY + M.rowGap + height, 1)
	body:ClearAllPoints()
	body:SetPoint("TOPLEFT", lead, 0)
	body:SetHeight(told)
	frame:SetWidth(lead + WIDTH)
	frame:SetHeight(math.max(told, down))

	-- Up whenever your log has a quest in it, and down when the log is empty.
	-- It was up only while there were quests under your feet, which was right
	-- until the zones arrived: standing in a city would take the plates away
	-- with the rows, and the plates are how you get out of the city.
	local full = (Log.Tally()) > 0
	frame:SetShown(full)
	-- Last, and over whatever the pools now hold. A row or a tab made on this
	-- paint has taken no side in the lock yet, and one that answers the pointer
	-- while the frame is being placed swallows the drag that is the point of
	-- unlocking.
	Column.Lock()
	painting = false
	return full
end

--------------------------------------------------------------------------
-- The frame
--------------------------------------------------------------------------

function Column.Build()
	if built then
		return frame
	end

	frame = CreateFrame("Frame", "WarriorKitQuestColumn", UIParent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetSize(WIDTH, 1)
	UI.Adopt(frame, ns.Zoom("questsZoom"))

	-- One tab per zone, down the left edge, turned a quarter turn, and empty
	-- whenever the zones are drawn as plates instead. Named for the reason every
	-- list in this addon is: a strip that has laid itself out wrongly has to be
	-- measurable from a macro and from scripts/harness.lua.
	side = UI.SideTabs(frame, {
		name = "WarriorKitQuestZones",
		size = ZONE_TEXT,
		onSelect = function(name) Column.Choose(name) end,
	})
	side.frame:SetPoint("TOPLEFT")

	-- Everything that is not the strip, in one frame, so a paint moves the
	-- words off the strip's width with one anchor rather than two.
	--
	-- Sized in both directions rather than only across, and the one is not
	-- decoration. A frame with no height has no rectangle on this client, and
	-- nothing anchored inside one is laid out at all: the tally and every row
	-- under it went through this frame the moment the strip arrived, so a
	-- width and nothing else was a tracker drawing its zone tabs over an empty
	-- column. It is the rule every other container in this addon already
	-- follows, which is why they are all made with math.max(size, 1).
	body = CreateFrame("Frame", nil, frame)
	body:SetPoint("TOPLEFT")
	body:SetSize(WIDTH, 1)

	-- No background and no hairline, because this is not a window. The wash is
	-- the whole of the ground: solid shadow at the left edge where the words
	-- start, gone by the right edge where they end, so the column has something
	-- to be read against without a panel cut out of the world.
	wash = UI.Wash(frame, C.shadow, "LEFT", "BACKGROUND")
	wash:SetAllPoints(frame)

	-- How full your log is, over the quests. The same reading the quest window
	-- puts in its title bar, off the same Log.Full, because two counts of one
	-- log is how the two drift.
	--
	-- Quiet rather than body text. It is the one line here that is not a thing
	-- you have to do, and a tracker read at a glance has to let the eye go
	-- straight past it to the quest names.
	tally = CreateFrame("Frame", nil, body)
	tally:SetPoint("TOPLEFT")
	tally:SetPoint("TOPRIGHT")
	tally:SetHeight(TALLY)
	tally.text = UI.Label(tally, TALLY_TEXT, C.quiet, "LEFT", UI.SHADOW)
	tally.text:SetPoint("LEFT", LEAD, 0)
	tally.text:SetPoint("RIGHT", -M.rowGap, 0)

	stack = UI.Stack(body, WIDTH)
	stack.frame:ClearAllPoints()
	stack.frame:SetPoint("TOPLEFT", tally, "BOTTOMLEFT", 0, -M.rowGap)

	place = UI.Placeable(frame, {
		name = "WarriorKit quest tracker",
		moved = function(anchor)
			ns.db.questsColumnPoint = anchor
		end,
	})
	ns.Theme.Wear("quests", frame)

	frame:Hide()
	built = true
	return frame
end

-- Whether the tracker should be on the screen right now.
--
-- The switch that takes Questie's tracker off, and no switch of its own. Two
-- trackers on one screen is the thing item 90 went to the trouble of a reload
-- to avoid, and a second box that could put ours up beside theirs would hand
-- that straight back.
function Column.Wanted()
	return ns.QuestTrackerOff.Wanted()
end

-- Everything a setting can move: where it sits, how big it is drawn, whether it
-- is there at all, and then what is on it.
function Column.Apply()
	if not ns.db then
		return false
	end
	if not Column.Wanted() then
		if built then
			frame:Hide()
		end
		return false
	end

	Column.Build()
	place:Place(ns.db.questsColumnPoint)
	UI.Rezoom(frame, ns.Zoom("questsZoom"))
	return Column.Paint()
end

function Column.Lock()
	if not built then
		return
	end
	local unlocked = not ns.db.locked
	place:Lock(unlocked)
	Mouse(heads, not unlocked)
	Mouse(lines, not unlocked)
	Mouse(plates, not unlocked)
	side:Mouse(not unlocked)
end

-- Redrawn only while it is on the screen, which is the rule the quest window's
-- own refresh follows: reading sixty rows to update something nobody is looking
-- at is the waste this addon has a gate for.
function Column.Refresh()
	if not built or not Column.Wanted() then
		return false
	end
	return Column.Paint()
end

--------------------------------------------------------------------------

-- Short enough for a reading on the options page, which never wraps.
function Column.Describe()
	if not ns.db.quests then
		return "off with the quest log"
	end
	if not Column.Wanted() then
		return "off, and Questie's tracker has the screen"
	end
	local name = Standing()
	if not name then
		return "waiting to hear where you are standing"
	end
	-- Counted in two halves, because the column holds two kinds of row and one
	-- number over both would say "3 quests, in Westfall" about a column with one
	-- Westfall quest on it. The reading is the only place a player finds out
	-- what the tracker thinks it is looking at, so it has to be able to say that
	-- what it is looking at is somewhere else.
	local showing = Column.Showing() or {}
	local here, away = 0, 0
	for _, quest in ipairs(Column.Quests()) do
		if showing[quest.zone] then
			here = here + 1
		else
			away = away + 1
		end
	end

	-- A zone you pressed is named as one you pressed. It is the one state where
	-- the column is not answering "what is in front of me", and a reading that
	-- said "3 quests, in Westfall" while the player stood in Ironforge would be
	-- the tracker looking wrong rather than the strip looking chosen.
	local said
	if chosen and here == 1 then
		said = ("one quest, in %s, which you picked"):format(chosen)
	elseif chosen then
		said = ("%d quests, in %s, which you picked"):format(here, chosen)
	elseif here == 0 then
		said = ("nothing in your log is in %s"):format(name)
	elseif here == 1 then
		said = ("one quest, in %s"):format(name)
	else
		said = ("%d quests, in %s"):format(here, name)
	end

	if away == 1 then
		return said .. ", and one pinned elsewhere"
	elseif away > 1 then
		return said .. (", and %d pinned elsewhere"):format(away)
	end
	return said
end

--------------------------------------------------------------------------

-- The client's own quest events, and the three that say you have walked
-- somewhere new.
--
-- QUEST_LOG_UPDATE is the client saying it looked rather than the log changing,
-- several times a second while you are killing things, and each one is a read
-- and a repaint of a handful of rows. That is the same cost the quest window
-- already pays while it is open, taken by a frame that is open more often. If
-- it ever turns out to be the stutter Quests/Where.lua warns about, the fix is a
-- stamp on ns.QuestLog that both readers check, not a second model here.
--
-- The zone events do not empty ns.QuestHere. That answer is held on the map id
-- and re-derived when the id moves, so walking into Duskwood is a fresh reading
-- without anything having to say so.
local function OnEvent(_, event)
	if event == "PLAYER_LOGIN" then
		Column.Apply()
		return
	end
	Column.Refresh()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("QUEST_WATCH_UPDATE")
events:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- The two edges of a fight, for the foot line rather than for the quests. It
-- goes quiet in combat, and the swords coming out is not otherwise an event
-- this column hears: without these the sentence would sit over the fight until
-- the next QUEST_LOG_UPDATE happened to arrive, and hang about after it.
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", OnEvent)

-- A party member's count landing in Questie, which none of the client's events
-- says. Quests/Party.lua says why it arrives after them.
ns.QuestParty.OnHeard(Column.Refresh)

-- A resolution change moves every size in this file at once, the same way it
-- moves the experience rails and the swing bars.
UI.OnRescale(function()
	Column.Apply()
end)
