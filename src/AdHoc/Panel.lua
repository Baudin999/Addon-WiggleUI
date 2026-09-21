local ADDON, ns = ...

local Panel = {}
ns.AdHocPanel = Panel

--------------------------------------------------------------------------
-- Designing a bar, on the page
--
-- One bar at a time, picked off a strip of tabs with a plus on the end. The
-- plus asks what the bar is called and makes nothing until you answer, so a
-- bar on the strip is a bar somebody named. Under the strip: the name, the
-- key, and the ring itself.
--
-- **The page draws the ring, not a row.** The squares sit on the same circle
-- the ring draws them on, at the same angles, at a radius that grows with the
-- count exactly as the ring's does. It was a line of squares that wrapped at
-- the page's width, and a line teaches an order the gesture does not use: the
-- thing you have to know to use one of these bars is which way to push, and a
-- line cannot say. Drop something on it and the circle opens up and takes it,
-- which is what it will look like under your thumb.
--
-- **The empty square is in the middle.** That is where the ring writes the
-- name of what you are pointing at, and it is the one thing on this page the
-- ring does not have. On the circle it would be a position the ring has not
-- got, every square would shuffle round as you dropped onto it, and the circle
-- you were looking at would never be the circle you got.
--
-- Drag a spell out of the book, an item out of a bag, a macro or a gear set
-- off the character page onto the middle to add it, onto a square to replace
-- what is there, from one square to another to move it round the circle, and
-- off the ring to take it away. A right click takes it away too.
--
-- The circle here and the ring on the screen are two pictures of one list.
-- Nothing on this page draws a cooldown or a colour, because this is where you
-- decide what is on the bar and the ring is where you read what it is doing.
--
-- Nothing here names a setting. AdHoc.lua owns the list and Bars.lua owns the
-- keys and the geometry; this file asks which record is where and tells them
-- where a drop landed.
--------------------------------------------------------------------------

local UI = ns.UI
local C, M = ns.UI.Color, ns.UI.Metric

-- A square on the page. Half the square the ring draws, which is the small
-- sharp size in UI.IconSizes and is what everything else on a settings page is
-- drawn at. Every other number on this page comes off it: the circle is the
-- ring's own circle times this over the ring's square.
local EDGE = 27

-- The pool, one square per place on a bar, because a frame cannot be destroyed
-- on these clients. The empty one in the middle is the next place along and so
-- comes out of the same pool; a bar with every place taken has no middle square
-- and nothing to draw there.
local squares = {}

-- Which square a button belongs to, for the drag the cursor does not carry.
local owner = {}

-- The square being dragged. Set when the drag starts and read when the button
-- comes up, which is inside one gesture and never outside one.
local lifted = nil

local function Shown()
	return ns.AdHoc.Shown()
end

local function Current()
	return ns.AdHoc.Get(Shown())
end

--------------------------------------------------------------------------
-- What the cursor is holding
--------------------------------------------------------------------------

-- A refusal is said once per reason rather than once per ask, because the
-- widget asks on hover as well as on drop and a loaded cursor crossing the
-- line would print a line per square.
local told = {}

local function Say(line)
	if told[line] then
		return
	end
	told[line] = true
	ns.Print(line)
end

local function Take(kind, a, b, c)
	if not kind then
		return nil
	end
	local record, why = ns.AdHoc.Carry(kind, a, b, c)
	if not record and why then
		Say(why)
	end
	return record
end

-- A drag the client's cursor cannot hold, which is a gear set off the toggle
-- stack on the character page. There is nothing to pick up for one, so
-- UI/Carry.lua carries the name and the picture and this turns them into a
-- record. Anything else carried that way, a circle off a gear row among them,
-- is not something a bar holds and is refused in silence: the drag came from
-- another window and landing on the wrong square is not a mistake worth a line.
local function Carried(held)
	if type(held) ~= "table" or held.kind ~= "set" then
		return nil
	end
	return Take("set", held.name, held.icon)
end

--------------------------------------------------------------------------
-- The two ends of a drag
--------------------------------------------------------------------------

local function Lift(w)
	lifted = nil
	if w.record then
		lifted = w.at
	end
end

