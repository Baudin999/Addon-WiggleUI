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
-- last two are opposite intentions, so they are drawn as far apart as ten
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
-- cursor. A drag off empties it. Between two circles the thing being carried
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

-- The circle, and how far apart two of them sit. Ten and not twelve, which is
-- what a socket disc is: the sockets are read across a row and these are read
-- down a column, and the column is twenty rows long.
local DISC = 10
local LANE = DISC + 2

-- How much of the circle the ring keeps for itself, which leaves six pixels of
-- picture. Small, and it is enough: what a circle is read for down a column is
-- whether there is a picture in it at all.
local RIM = 2

-- How far past the circle the mouse still answers, which makes a sixteen pixel
-- target out of a ten pixel disc. A hit rect and not a bigger button, the way
-- the ammo row widens itself: the picture is the size it wants to be and the
-- target is the size a cursor needs.
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
-- which by drawing one at thirty-six and the other at ten.
local TOGGLE = 36
local AIR = 4

-- The trees a talent group has, for a client that will not say. Three on both
-- clients this addon runs on, and it has been three since the game shipped.
local TREES = 3

-- What is drawn where a set has nothing. Read once rather than measured: a bar
-- two pixels thick is the thinnest mark that is still a mark on a disc this
-- small.
local BAR = M.hairline * 2

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
-- Nothing at one set and nothing at none, which is the promise this feature
-- made to everybody who does not use it: a page with one set on it is the page
-- that shipped, to the pixel. One circle under a row answers no question
-- either, because the question this line is for is which of your sets
-- disagrees with what you have on, and that takes two.
function SetRow.Band(pane)
	return #Listed(pane) > 1 and LANE or 0
end

-- How much of the top of the page the toggles take.
--
-- Off the crown rather than out of the rows' own air, because the rows are
-- centred on what is left and the figure stands on their block: a stack drawn
-- over the top of the page without this would be a stack laid across the first
-- two rows of the left column, which is a mouse fight with two secure squares.
function SetRow.Crown(pane)
	local count = #Listed(pane)
	if count == 0 then
		return 0
	end
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

-- A click, which is the gesture a set is actually built with: whatever is in
-- that slot right now goes into that set. Holding something on the cursor
-- makes it the drop instead, because that is what every square in the game
-- does with a click while your hand is full and a square that refused would
-- read as broken.
local function Clicked(circle)
	local kind, _, link = GetCursorInfo()
	if kind == "item" and type(link) == "string" then
		ns.Sets.Put(circle.set, circle.slot, link)
		ClearCursor()
		return true
	end
	ns.Sets.Capture(circle.set, circle.slot)
	return true
end

-- A piece dragged out of a bag and let go over the circle.
local function Dropped(circle)
	local kind, _, link = GetCursorInfo()
	if kind ~= "item" or type(link) ~= "string" then
		return false
	end
	ns.Sets.Put(circle.set, circle.slot, link)
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
		ns.Sets.Clear(circle.set, circle.slot)
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
	ns.Sets.Put(circle.set, circle.slot, thing.link)
	return true
end

