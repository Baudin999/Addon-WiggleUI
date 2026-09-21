local ADDON, ns = ...

local SetRow = {}
ns.SetRow = SetRow

local UI = ns.UI
local C, M = UI.Color, UI.Metric

--------------------------------------------------------------------------
-- The sets on the gear page
--
-- Two things that are one feature: a line of small circles under every gear
-- row, one per set, and a stack of toggles at the top left of the page. They
-- are here rather than in Character/Paperdoll.lua because that file is the
-- page, and the page's job is to host these rather than to know how a set is
-- drawn. What stays over there is the arithmetic a row's new height changes.
--
-- **The big disc stays what you are wearing.** That is the sheet's whole job,
-- and a page that drew a saved set on the disc instead would stop answering
-- the question anybody opened it for. The set goes on a third line, under the
-- item level, at the near edge:
--
--     O   Sunfury Robe of the Magus
--         ilvl 128              * * *
--         o o o
--
-- **A circle that disagrees with the disc above it is a piece that did not go
-- on.** That is the reading this layout is for. After a swap you run an eye
-- down the near edge of the column and every circle still showing a picture is
-- a slot the set wanted and did not get, which is the whole of "did it work"
-- without a line of text anywhere.
--
-- **Four states and no two of them look alike.** The item's icon for a set that
-- names a piece; the same icon at rest when that piece is what the disc above
-- is already showing; a hollow ring for a slot the set has never been told
-- about; and a ring with a bar through it for one deliberately left bare. The
-- last two are opposite intentions, so they are drawn as far apart as sixteen
-- pixels allows: nothing inside the ring against something inside it.
--
-- **Nothing here touches the secure square.** The circles sit under the note
-- at the near edge and the toggles take their room off the top of the page, so
-- neither is ever over the thirty-six pixels the client owns. A frame laid over
-- a protected button is a fight for the mouse, and a drop that landed on it in
-- combat would be a refused equip rather than an edit to a set.
--
-- **The gestures are the ones a slot already has, and one that it must not
-- have.** A click takes what you are wearing into the set, which is how a set
-- gets built a piece at a time. A drop out of a bag fills the slot from the
-- cursor. A drag off empties it. A right click cycles the slot through the
-- fourth state and back, which is the only way to it and the reason it is not
-- a fifth gesture: the three above can all say which piece, and none of them
-- can say none. Between two circles the thing being carried
-- goes through UI/Carry.lua rather than the client's cursor, because the
-- client's cursor holding a piece of gear is one misplaced release away from
-- equipping, unequipping or destroying it, and copying a name between two
-- saved lists should not be able to touch what you have on. For the same
-- reason the worn square above is never a drag source for any of this:
-- picking a piece up off the paperdoll takes it off you.
--
-- **None of it on an inspect page.** Every call below answers about your own
-- sets, so a circle under somebody else's boots would be a fact about you
-- drawn under their name, which is the reason the durability rule, the stone
-- countdown and the cooldown arc are all missing from that page too.
--------------------------------------------------------------------------

-- The circle, and how far apart two of them sit. Sixteen, and it shipped at
-- ten, which was wrong on a monitor in a way it was not wrong in the layout: a
-- ten pixel disc with a two pixel rim is six pixels of picture, and six pixels
-- of an item icon is a dot rather than a helmet. Sixteen is four larger than
-- the socket disc and it earns the difference: a socket is read across one row
-- and these are read down a column of eleven.
--
-- The row grows with it, because SetRow.Band below is LANE and
-- Character/Paperdoll.lua takes every number it has off that. A hunter's left
-- column is eleven rows, so the page is eleven times eighteen taller than the
-- one that has no sets, which is well inside what this monitor gives a sheet
-- clamped to 94 percent of its height.
local DISC = 16
local LANE = DISC + 2

-- How much of the circle the ring keeps for itself, which leaves twelve pixels
-- of picture. Small, and it is enough: what a circle is read for down a column
-- is whether there is a picture in it at all.
local RIM = 2

-- How far past the circle the mouse still answers, which makes a twenty-two
-- pixel target out of a sixteen pixel disc. A hit rect and not a bigger button,
-- the way the ammo row widens itself: the picture is the size it wants to be
-- and the target is the size a cursor needs.
local REACH = 3

-- Circles a row. Three because three fits under the note without reaching the
-- socket discs at the far end, and because a character with four sets is
-- reading the first three of them anyway.
local MOST = 3

-- The nineteen slots a set can name. The ammo row is the twentieth row on the
-- page and is not one of them: no set has ever wanted to save which arrows you
-- had, and three hollow rings under a stack of arrows would be three questions
-- the page cannot answer.
local SLOTS = 19

-- The toggle at the top of the page, which is deliberately the gear disc's own
-- size. It is the largest thing on the left of the page and it is meant to be:
-- a toggle is pressed and a circle is read, and the page already says which is
-- which by drawing one at thirty-six and the other at sixteen.
local TOGGLE = 36
local AIR = 4