-- Where the button came up. On another square, the record moves there, and the
-- middle square is the place after the last one, so a drag into the middle puts
-- it at the end. On the square it came from, nothing happened. Anywhere off the
-- ring, it comes off the bar.
local function Landed()
	local from = lifted
	lifted = nil
	if not from then
		return
	end
	local focus = ns.MouseFocus()
	local w = focus and owner[focus] or nil
	if w and w.at == from then
		return
	end
	if w then
		ns.AdHoc.Move(Shown(), from, w.at)
	else
		ns.AdHoc.Take(Shown(), from)
	end
end

-- A drop, or a right click, on one square.
local function Drop(w, record)
	if record == nil then
		return ns.AdHoc.Take(Shown(), w.at) ~= nil
	end
	local ok, why = ns.AdHoc.Put(Shown(), w.at, record)
	if not ok and why then
		ns.Print(why)
	end
	return ok
end

--------------------------------------------------------------------------
-- One square
--------------------------------------------------------------------------

local function Says(w)
	local record = w.record
	if not record then
		return { kind = "note", title = "the middle",
			lines = { "Drag a spell out of your book, an item out of a bag, a macro or a gear set here.",
				"It goes on the end of the ring and the circle opens up to take it." } }
	end
	return { kind = "note", title = record.name,
		lines = { "Drag it round the circle to move it, or into the middle to put it last.",
			"Drag it off the ring to take it away. A right click does that too." } }
end

local function Square(frame)
	local w
	w = ns.UI.DropSquare(frame, EDGE, function()
		return w.record and w.record.icon, w.record and w.record.name
	end, function(record)
		return Drop(w, record)
	end, {
		take = Take,
		carried = Carried,
		after = ns.Options.Refresh,
		drag = function() Lift(w) end,
		landed = Landed,
		describe = function() return Says(w) end,
	})
	-- The mark on the empty one. A square with nothing in it is a hole in the
	-- middle of the circle until something says what it is for, and the plus is
	-- the same mark the strip above puts on the tab that makes a bar.
	w.plus = UI.Glyph(w, M.glyph, C.dim, "CENTER")
	w.plus:SetPoint("CENTER")
	w.plus:SetText("+")
	owner[w.button] = w
	return w
end

--------------------------------------------------------------------------
-- The circle
--------------------------------------------------------------------------

-- One square at one place on the circle, measured from the middle of it.
local function Place(w, at, record, x, y)
	w.at, w.record = at, record
	w:SetSize(EDGE, EDGE)
	w:ClearAllPoints()
	w:SetPoint("CENTER", w:GetParent(), "CENTER", UI.Whole(x), UI.Whole(y))
	w:Show()
	w.Refresh()
	w.plus:SetShown(record == nil)
end

-- The shown bar's squares on the ring's own circle, the empty one in the
-- middle, and how tall that came out.
--
-- Nothing here works out where a square goes. AdHocBars.Where answers that for
-- the ring, and this multiplies its answer by the size of a square here over
-- the size of a square there. One rule, two pictures: a change to the ring's
-- radius moves this circle without anybody coming back to this file.
local function Lay(frame)
	local records = ns.AdHoc.Squares(Shown())
	local count = records and #records or 0
	local scale = EDGE / ns.AdHocBars.SIZE
	local radius = ns.AdHocBars.Radius(math.max(count, 1)) * scale
	local side = 2 * (radius + EDGE)
	-- The place after the last one, which is where a drop lands, and none once
	-- every place is taken.
	local middle = count < ns.AdHoc.PER_BAR and count + 1 or nil

	frame.ring:SetSize(side, side)
	frame.ring:SetShown(records ~= nil)
	ns.AdHocRing.Lay(frame.chrome, count, radius, EDGE)

	for at = 1, #squares do
		local w = squares[at]
		if records and at <= count then
			local x, y = ns.AdHocBars.Where(at, count)
			Place(w, at, records[at], x * scale, y * scale)
		elseif records and at == middle then
			Place(w, at, nil, 0, 0)
		else
			w.at, w.record = nil, nil
			w:Hide()
		end
	end

	if not records then
		return 0
	end
	return side
end

function Panel.Square(at)
	return squares[at]
end

--------------------------------------------------------------------------
-- Making one
--------------------------------------------------------------------------