-- The hover, built from the link the set saved rather than from anything you
-- are wearing. That is the point of holding the link at all: the piece this
-- circle names may be in the bank, on another character's mail or three zones
-- away, and it still reads.
--
-- The set's name is the title, so the first line of the box says which of the
-- three circles under the cursor is being described, which at ten pixels apart
-- is not otherwise obvious.
local function Entered(circle)
	if not circle.set then
		return false
	end
	local subject
	if circle.link then
		subject = { kind = "item", link = circle.link, title = circle.set }
	else
		subject = { kind = "note", title = circle.set, lines = { {
			circle.state == "empty" and "left empty on purpose" or "not saved",
			color = C.dim } } }
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
	UI.Press.Clicks(circle, "up", "LeftButton")

	circle.ring = UI.Disc(circle, "OVERLAY")
	circle.ring:SetAllPoints()

	circle.art = UI.Clip(UI.Icon(circle, "OVERLAY"))
	circle.art:SetPoint("TOPLEFT", RIM, -RIM)
	circle.art:SetPoint("BOTTOMRIGHT", -RIM, RIM)

	circle.bar = ns.Fill(circle, "OVERLAY", C.text[1], C.text[2], C.text[3], 1)
	circle.bar:SetSize(DISC - RIM * 2, BAR)
	circle.bar:SetPoint("CENTER")

	circle.slot = entry.slot
	circle:SetScript("OnClick", function(self)
		UI.CloseDropdown()
		Clicked(self)
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
-- The worn link is handed in rather than read again. The repaint above has it
-- already, and the one comparison this line is for is against exactly that:
-- the same link means the set's piece is the piece on the disc above, and a
-- circle repeating the picture at full strength would draw the eye to the one
-- row that has nothing to say.
local function PaintCircle(circle, name, worn)
	local state, link = ns.Sets.Entry(name, circle.slot)
	circle.set, circle.state, circle.link = name, state or "unset", link or nil

	local icon = link and select(2, ns.ItemInfo(link)) or nil
	local on = link ~= nil and link == worn
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
-- on the ammo row and nothing at all until there are two sets to disagree.
function SetRow.Paint(box, worn)
	local pane = box.pane
	local sets = Listed(pane)
	local count = #sets > 1 and math.min(#sets, MOST) or 0
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

-- The picture for a talent group, which the client will draw for a group you
-- are not standing in. That is the whole reason this is the icon a toggle
-- wears: you are pressing it to become the other thing, so it has to show the
-- other thing.
--
-- Which of the three trees is asked for is not on the set. A set names a
-- group, a group has three trees, and the tree worth showing is the one the
-- points are in, which is the seventh value of the same call.
--
-- Probed and pcalled the way Talents/Read.lua probes the same table: the
-- vanilla client has no C_SpecializationInfo at all, and a set that gets
-- nothing back falls through to one of its own pieces below.
local function SpecArt(group)
	local api = _G.C_SpecializationInfo
	if not group or type(api) ~= "table"
		or type(api.GetSpecializationInfo) ~= "function" then
		return nil
	end
	local tabs = type(_G.GetNumTalentTabs) == "function"
		and tonumber(_G.GetNumTalentTabs()) or TREES
	local best, art = -1, nil
	for tree = 1, tabs or TREES do
		local ok, _, name, _, icon, _, _, points = pcall(api.GetSpecializationInfo,
			tree, false, false, nil, nil, group)
		local spent = tonumber(points) or 0
		if ok and type(name) == "string" and spent > best then
			best, art = spent, icon
		end
	end
	return art
end

-- And the fallback, which is a picture off the set itself. A resist set and a
-- PvP set are real sets with no spec behind them, so this is the ordinary case
-- rather than the broken one: the first piece the set names is as good an
-- emblem as a list of nineteen has.
local function PieceArt(name)
	for slot = 1, SLOTS do
		local state, link = ns.Sets.Entry(name, slot)
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
-- Two calls and the set says which. A set that follows the talent group you
-- are not standing in is a talent switch and then a change of clothes, in that
-- order and never together: the talents are a cast and the gear is a round
-- trip to the server per piece, and running the two at once is how a set lands
-- half on. A set with no group, or one whose group you are already in, is just
-- the clothes.
local function Pressed(toggle)
	local set = toggle.set
	if not set then
		return false
	end
	if set.group and set.group ~= ns.Class.Spec.Group() then
		return ns.Sets.Swap(set.group)
	end
	local ok, why = ns.Sets.Wear(set.name)
	if not ok and why then
		ns.Print(why)
	end
	return ok and true or false
end

-- One toggle, built on the first repaint that has a set for it. Grown and
-- never shrunk, which is the same bargain a circle strikes: a player with two
-- sets builds two of these forever and a third is built the day it is saved.
local function Toggle(stack, index)
	local toggle = CreateFrame("Button", nil, stack)
	toggle:SetHeight(TOGGLE)
	toggle:SetPoint("TOPLEFT", stack, "TOPLEFT", 0, -(index - 1) * (TOGGLE + AIR))
	toggle:SetPoint("RIGHT", stack, "RIGHT")
	UI.Press.Clicks(toggle, "up", "LeftButton")

	toggle.ring = UI.Disc(toggle, "BACKGROUND")
	toggle.ring:SetSize(TOGGLE, TOGGLE)
	toggle.ring:SetPoint("TOPLEFT")

	-- Inset the way a gear disc is inset, so a band of the ring shows all the
	-- way round the picture and the accent below has somewhere to land.
	toggle.art = UI.Clip(UI.Icon(toggle, "ARTWORK"))
	toggle.art:SetPoint("TOPLEFT", 3, -3)
	toggle.art:SetPoint("BOTTOMRIGHT", toggle.ring, "BOTTOMRIGHT", -3, 3)

	toggle.name = UI.Label(toggle, M.font, C.text, "LEFT", UI.SHADOW)
	UI.Wrap(toggle.name, false)
	toggle.name:SetPoint("LEFT", toggle.ring, "RIGHT", M.gutter, 0)
	toggle.name:SetPoint("RIGHT", toggle, "RIGHT")

	toggle:SetScript("OnClick", function(self)
		UI.CloseDropdown()
		Pressed(self)
	end)
	return toggle
end

-- The stack again, and which of them is lit.
--
-- The active one takes the accent and the rest sit at rest, which is one
-- question answered in one glance: a page open on a character whose talents
-- say fury and whose clothes say prot is a page with a lit toggle that is not
-- the one the figure is wearing.
function SetRow.PaintStack(stack)
	if not stack then
		return 0
	end
	local sets = ns.Sets.All()
	local active = ns.Sets.Active()
	for index = 1, #sets do
		local set = sets[index]
		local toggle = stack.toggles[index] or Toggle(stack, index)
		stack.toggles[index] = toggle
		toggle.set = set
		toggle.art:SetTexture(SpecArt(set.group) or PieceArt(set.name))
		toggle.name:SetText(set.name)

		local on = active ~= nil and active.name == set.name
		local tone = on and C.accent or C.edge
		toggle.ring:SetVertexColor(tone[1], tone[2], tone[3], on and 1 or M.rest)
		toggle.name:SetTextColor(on and C.text[1] or C.dim[1],
			on and C.text[2] or C.dim[2], on and C.text[3] or C.dim[3])
		toggle.art:SetAlpha(on and 1 or M.rest)
		toggle:Show()
	end
	for index = #sets + 1, #stack.toggles do
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