-- What is drawn where a set has nothing. Read once rather than measured: a bar
-- two pixels thick is the thinnest mark that is still a mark on a disc this
-- small.
local BAR = M.hairline * 2

-- The mark the empty toggle wears instead of a picture, and how far across it
-- reaches. A plus drawn as two bars rather than a glyph or a file: the addon
-- ships no plus art, and a letter in the middle of a thirty-six pixel disc is
-- text in a stack that has none anywhere else.
local MARK = 14

-- What the empty toggle is called. A word for the thing it does and not a
-- name, because it is the one toggle in the stack that is not a set.
local MAKE = "new set"

-- How many sets are worth drawing, which is none at all on an inspect page.
local NOBODY = {}

local function Listed(pane)
	if pane.inspect then
		return NOBODY
	end
	return ns.Sets.All()
end

-- How much taller a gear row is for carrying a line of circles.
--
-- Nothing at none, and a line from the first set on. A character who has never
-- saved one opens the page that shipped, to the pixel, which is the promise
-- this feature made to everybody who does not use it.
--
-- It waited for the second set for a while and that was backwards. One saved
-- set you are not fully wearing is the case the circles exist for: the row
-- whose circle disagrees with the disc above it is the piece that did not go
-- on, and a page that hid that until you saved something else was a page that
-- said nothing about the one set you had.
function SetRow.Band(pane)
	return #Listed(pane) > 0 and LANE or 0
end

-- How much of the top of the page the toggles take.
--
-- Off the crown rather than out of the rows' own air, because the rows are
-- centred on what is left and the figure stands on their block: a stack drawn
-- over the top of the page without this would be a stack laid across the first
-- two rows of the left column, which is a mouse fight with two secure squares.
function SetRow.Crown(pane)
	if pane.inspect then
		return 0
	end
	-- Your sets, and the empty one under them. Never nought on your own sheet:
	-- the empty toggle is drawn on a page with no sets at all, because it is
	-- the only thing anywhere on the page that says a set can be made here.
	local count = #Listed(pane) + 1
	return count * TOGGLE + (count - 1) * AIR + M.gutter
end

--------------------------------------------------------------------------
-- The circles
--------------------------------------------------------------------------

-- What a circle is carrying, as the thing UI/Carry.lua hands to whatever it is
-- dropped on. The set and the slot as well as the link, because the drop has to
-- be able to say where it came from and the drag that lands on nothing has to
-- be able to put it back to unset.
local function Held(circle)
	return { set = circle.set, slot = circle.slot, link = circle.link }
end

-- A link into the slot a circle stands for, which is what all three of the
-- gestures that fill one come down to. One place rather than three, so the
-- set, the slot and the link are read off the circle the same way whether the
-- piece came from a click, from the bags or from another circle.
--
-- And the refusal is read here, because all three callers threw it away: a
-- helmet dropped on a ring circle did nothing and said nothing, which is the
-- one gesture on this page that looks broken rather than refused.
local function Put(circle, link)
	local ok, why = ns.Sets.Put(circle.set, circle.slot, link)
	if not ok and why then
		ns.Print(why)
	end
	return ok
end

-- The two ways a slot holds nothing, one door each.
--
-- A door apiece and not one call with a flag, because the two are opposite
-- intentions and a reader following a gesture down to the store should land on
-- the name of the thing it did. They are also the reason this file has doors at
-- all: scripts/trees.lua caps how many times the page may name ns.Sets, and a
-- call site per gesture would spend that cap on saying the same sentence twice.
local function Empty(circle)
	return ns.Sets.Empty(circle.set, circle.slot)
end

local function Clear(circle)
	return ns.Sets.Clear(circle.set, circle.slot)
end

-- What you have on, into a set. The slot is what separates the two gestures
-- that call this and nothing else is: a slot is one circle taking the piece on
-- the disc above it, and no slot is the whole character going in at once.
local function Capture(name, slot)
	return ns.Sets.Capture(name, slot)
end

-- A set dropped, with the confirm in front of it rather than behind it. The
-- store takes its own snapshot on the way out, so `/wui set undo` puts the set
-- back and the confirm is a light one that says so.
local function Forget(name)
	return ns.Sets.Remove(name)
end

-- What a set says about one slot, and whether that is the piece on the disc
-- above the circle. The worn link is handed in rather than read again: the
-- repaint above has it already.
--
-- Three answers out of one call and not two calls, because comparing what the
-- set saved against what you are wearing is a comparison of item keys and the
-- store is the one file that knows how an item is written down. This line
-- compared two raw links for a while, which is the `uniqueId` field moving the
-- first time anything touched your gear: all nineteen circles lit at once and
-- the page's headline reading went with them.
local function Entry(name, slot, worn)
	return ns.Sets.Entry(name, slot, worn)
end

-- A click, which is the gesture a set is actually built with: whatever is in
-- that slot right now goes into that set. Holding something on the cursor
-- makes it the drop instead, because that is what every square in the game
-- does with a click while your hand is full and a square that refused would
-- read as broken.
local function Clicked(circle)
	local kind, _, link = GetCursorInfo()
	if kind == "item" and type(link) == "string" then
		Put(circle, link)
		ClearCursor()
		return true
	end
	Capture(circle.set, circle.slot)
	return true