-- The plus on the strip. It asks what the bar is called and makes nothing
-- until that is answered, so the first thing a bar has is a name rather than
-- the first thing you have to correct: the plus used to make `Bar 3` and leave
-- you to find the name field further down the page and type over it.
--
-- The cap is asked about before the window opens rather than after it is
-- answered, because a name typed into a window that then refuses it is a
-- question that should not have been asked.
function Panel.Add()
	local room, full = ns.AdHoc.Room()
	if not room then
		ns.Print(full)
		return false
	end
	ns.UI.Name({
		title = "A bar of your own",
		note = "Name it for what goes on it: totems, trade skills, the things you only press in town.",
		accept = "make it",
		onAccept = function(name)
			local index, why = ns.AdHoc.Add(name)
			if not index then
				ns.Print(why)
			end
			ns.Options.Refresh()
		end,
	})
	return true
end

--------------------------------------------------------------------------

function Panel.Build(ui)
	ui.Section("Ad hoc bars", "Action bars")
	ui.Lede("A ring of your own on a key: up while you hold it, and the square you push toward fires when you let go.")

	ui.Tabs(
		function()
			local labels = {}
			for index, bar in ipairs(ns.AdHoc.All()) do
				labels[index] = bar.name
			end
			return labels
		end,
		Shown,
		function(index) ns.AdHoc.Show(index) end,
		{ onAdd = Panel.Add })

	ui.Reading("bars", function()
		local count = ns.AdHoc.Count()
		if count == 0 then
			return "none yet, press + and name one"
		end
		return ("%d of %d"):format(count, ns.AdHoc.MAX)
	end)

	ui.TextField("name",
		function()
			local bar = Current()
			return bar and bar.name or ""
		end,
		function(value) ns.AdHoc.Rename(Shown(), value) end)

	ui.KeyField("key",
		function()
			local bar = Current()
			if bar and bar.key ~= "" then
				return bar.key
			end
			return "|cff808080not bound|r"
		end,
		function(combo)
			local ok, why = ns.AdHocBars.Bind(Shown(), combo)
			if not ok then
				ns.Print(why)
			end
		end,
		function() ns.AdHocBars.Bind(Shown(), "") end)
	ui.Hint("Hold it to open the ring, push toward a square and let go to use it. Let go without moving and nothing happens.")

	ui.Reading("this key", function()
		local bar = Current()
		if not bar or bar.key == "" then
			return "not bound"
		end
		if bar.displaced ~= "" then
			return "shadows " .. bar.displaced
		end
		return "nothing else wanted it"
	end)

	ui.Gap()

	ui.Custom(function(frame)
		-- A frame of its own for the circle, centred on the row, so a square
		-- sits at the offset AdHocBars.Where gives and nothing on this page has
		-- to add half a row's height to it.
		frame.ring = CreateFrame("Frame", nil, frame)
		frame.ring:SetPoint("TOP")
		-- The same pie the ring draws under your thumb, at the size of a
		-- settings page. AdHoc/Ring.lua is the one drawing of it.
		frame.chrome = ns.AdHocRing.Dress(frame.ring)
		for at = 1, ns.AdHoc.PER_BAR do
			squares[at] = Square(frame.ring)
		end
		return function()
			return Lay(frame)
		end
	end, { height = M.control, label = "the ring this bar draws" })
	ui.Hint("Drop a spell, an item or a macro in the middle to add it. Drag a square round the circle to move it, or off it to take it away. The first is at twelve and the rest go clockwise, the way you push.")

	local low, high = ns.AdHocBars.RadiusRange()
	ui.Size("radius", low, high, 10,
		function() return ns.db.adhocRadius end,
		function(value)
			ns.db.adhocRadius = value
			ns.AdHocBars.Apply()
		end)
	ui.Hint("How far out the squares sit, and with it how far you push. A release that never leaves the middle of the ring fires nothing.")

	ui.Reading("this ring", function()
		local bar = Current()
		if not bar then
			return "no bar"
		end
		local count = math.max(#bar.buttons, 1)
		local drawn = math.floor(ns.AdHocBars.Radius(count) + 0.5)
		if ns.AdHocBars.Packed(count) then
			return ("%d units, opened out for %d squares"):format(drawn, count)
		end
		return ("%d units"):format(drawn)
	end)

	ui.Reading("on screen", function()
		local index = Shown()
		if index == 0 then
			return "no bar"
		end
		if not ns.db.adhoc then
			return "the bars are off"
		end
		local visible = ns.AdHocBars.Visible(index)
		if visible == nil then
			return "not built yet"
		end
		return visible and "up" or "hidden, hold the key"
	end)

	ui.Action(
		function()
			local bar = Current()
			return bar and ("delete " .. bar.name) or "delete"
		end,
		function() ns.AdHoc.Remove(Shown()) end,
		function() return Current() ~= nil end)
end