end

-- The right button on a circle, which is the only way to the fourth state.
--
-- Nothing else reaches it. A click captures, a drop names a piece and a drag
-- off unsets, so three gestures all say which piece and none of them says none,
-- and a set that cannot say none is a set that can never take a piece off you:
-- wearing one moves the slots it names and leaves an unset slot exactly as it
-- found it.
--
-- A cycle rather than a switch, so the gesture is its own undo. A slot holding
-- a piece goes to the deliberate hole, the hole goes back to unset, and unset
-- goes to the hole again, which means two presses from anywhere put the slot
-- back where the right button found it and no drag is needed to get out.
local function Cycled(circle)
	if not circle.set then
		return false
	end
	if circle.state == "empty" then
		return Clear(circle)
	end
	return Empty(circle)
end

-- A piece dragged out of a bag and let go over the circle.
local function Dropped(circle)
	local kind, _, link = GetCursorInfo()
	if kind ~= "item" or type(link) ~= "string" then
		return false
	end
	Put(circle, link)
	-- The cursor is put down here and not left holding the piece. A drop that
	-- filled the slot and left the item on the cursor is a player one click
	-- away from dropping their own helmet on the ground.
	ClearCursor()
	return true
end

-- The start of a drag off a circle, and what it puts on the cursor is a
-- picture rather than the item: UI/Carry.lua sets the pointer's art and the
-- client's own cursor stays empty the whole way, which is what makes a drag
-- between two sets unable to equip or destroy anything.
local function Grabbed(circle)
	if not circle.set or circle.state == "unset" then
		return false
	end
	UI.Carry.Lift(Held(circle), circle.art:GetTexture())
	return true
end

-- The release. Landing on another circle is a copy and landing anywhere else
-- is the slot going back to unset, which is the whole of how a set entry is
-- deleted. One call answers both: Land hands the thing to whatever was under
-- the pointer and says whether anything took it.
local function Released(circle)
	if UI.Carry.Land() then
		return true
	end
	if circle.set and circle.state ~= "unset" then
		Clear(circle)
	end
	return false
end

-- Something carried from another circle, landing on this one.
--
-- A hole is not copied. The contract has a call that puts a link in a slot and
-- one that takes a slot back to unset, and none that puts a deliberate hole
-- somewhere else, so a circle carrying one lands with nothing to say and the
-- slot it came from keeps it. That refusal costs nothing and the alternative
-- was inventing a write nothing else in the addon makes.
local function Took(circle, thing)
	if type(thing) ~= "table" or type(thing.link) ~= "string" then
		return false
	end
	Put(circle, thing.link)
	return true
end

-- The hover, built from the link the set saved rather than from anything you
-- are wearing. That is the point of holding the link at all: the piece this
-- circle names may be in the bank, on another character's mail or three zones
-- away, and it still reads.
--
-- The set's name is the title, so the first line of the box says which of the
-- three circles under the cursor is being described, which at eighteen pixels
-- apart is not otherwise obvious.
--
-- And what the buttons do, because nothing on the page says. The user's words
-- for the state below and the gesture that reaches it were that there was no
-- way to do either, and there was: a sixteen pixel disc has no room for a label
-- and the hover is the only place on this page a sentence fits.
local function Gestures(state)
	local lines = { { "Click saves what you are wearing here.", color = C.dim } }
	if state == "empty" then
		lines[#lines + 1] = { "Right click unsets the slot, and the set leaves it alone.",
			color = C.dim }
	else
		lines[#lines + 1] = { "Right click empties the slot, and the set takes the piece off.",
			color = C.dim }
	end
	if state ~= "unset" then
		lines[#lines + 1] = { "Drag it onto another circle to copy it, or off the row to unset it.",
			color = C.dim }
	end
	return lines
end

local function Entered(circle)
	if not circle.set then
		return false
	end
	local lines = Gestures(circle.state)
	local subject
	if circle.link then
		subject = { kind = "item", link = circle.link, title = circle.set,
			lines = lines }
	else
		table.insert(lines, 1, {
			circle.state == "empty" and "left empty on purpose" or "not saved",
			color = C.dim })
		subject = { kind = "note", title = circle.set, lines = lines }
	end
	-- Over the circle rather than beside it, which is what anything smaller
	-- than the cursor has to ask for.
	ns.Tip.Open(circle, subject, "worn", true)
	return true
end

-- One circle, built on the first repaint that has a set to draw in it.
--
-- Built late and never again, which is the bargain the cooldown arc on this
-- page already strikes. Three circles on each of twenty rows is sixty buttons
-- and a hundred and eighty textures, and on a character with no sets every one
-- of them would be built at login to be hidden forever.
local function Circle(box, index)
	local entry = box.entry
	local near = entry.side == "right" and "RIGHT" or "LEFT"
	local sign = entry.side == "right" and -1 or 1

	local circle = CreateFrame("Button", nil, box)
	circle:SetSize(DISC, DISC)
	-- One point and not two, for the reason the socket discs take one: a disc
	-- pinned at two corners takes its size from the anchors rather than from
	-- SetSize, and comes out an ellipse.
	circle:SetPoint("TOP" .. near, box.note, "BOTTOM" .. near,
		sign * (index - 1) * LANE, -2)
	-- Over the row, and the row has its own level by now. A frame takes its
	-- parent's level when it is made, and the page raises every row over the
	-- figure after the rows are built, so a circle made at build would have sat
	-- under the model with the cursor going to the model rather than to it.
	circle:SetFrameLevel(box:GetFrameLevel() + 1)
	circle:SetHitRectInsets(-REACH, -REACH, -REACH, -REACH)
	-- Both buttons, named rather than left at "Any". The right one is the cycle
	-- below and the two are all this circle answers: a thumb button registered
	-- here would arrive at the same handler as a left click, because OnClick
	-- tells them apart by name and every name it is not given is a capture.
	UI.Press.Clicks(circle, "up", "LeftButton", "RightButton")

	circle.ring = UI.Disc(circle, "OVERLAY")
	circle.ring:SetAllPoints()

	circle.art = UI.Clip(UI.Icon(circle, "OVERLAY"))
	circle.art:SetPoint("TOPLEFT", RIM, -RIM)
	circle.art:SetPoint("BOTTOMRIGHT", -RIM, RIM)

	circle.bar = ns.Fill(circle, "OVERLAY", C.text[1], C.text[2], C.text[3], 1)
	circle.bar:SetSize(DISC - RIM * 2, BAR)
	circle.bar:SetPoint("CENTER")

	circle.slot = entry.slot
	circle:SetScript("OnClick", function(self, button)
		UI.CloseDropdown()
		if button == "RightButton" then
			return Cycled(self)
		end
		return Clicked(self)
	end)
	circle:SetScript("OnReceiveDrag", function(self) Dropped(self) end)
	circle:RegisterForDrag("LeftButton")
	circle:SetScript("OnDragStart", function(self) Grabbed(self) end)
	circle:SetScript("OnDragStop", function(self) Released(self) end)
	UI.Carry.Target(circle, function(thing) Took(circle, thing) end)
	circle:SetScript("OnEnter", Entered)
	circle:SetScript("OnLeave", function() ns.Tip.Close() end)
	return circle
end

-- One circle told which set it is drawing and what that set says about this
-- slot.
--
-- The worn link is handed in rather than read again: the repaint above has it
-- already, and it goes straight through to the store, which answers whether the
-- set's piece is the piece on the disc above. A circle repeating that picture
-- at full strength would draw the eye to the one row with nothing to say.
local function PaintCircle(circle, name, worn)
	local state, link, on = Entry(name, circle.slot, worn)
	circle.set, circle.state, circle.link = name, state or "unset", link or nil

	local icon = link and select(2, ns.ItemInfo(link)) or nil
	circle.art:SetTexture(icon)
	circle.art:SetShown(icon and true or false)
	circle.art:SetAlpha(on and M.rest or 1)
	circle.bar:SetShown(circle.state == "empty")

	-- The ring carries the piece's own grade where there is a piece, which is
	-- the colour the disc above it is wearing, and the panel's edge where there
	-- is not. Half strength for a slot nobody has told the set about, which is
	-- the same difference the socket discs draw between a gem and a hole.
	local tone = link and UI.Quality[ns.ItemValue(link) or 1] or C.edge
	local alpha = 1
	if circle.state == "unset" then
		alpha = 0.5
	elseif on then
		alpha = M.rest
	end
	circle.ring:SetVertexColor(tone[1], tone[2], tone[3], alpha)
	circle:Show()
	return circle.state
end

-- One row's circles, on the repaint that drew the row.
--
-- Answers how many are showing, which is nothing on an inspect page, nothing
-- on the ammo row and nothing at all on a character with no sets.
function SetRow.Paint(box, worn)
	local pane = box.pane
	local sets = Listed(pane)
	local count = math.min(#sets, MOST)
	if box.entry.ammo then
		count = 0
	end
	-- And a row that has never had one leaves without a table to its name,
	-- which is the twenty rows of a character with no sets.
	if count == 0 and not box.circles then
		return 0
	end

	box.circles = box.circles or {}
	for index = 1, MOST do
		local circle = box.circles[index]
		if index <= count then
			circle = circle or Circle(box, index)
			box.circles[index] = circle
			PaintCircle(circle, sets[index].name, worn)
		elseif circle then
			circle:Hide()
		end
	end
	return count
end

--------------------------------------------------------------------------
-- The toggles
--
-- A stack at the top left of the page, mirroring the four badges at the top
-- right. Who you are on the right, what you are dressed for on the left.
--------------------------------------------------------------------------

-- The picture for a talent group is ns.SpecArt, in Core, because asking the
-- client whether it has a call is a probe and only Core/ may hold one. What is
-- left here is the fallback under it.

-- And the fallback, which is a picture off the set itself. A resist set and a
-- PvP set are real sets with no spec behind them, so this is the ordinary case
-- rather than the broken one: the first piece the set names is as good an
-- emblem as a list of nineteen has.
local function PieceArt(name)
	for slot = 1, SLOTS do
		local state, link = Entry(name, slot)
		if state == "item" and link then
			local _, icon = ns.ItemInfo(link)
			if icon then
				return icon
			end
		end
	end
	return nil
end

-- A toggle pressed.
--
-- One call, and the store decides which of the two it is. A set that follows
-- the talent group you are not standing in is a talent switch and then a change
-- of clothes, in that order and never together; a set with no group, or one
-- whose group you are already in, is just the clothes. That rule lived here
-- while the slash word did it differently, which is one sentence with two
-- readings, and it is Sets.Press now.
local function Pressed(toggle)
	local set = toggle.set
	if not set then
		return SetRow.Make()
	end
	local ok, why = ns.Sets.Press(set.name)
	if not ok and why then
		ns.Print(why)
	end
	return ok and true or false
end

-- A toggle right clicked: everything you have on, into that set.
--
-- The gesture the feature shipped without. A set is a photograph and there was
-- no way to take it again from the page: the circles edit one slot each, so
-- bringing a nineteen slot set up to date with the gear you are standing in was
-- nineteen clicks, and the only re-take anywhere was `/wui set save` typed on a
-- name that already existed.
--
-- It says what it did, because a gesture that rewrites nineteen slots in
-- silence is a gesture nobody presses twice. The circles under the rows say the
-- same thing in pictures a moment later, and the line is what makes it
-- deliberate rather than something that happened.
local function Refilled(toggle)
	local set = toggle.set
	if not set then
		return false
	end
	local ok, why = Capture(set.name)
	if not ok then
		ns.Print(why)
		return false
	end
	ns.Print(("saved what you have on into %q."):format(set.name))
	return true
end

-- A toggle shift right clicked: that set forgotten, with a question in front
-- of it.
--
-- The gesture the page shipped without. A set could be made here and only
-- dropped with `/wui set forget <name>`, a command nothing on the page
-- mentions, which is the same hole the empty toggle was made to close.
--
-- Shift and the right button, not a dropdown. The two obvious buttons are spent
-- -- left wears the set and right re-takes it -- and shift is already the
-- modifier this page uses for a second reading on a hover, so it is the
-- modifier a second reading of a press belongs on. A dropdown buys room for
-- rename and "follow this spec" as well, and that is the shape to reach for the
-- moment a third thing wants a home on a toggle; it is more window than one
-- gesture needs today.
--
-- A light confirm and not a scary one, because the store takes a snapshot on
-- the way out and the question says so.
local function Forgotten(toggle)
	local set = toggle.set
	if not set then
		return false
	end
	local name = set.name
	UI.Ask({
		title = "forget a set",
		question = ("Forget %q? set undo puts it back."):format(name),
		accept = "forget it",
		onAccept = function()
			local ok, why = Forget(name)
			ns.Print(ok and ("forgot %q. set undo puts it back."):format(name) or why)
		end,
	})
	return true
end

-- The start of a drag off a toggle, which is how a set gets onto a bar.
--
-- Through UI/Carry.lua and never the client's cursor, for the reason a circle
-- goes that way: there is nothing about a set the client's cursor has a kind
-- for, and a piece of gear riding the real cursor is one misplaced release away
-- from being equipped or dropped on the ground. What lands on an ad hoc bar is
-- a macro square whose one line is the same line you would paste into a
-- Blizzard macro.
local function Carried(toggle)
	local set = toggle.set
	if not set then
		return false
	end
	UI.Carry.Lift({ kind = "set", name = set.name, icon = toggle.art:GetTexture() },
		toggle.art:GetTexture())
	return true
end

-- What a toggle says to a hover.
--
-- The stack draws a picture, a name and an accent, and none of the three says
-- that the right button does anything. Neither did anything else: the user went
-- looking for a way to re-take a set and reported that there was none, which is
-- what an undiscoverable gesture and a missing one look like from the outside.
local function ToggleSays(toggle)
	local set = toggle.set
	if not set then
		return { kind = "note", title = MAKE, lines = {
			{ "Click asks for a name, and whether the set starts from what you are wearing.",
				color = C.dim } } }
	end
	local lines = {}
	if set.group then
		lines[#lines + 1] = { ("Worn for talent group %d."):format(set.group),
			color = C.dim }
	end
	lines[#lines + 1] = { "Click puts it on.", color = C.dim }
	lines[#lines + 1] = { "Right click saves everything you are wearing into it.",
		color = C.dim }
	lines[#lines + 1] = { "Shift right click forgets it.", color = C.dim }
	-- The line itself, because Blizzard's own bars hold spells, items and macros
	-- and nothing an addon can invent. Drag the toggle onto one of your own bars
	-- and it lands as a macro square carrying this; for one of theirs, this is
	-- what goes in the macro.
	lines[#lines + 1] = { "Drag it onto a bar of your own, or put this in a macro:",
		color = C.dim }
	lines[#lines + 1] = { ns.Sets.Line(set.name), color = C.text }
	return { kind = "note", title = set.name, lines = lines }
end

-- One toggle, built on the first repaint that has a set for it. Grown and
-- never shrunk, which is the same bargain a circle strikes: a player with two
-- sets builds two of these forever and a third is built the day it is saved.
local function Toggle(stack, index)
	local toggle = CreateFrame("Button", nil, stack)
	toggle:SetHeight(TOGGLE)
	toggle:SetPoint("TOPLEFT", stack, "TOPLEFT", 0, -(index - 1) * (TOGGLE + AIR))
	toggle:SetPoint("RIGHT", stack, "RIGHT")
	UI.Press.Clicks(toggle, "up", "LeftButton", "RightButton")

	toggle.ring = UI.Disc(toggle, "BACKGROUND")
	toggle.ring:SetSize(TOGGLE, TOGGLE)
	toggle.ring:SetPoint("TOPLEFT")

	-- Inset the way a gear disc is inset, so a band of the ring shows all the
	-- way round the picture and the accent below has somewhere to land.
	toggle.art = UI.Clip(UI.Icon(toggle, "ARTWORK"))
	toggle.art:SetPoint("TOPLEFT", 3, -3)
	toggle.art:SetPoint("BOTTOMRIGHT", toggle.ring, "BOTTOMRIGHT", -3, 3)

	-- Built on every toggle and not only on the last one, because which toggle
	-- is the empty one moves: saving a set turns the third into that set's and
	-- makes the fourth the empty one, and a mark that only the last toggle owned
	-- would be a mark on the wrong disc from then on.
	toggle.plus = {
		ns.Fill(toggle, "ARTWORK", C.text[1], C.text[2], C.text[3], 1),
		ns.Fill(toggle, "ARTWORK", C.text[1], C.text[2], C.text[3], 1),
	}
	toggle.plus[1]:SetSize(MARK, BAR)
	toggle.plus[2]:SetSize(BAR, MARK)
	for mark = 1, 2 do
		toggle.plus[mark]:SetPoint("CENTER", toggle.ring, "CENTER")
		toggle.plus[mark]:Hide()
	end

	toggle.name = UI.Label(toggle, M.font, C.text, "LEFT", UI.SHADOW)
	UI.Wrap(toggle.name, false)
	toggle.name:SetPoint("LEFT", toggle.ring, "RIGHT", M.gutter, 0)
	toggle.name:SetPoint("RIGHT", toggle, "RIGHT")

	toggle:SetScript("OnClick", function(self, button)
		UI.CloseDropdown()
		if button == "RightButton" then
			return IsShiftKeyDown() and Forgotten(self) or Refilled(self)
		end
		return Pressed(self)
	end)
	-- The drag that takes a set off this page and onto a bar. The client's
	-- cursor stays empty the whole way, so a release anywhere but on a square
	-- that takes one is a release that did nothing.
	toggle:RegisterForDrag("LeftButton")
	toggle:SetScript("OnDragStart", function(self) Carried(self) end)
	toggle:SetScript("OnDragStop", function() UI.Carry.Land() end)
	-- Beside the stack rather than over it, unlike a circle: a toggle is
	-- thirty-six pixels and the cursor is not standing on the whole of it.
	toggle:SetScript("OnEnter", function(self)
		ns.Tip.Open(self, ToggleSays(self), "worn")
	end)
	toggle:SetScript("OnLeave", function() ns.Tip.Close() end)
	return toggle
end

-- One toggle wearing a set, and whether it is the one you have on.
--
-- The active one takes the accent and the rest sit at rest, which is one
-- question answered in one glance: a page open on a character whose talents
-- say fury and whose clothes say prot is a page with a lit toggle that is not
-- the one the figure is wearing.
local function PaintToggle(toggle, set, active)
	toggle.set = set
	toggle.art:SetTexture(ns.SpecArt(set.group) or PieceArt(set.name))
	toggle.art:Show()
	toggle.plus[1]:Hide()
	toggle.plus[2]:Hide()
	toggle.name:SetText(set.name)

	local on = active ~= nil and active.name == set.name
	local tone = on and C.accent or C.edge
	toggle.ring:SetVertexColor(tone[1], tone[2], tone[3], on and 1 or M.rest)
	toggle.name:SetTextColor(on and C.text[1] or C.dim[1],
		on and C.text[2] or C.dim[2], on and C.text[3] or C.dim[3])
	toggle.art:SetAlpha(on and 1 or M.rest)
	toggle:Show()
end

-- The one at the foot of the stack, which is not a set.
--
-- Never lit, because there is nothing to be wearing. It is the ring the others
-- are and the plus instead of a picture, so the stack still reads as one
-- column and the odd one out is obvious at the same glance.
local function PaintMaker(toggle)
	toggle.set = nil
	toggle.art:SetTexture(nil)
	toggle.art:Hide()
	toggle.plus[1]:Show()
	toggle.plus[2]:Show()
	toggle.name:SetText(MAKE)
	toggle.ring:SetVertexColor(C.edge[1], C.edge[2], C.edge[3], M.rest)
	toggle.name:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
	toggle:Show()
end

-- The stack again.
--
-- Answers how many sets there are rather than how many toggles were drawn,
-- because the empty one is not a set and every caller of this is asking about
-- sets.
function SetRow.PaintStack(stack)
	if not stack then
		return 0
	end
	-- Through the page's own answer rather than the store's, which is the same
	-- list: a stack only exists on your own sheet.
	local sets = Listed(stack.pane)
	local active = ns.Sets.Active()
	for index = 1, #sets do
		local toggle = stack.toggles[index] or Toggle(stack, index)
		stack.toggles[index] = toggle
		PaintToggle(toggle, sets[index], active)
	end

	-- And the empty one under them, drawn on a page with no sets as well as on
	-- one with four. That is the whole of how a set gets made from the page:
	-- before it there was a stack that drew nothing until you had already saved
	-- something at the slash prompt, which is a feature you had to be told about
	-- to find.
	local last = #sets + 1
	stack.toggles[last] = stack.toggles[last] or Toggle(stack, last)
	PaintMaker(stack.toggles[last])
	for index = last + 1, #stack.toggles do
		stack.toggles[index]:Hide()
	end
	return #sets
end

-- The page told that a set was written.
--
-- The count is compared rather than the page simply laid out again, because
-- every write comes through here: a click on a circle is a write, and laying
-- twenty rows out and resizing the window for each one would be the page
-- flinching every time you saved a bracer. The layout only has an answer to
-- change when the number of sets crosses one, which is the number the row
-- height and the crown are both read off.
local counted = nil

local function Wrote(pane)
	local count = #Listed(pane)
	if count ~= counted then
		counted = count
		-- Refused in a fight, and that refusal is the right one: sizing the
		-- frame twenty secure buttons hang off is a protected act, and
		-- Character/Window.lua already books it for the end of the fight.
		ns.CharWindow.Fit()
	end
	return pane:Paint()
end

-- The stack, and the standing offer to be told when anything about a set
-- changes. Nil on an inspect page, which is what the page reads as "there is
-- no stack here" everywhere it places one.
function SetRow.Stack(pane, parent, level)
	if pane.inspect then
		return nil
	end
	local stack = CreateFrame("Frame", nil, parent)
	stack:SetFrameLevel(level)
	stack.toggles = {}
	stack.pane = pane
	counted = nil
	ns.Sets.Watch(function() return Wrote(pane) end)
	return stack
end

-- Where the page puts it: over the left column, as wide as that column so a
-- set's name is read on the same line an item's name is, and as tall as its
-- own toggles. The gutter under the stack is the stack's and comes off here
-- rather than being a number the layout has to remember.
--
-- Answers whether there was one, so the page can place it with one line and no
-- test of its own for a sheet that is somebody else's.
function SetRow.Place(stack, x, y, width)
	if not stack then
		return false
	end
	stack:ClearAllPoints()
	stack:SetPoint("TOPLEFT", stack:GetParent(), "TOPLEFT", x, -y)
	stack:SetSize(width, math.max(SetRow.Crown(stack.pane) - M.gutter, 1))
	return true
end

--------------------------------------------------------------------------
-- Making one
--
-- The window the empty toggle opens: a name, one question about what goes into
-- the set, and a button that is refused before the press rather than after it.
--
-- **Not UI.Ask.** Ask is a sentence answered yes or no. A text field and a tick
-- box bolted onto it would be two windows wearing one name, which is the
-- argument UI/Amount.lua's header already makes for being its own window.
--
-- **One question and one tick.** Whether the set starts from what you have on
-- is a yes and a no, so it is a box that is ticked or not and never two chips
-- to choose between. It is written as the positive, because a switch named for
-- what it does not do is a sentence read twice.
--
-- **One window, reused.** Every popup in this addon is built once and
-- repainted, for the reason UI/Widgets.lua's dropdown gives: this client cannot
-- destroy a frame, so a window built per press is a window leaked per press.
--------------------------------------------------------------------------

local NAMER = 248

-- What a control that cannot be pressed is painted, which is UI/Widgets.lua's
-- own number for a control it has disabled.
local REFUSED = 0.4

local namer = nil

-- The name in the field, trimmed, and the reason it cannot be saved.
--
-- Asked before the press and not by making the set. ns.Sets.New answers these
-- same two refusals, but it answers them by being called, and the call that
-- does not refuse has already written the set: a window that found out at the
-- accept would be a window saying "there is already a set called that" over
-- one it just made.
local function Wanted(typed)
	local name = (typed or ""):match("^%s*(.-)%s*$")
	if name == "" then
		return nil, "a set needs a name."
	end
	if ns.Sets.Get(name) then
		return nil, ("there is already a set called %q."):format(name)
	end
	return name
end

-- The window told what is in its field now, which is every keystroke.
--
-- The refusal is the line under the tick and the dimmed button together. Both
-- and not one: a button that is simply dead says you cannot press it and never
-- says why, and a line on its own is a sentence under a button that still
-- looks pressable.
local function Refresh()
	local name, why = Wanted(namer.field.edit:GetText())
	namer.note:SetText(why or "")
	namer.accept:SetAlpha(name and 1 or REFUSED)
	namer.accept:EnableMouse(name ~= nil)
	return name
end

local function Accept()
	local name = Refresh()
	if not name then
		return false
	end
	local record, why = ns.Sets.New(name)
	if not record then
		-- Both of the refusals this window draws were caught above, so what is
		-- left is the store: the saved variables are not up yet. That goes to
		-- the chat line rather than under the field, because there is nothing
		-- the player can retype to get past it.
		ns.Print(why)
		return false
	end
	local worn = namer.worn.on
	if worn then
		Capture(record.name)
	end
	namer.window:Hide()
	ns.Print(worn and ("saved what you have on as %q."):format(record.name)
		or ("made %q with nothing in it. a click on its circle under a row puts that slot in.")
			:format(record.name))
	return true
end

-- The one question the window asks besides the name.
--
-- Ticked when it opens, because the set you are making is nearly always the
-- clothes you are standing in and the empty one is the deliberate choice.
local function Worn(parent)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(M.control)
	UI.Press.Clicks(row, "up", "LeftButton")

	local box = UI.TickBox(row)
	box:SetPoint("LEFT")
	row.tick = box.tick

	row.text = UI.Label(row, M.font, C.text, "LEFT", UI.FLAT)
	row.text:SetPoint("LEFT", box, "RIGHT", M.gutter, 0)
	row.text:SetPoint("RIGHT")
	UI.Wrap(row.text, false)
	row.text:SetText("start from what you are wearing")

	row:SetScript("OnClick", function(self)
		self.on = not self.on
		self.tick:SetShown(self.on and true or false)
	end)
	return row
end

-- How tall it came out: the chrome, the field, the tick and the line under
-- them. Written as its pieces rather than as a number, so a metric moving
-- moves the window.
local function Tall()
	return M.title + M.footer + M.pad * 2 + M.control * 2 + M.rowGap * 2 + M.small
end

local function Built()
	if namer then
		return namer
	end
	local window = UI.Window({
		name = "WiggleUINewSet",
		title = "new set",
		width = NAMER,
		height = Tall(),
		-- Over the sheet that raised it, for the reason UI/Amount.lua asks for
		-- the same strata: every other window in the addon is on DIALOG.
		strata = "FULLSCREEN_DIALOG",
	})
	namer = { window = window }

	namer.field = UI.Field(window.content, {
		width = NAMER - M.pad * 2,
		onType = function() Refresh() end,
		-- Enter is this window's accept rather than a commit. UI/Widgets.lua
		-- commits a field by clearing its focus, and a field that did both ran
		-- the thing behind it twice on one press, which is what item 44 was.
		onEnter = function() Accept() end,
	})
	namer.field:SetPoint("TOPLEFT", M.pad, -M.pad)

	-- Escape closes the window rather than only stepping out of the field. The
	-- window's name is in UISpecialFrames either way, but a focused field takes
	-- the first press, and a dialog you have to press escape at twice reads as
	-- stuck.
	namer.field.edit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		window:Hide()
	end)

	namer.worn = Worn(window.content)
	namer.worn:SetPoint("TOPLEFT", M.pad, -(M.pad + M.control + M.rowGap))
	namer.worn:SetPoint("RIGHT", -M.pad, 0)

	namer.note = UI.Label(window.content, M.small, C.dim, "LEFT", UI.FLAT)
	namer.note:SetPoint("TOPLEFT", M.pad, -(M.pad + M.control * 2 + M.rowGap * 2))
	namer.note:SetWidth(NAMER - M.pad * 2)
	UI.Wrap(namer.note, false)

	namer.accept = UI.Button(window.footer, { label = "save", width = 92,
		tone = C.accent, onClick = function() Accept() end })
	namer.accept:SetPoint("RIGHT", 0, 0)

	namer.refuse = UI.Button(window.footer, { label = "cancel", width = 76,
		onClick = function() window:Hide() end })
	namer.refuse:SetPoint("RIGHT", namer.accept, "LEFT", -M.rowGap, 0)
	return namer
end

-- The empty toggle pressed.
--
-- The spec you are standing in is already in the field and already selected, so
-- the player who wanted that name presses enter and the one who did not types
-- over it without reaching for backspace. A character with no spec resolved
-- gets an empty field, which is the same window with one more word to type.
function SetRow.Make()
	local window = Built().window
	namer.field.edit:SetText(ns.Class.Spec.Label() or "")
	namer.worn.on = true
	namer.worn.tick:SetShown(true)
	Refresh()
	-- Shown before the focus, because a field inside a hidden frame gives the
	-- keyboard straight back.
	window:Show()
	namer.field.edit:SetFocus()
	namer.field.edit:HighlightText()
	return true
end

-- The window on the screen now, or nothing. Public for the reason UI.Amounting
-- is: the page can tell whether the player has dealt with it, and a test reads
-- it without naming its frames.
function SetRow.Naming()
	if namer and namer.window:IsShown() then
		return namer
	end
	return nil
end
