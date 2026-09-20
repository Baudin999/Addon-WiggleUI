local ADDON, ns = ...

local UI = ns.UI
local C, M = UI.Color, UI.Metric

local Grid = {}
ns.BagsGrid = Grid

--------------------------------------------------------------------------
-- The squares
--
-- One button per bag slot, drawn where the pile it belongs to puts it. The
-- pool never shrinks and a square is reassigned to whatever slot lands on it
-- this pass, which is what lets a hundred and fifty of them be laid out again
-- for the price of a hundred and fifty anchors.
--
-- **What a square looks like is UI/Slot.lua's.** The sunken ground, the
-- hairline in the item's own grade, the crisp icon and the count in the corner
-- are the same in the merchant window, and one of them differing by a pixel
-- when the two are open beside each other is why that file exists. What is left
-- here is everything that is a fact about a bag slot and about nothing else.
--
-- **The button is the client's own template and that is the whole design.**
-- `ContainerFrameItemButtonTemplate` is what every bag button in the game is
-- built on, Blizzard's and every addon's, and inheriting it means the click, the
-- drag, the stack split, the shift-link and the merchant sale are the client's
-- code rather than ours. None of that is reimplementable: a right click on a
-- bag slot means eat, equip, open, sell or attach depending on which window is
-- in front of you, and the rules for which are inside the client. That is the
-- one thing the merchant window's rows do not do and do not want: buying is one
-- call with one meaning.
--
-- It also keeps that click secure, which is the only way a right click on a
-- scroll reads it: `C_Container.UseContainerItem` is protected, and the
-- template's own OnClick is the only path to it this addon has. So the OnClick
-- is never set here. Mail/Bags.lua wants the right button while the mail
-- window is open, and it takes it through Bags.Dress, which registers the
-- square for the left button alone and hangs an OnMouseUp on it; both are
-- widget settings and taint nothing. A square is dressed once when built, so
-- one born with the mail window open arrives already knowing.
--
-- **A slot is its own id and its bag is its parent's.** That is where the
-- client keeps it and the only thing the template's own handlers have to go on,
-- so every square is parented to a holder frame carrying the bag number. The
-- holders are all the size of the canvas, so a square is anchored inside its
-- own parent and the layout never has to know which holder it landed in.
--
-- **Three piles are drawn in two lanes.** Weapons and armour are the only
-- things you carry that bind, so they are the only piles where "already mine"
-- and "still worth something to somebody else" is a division you can make.
-- The quest pile divides the same way on a different fact: what a quest in
-- your log still wants, and what nothing in it wants. Yours on the left,
-- not on the right, half a square of air between them, and each lane wraps
-- inside its own width. Which piles split, and on what, is
-- Core/Piles.lua's; which lane a square is in is Bags/Bags.lua's, written on
-- the entry as `yours`; how wide a lane is and where the second one starts
-- are here, because they are drawing.
--
-- Every pile, split or not, spends the same half square of air after it, and
-- the window carries that much air at its right edge: that is what Grid.Width
-- adds. A window as wide as the widest pile in it is a window that changes
-- width when you pick up a sword.
--
-- **A line is balanced before it is broken.** Piles flow left to right. When
-- the next pile will not fit beside the ones already on the line, every pile
-- on the line is allowed one more row and the line is measured again, and the
-- new pile only starts the next line once none of them may grow any taller. A
-- big pile and a small one share a line as two blocks. Filling the line
-- greedily gave the big pile a strip the width of the window and pushed the
-- small one under it. See The flow below.
--
-- **Sections and rules break a line.** Core/Piles.lua hands this window three
-- kinds of row that are not piles: a section caption, Equipment over the
-- weapons and armour, in the small dim face; a rule, one pixel of the theme's
-- edge under the session and over the junk; and a plain break where a section
-- ends. Each ends the line being filled.
--
-- **While the window is open the layout holds still.** Selling a grey, eating
-- a potion or equipping a sword takes an item out of its pile, and a pile that
-- closes the gap moves every square after it, so a grid you were reading is a
-- grid you read again from the top after every click. The first paint after
-- the window opens lays the piles out and holds them; every paint after it
-- keeps each square where it is and asks the scan what is lying on its slot
-- now. A slot that emptied stays as an empty square, which is the placeholder
-- that keeps everything else in place. Shutting the window lets go, and the
-- next open closes the gaps. See Hold below for what breaks it early.
--
-- **The art is ours and the behaviour is theirs.** The template arrives dressed
-- for a window that looks nothing like this one, so UI.Undress sweeps every
-- region it brought and UI.Dress draws the square again in the addon's palette.
--
-- The cooldown frame is the one exception and it is exactly the shape of the
-- rule: it is stripped from nothing because nothing here draws a replacement,
-- and the client's own call is what fills it in.
--
-- The hover is the addon's own box for the same reason. A window drawn in this
-- palette with the client's tiled parchment opening over it is two designs on
-- one screen, which is the defect the addon's own box exists to stop.
--
-- **Nothing here hands the right button to the camera.** The right click on a
-- bag slot is the whole of eat, equip, open, sell, attach and put a stone on
-- your axe, and when the button was passed through every one of them went to
-- the camera instead. The price is the one named in UI/Press.lua: a right drag
-- begun on a square does not turn the camera. There are two pixels
-- between squares and a frame around the window, so there is somewhere on it to
-- start a drag; there is nowhere else to put a right click.
--------------------------------------------------------------------------

local SLOT, GAP, BREAK = UI.SLOT, UI.SLOT_GAP, UI.SLOT_BREAK
local LANE = UI.SLOT_LANE

-- The mark on a square a vendor will take, which is the same coin the loot
-- feed's money chip draws. Named rather than written at the call site because
-- scripts/bake-glyphs.sh is what decides which letter carries which mark, and a
-- literal `$` sitting in the middle of the layout gives nobody reading this file
-- a way to find that out.
local COIN = "$"

-- The pointer over something this vendor will pay for.
--
-- The client's own cursor, by the name its own bag buttons ask for. Blizzard's
-- ContainerFrameItemButton_OnEnter sets exactly this one over a slot while a
-- merchant is up, so a square in this window and a square in theirs read the
-- same at the same moment, and the coin under the pointer is the coin the
-- player already knows.
local BUY = "BUY_CURSOR"

local TEMPLATE = "ContainerFrameItemButtonTemplate"

local squares, holders, rules = {}, {}, {}
local canvas, headings
local inherited = true

-- The square whose pointer this file changed, or nothing.
--
-- Held rather than worked out again on the way off, because the cursor is one
-- thing on the screen and this file is not the only one that writes it. A
-- square that reset the pointer on every OnLeave would take back whatever the
-- cursor was doing for somebody else, and an empty slot in a bag has no
-- business saying anything about it.
local paying

-- A distance in this window's units, snapped to a whole number of pixels.
--
-- The window is drawn at a zoom, and a zoom of one and three tenths puts one
-- unit on one and three tenths of a pixel. A square whose top lands on a
-- fraction of a pixel has a one pixel hairline along that edge asking to be
-- drawn between two pixels, and the client draws it on one of them or on
-- neither depending on which fraction it got. What that looked like was every
-- bottom edge missing from one row of squares and every top edge missing from
-- the row below it, with the left and right edges of the same squares correct:
-- the columns happened to fall on a fraction the client draws and the rows on
-- one it does not.
--
-- So nothing in this grid is placed or sized in units. Every origin and the
-- side of every square goes through here, which puts every hairline on a pixel
-- of its own however the zoom divides. Rounded at layout rather than baked into
-- the constants because the answer is a fact about the frame: the same
-- thirty-one units is a different number of pixels at every zoom, and only the
-- canvas can say which. Asked of the canvas rather than of a square because the
-- squares inherit its scale and there is no square yet when the window first
-- asks how wide it should be.
local function Snap(distance)
	return UI.Round(canvas, distance)
end

-- The air between the two lanes, in whole pixels.
--
-- Named rather than snapped at the two call sites because the window's width is
-- built from it as well as the layout, and a window one pixel narrower than the
-- squares it holds is a window that clips its own right edge.
local function Gap()
	return Snap(LANE)
end

-- How wide a grid of this many columns is, which is the number the window sizes
-- itself off. UI/Slot.lua answers the squares and the gaps between them, because
-- the merchant window asks the same question of the same squares and two files
-- with the same arithmetic in them is how the two windows end up a pixel apart.
--
-- The lane gap is added on top and is paid by every pile whether or not it is
-- split. A pile drawn in two lanes spends it in the middle; every other pile
-- spends it as air at the right edge. That is what makes the two kinds of pile
-- end in the same place, and the alternative -- a window as wide as the widest
-- pile in it -- is a window that changes width when you pick up a sword.
function Grid.Width(columns)
	return UI.SlotSpan(columns) + Gap()
end

-- Whether this pile is drawn in two lanes at this width.
--
-- Two columns is the narrowest a split can be, one square a side. Below that
-- there is no division to draw, so a player who has wound the column setting
-- down to one gets an ordinary pile rather than a lane of nothing.
local function Splits(group, columns)
	return group.split == true and columns >= 2
end

--------------------------------------------------------------------------
-- Building one
--------------------------------------------------------------------------

-- The three strings a bag square carries that no other square in the addon does.
local function Extras(button)
	-- How many slots you have free, on the one square the empty pile folds
	-- into. Its own string rather than the tally in the corner, and in the
	-- middle of the square, because the two numbers are not the same kind of
	-- number: the tally is a fact about the item lying on the square and this is
	-- a fact about the square. A single free slot reads "1" in the centre, where
	-- the tally would have drawn nothing at all.
	button.free = UI.Label(button, M.font, C.dim, "CENTER", UI.FLAT)
	button.free:SetPoint("CENTER")
	UI.Wrap(button.free, false)

	-- The coin on a grey a vendor will take, in the corner the tally is not in.
	--
	-- It says one thing and it is not "this is junk": the pile heading over the
	-- square already says that. It says a merchant will pay for this, which the
	-- pile cannot, because a grey with no sell price on it is filed as junk like
	-- every other grey and is the one thing in that pile the sale will leave
	-- behind.
	button.coin = UI.Glyph(button, M.glyph, C.heading, "LEFT")
	button.coin:SetPoint("TOPLEFT", 3, -3)
	UI.Wrap(button.coin, false)
	button.coin:SetText(COIN)
	button.coin:Hide()

	-- How many of this the session recorded, in the corner the stack count and
	-- the coin are both not in.
	--
	-- Two numbers on one square is a thing to justify rather than a thing to
	-- do, and these two are genuinely different facts: the tally in the bottom
	-- corner is how many you are holding and this is how many arrived while you
	-- were recording. Eight Runecloth carried in and twelve looted is a square
	-- reading twenty at the bottom and twelve at the top, and there is no call
	-- on this client that could split the stack to make it read any other way.
	-- It is only ever drawn under a session heading, so what it counts is named
	-- one line above the square.
	--
	-- Outlined and at M.tally for the reason UI/Slot.lua gives its own number:
	-- it lands on art this addon did not paint.
	button.gained = UI.Label(button, M.tally, C.heading, "LEFT", UI.OUTLINE)
	button.gained:SetPoint("TOPRIGHT", -3, -3)
	UI.Wrap(button.gained, false)
	return button
end

-- What the box over a square says. Nothing at all for an empty one: a slot with
-- nothing in it has nothing to tell you, and a box that opens to say so is a box
-- that opens over every gap in the window.
local function Subject(button)
	if not button.link then
		return nil
	end
	-- The bag and the slot travel with the link, and they are what makes the
	-- binding line true. A link on its own says "Binds when picked up" about
	-- something you picked up months ago; the slot it is lying in says
	-- "Soulbound". See Head in UI/Tip.lua.
	return {
		kind = "item",
		link = button.link,
		title = button.name,
		count = button.count,
		bag = button.bag,
		slot = button.slot,
	}
end

-- The coin on the pointer, and off it again.
--
-- Both are guarded on which square is holding it, so the pointer is written
-- once on the way in and once on the way out however many times the client
-- calls the handlers, and a square that never changed it never resets it.
local function Take(button)
	if paying == button then
		return
	end
	paying = button
	SetCursor(BUY)
end

local function Give()
	if not paying then
		return
	end
	paying = nil
	ResetCursor()
end

local function Enter(button)
	button.told, button.toldCount = button.link, button.count
	UI.Tint(button.bg, C.control)
	-- The pointer says what the click would do, which at a vendor is sell this.
	-- The window already dims what the merchant refuses, and dimming is a fact
	-- about the whole grid you read at a glance. This is the answer for the one
	-- square you are actually pointing at.
	if button.sells then
		Take(button)
	end
	-- On the square. An item in a bag is a thing you are pointing at, and the
	-- corner of the screen is a long way from a grid of a hundred of them.
	--
	-- And only once the pointer has stopped on it. The way to any square is
	-- across a dozen others, and a box for each of them on the way is a box
	-- flickering across the window. The wait is the bag setting, in
	-- milliseconds because that is the size of number it is; UI/Tip.lua takes
	-- seconds like every other duration in the addon.
	ns.Tip.Settle(button, Subject(button), "bag", nil,
		(ns.db.bagHover or 0) / 1000)
end

local function Leave(button)
	button.told, button.toldCount = nil, nil
	UI.Tint(button.bg, C.sunken)
	if paying == button then
		Give()
	end
	ns.Tip.Close()
end

-- The bag's holder frame, made on first use.
--
-- Every one of them is the whole canvas, so which holder a square is parented
-- to changes nothing about where it is drawn. The frame exists to carry one
-- number, and it carries it because the client's own click handler reads the bag
-- off the parent and there is nowhere else to put it.
local function Holder(bag)
	local holder = holders[bag]
	if not holder then
		holder = CreateFrame("Frame", nil, canvas)
		holder:SetAllPoints()
		holder:SetID(bag)
		holders[bag] = holder
	end
	return holder
end

-- One square. Named, because a bag button is one of the frames the client and
-- other addons reach for by name, and because a square that has landed
-- somewhere wrong has to be findable from a macro.
local function Build(index)
	local made, button = pcall(CreateFrame, "Button",
		"WiggleUIBagSlot" .. index, canvas, TEMPLATE)
	-- A client with no such template is a client where the squares are still
	-- drawn and still say what is in them, and where a click does nothing.
	-- Recorded rather than raised, because the window is worth having either way
	-- and because the panel has to be able to say which of the two you have.
	if not made or type(button) ~= "table" then
		inherited = false
		button = CreateFrame("Button", "WiggleUIBagSlot" .. index, canvas)
	end

	button:SetSize(SLOT, SLOT)
	UI.Undress(button)
	UI.Dress(button, SLOT)
	Extras(button)
	button:SetScript("OnEnter", Enter)
	button:SetScript("OnLeave", Leave)
	-- The template refreshes its own box by calling this while the pointer is
	-- still on the square. Ours has to answer the same name or the client's would
	-- open underneath the addon's on the next refresh.
	button.UpdateTooltip = Enter
	ns.MailBags.Dress(button)
	return button
end

local function Square(index)
	local button = squares[index]
	if not button then
		button = Build(index)
		button.index = index
		squares[index] = button
	end
	return button
end

-- The box over the square under the pointer, brought up to date with the
-- square.
--
-- Equipping a sword off a square is the case this exists for: the old sword
-- lands in the slot, the repaint writes it onto a square, and the pointer has
-- not moved, so no OnEnter is coming. The template's own refresh does not cover
-- it either, because the client only calls UpdateTooltip on a button that owns
-- the client's own tooltip, and this box is not that tooltip.
--
-- Run once the whole layout is down rather than per square in Paint. A relayout
-- moves squares, and the square under the pointer after it is not always the
-- one that was under it before: asked before the move, the answer is a square
-- that is about to be somewhere else.
--
-- What the square last told the box is written in Enter and wiped in Leave, so
-- a square that slid under a still pointer has told nothing and is entered, and
-- a refresh that changed nothing asks the client once and does nothing.
local function Follow()
	local under = ns.MouseFocus()
	if type(under) ~= "table" or squares[under.index] ~= under then
		return
	end
	if under.told ~= under.link or under.toldCount ~= under.count then
		Enter(under)
	end
end

--------------------------------------------------------------------------
-- Filling one in
--------------------------------------------------------------------------

-- Whether the client's own cooldown call has answered so far. One refusal takes
-- it off for the session rather than being tried a hundred and fifty times a bag
-- update for the rest of the evening.
local sweeps = true

-- The swirl over a potion you just drank.
--
-- The client's own call, by name and guarded, because there is no other way to
-- it: the sweep is drawn on the frame the template brought with it, off a
-- reading of the slot that this addon has no equivalent for, and building a
-- second cooldown model beside the client's to redraw a circle is not a trade
-- worth making. It is also the one region the template carries that is not
-- stripped, for the same reason: nothing here draws a replacement.
--
-- A build with no such call, or one whose call refuses a button parented
-- somewhere it did not expect, loses the swirl and keeps the square.
local function Sweep(button, entry)
	if not sweeps or type(_G.ContainerFrame_UpdateCooldown) ~= "function" then
		return false
	end
	if type(button.Cooldown) ~= "table" then
		return false
	end
	if not pcall(_G.ContainerFrame_UpdateCooldown, entry.bag, button) then
		sweeps = false
		return false
	end
	return true
end

-- `counted` is the number drawn in the middle of the square, or nothing. It is
-- written on the squares an empty pile folded into, and
-- it is a number of free slots rather than a number of items: the caller says
-- which square that is, because on a held layout it is the square that was the
-- fold when the hold began and not whichever slot the scan sorted first.
local function Paint(button, entry, selling, counted)
	local free = entry.link == nil
	local sellable = ns.Bags.Sellable(entry)
	-- Dim while a merchant is open, and only then. What a vendor will not buy
	-- is a fact about this minute rather than about the item: a quest item you
	-- cannot sell is an ordinary square in a bag you opened to find something,
	-- and it is the one square in the way when you are standing at a vendor
	-- deciding what to be rid of. An empty slot is not refused, it is empty.
	local refused = selling and entry.link ~= nil and not sellable

	button.link, button.name, button.count = entry.link, entry.name, entry.count
	button.bag, button.slot = entry.bag, entry.slot
	UI.SlotPaint(button, entry.icon, not free and entry.count or nil,
		entry.quality, refused)
	button.free:SetText(counted and tostring(counted) or "")
	button.coin:SetShown(sellable and entry.group == ns.Bags.JUNK)
	button.gained:SetText(entry.gained and tostring(entry.gained) or "")

	button.sells = selling and sellable
	-- The square under the pointer just sold, so what is lying on it now is
	-- whatever the layout moved up into its place. The pointer follows the
	-- square rather than the item, and nothing else would take the coin off it.
	if paying == button and not button.sells then
		Give()
	end
	button:SetAlpha(refused and UI.SLOT_DIM or 1)

	-- Both guarded on what the square already answers, because on a held
	-- layout neither changes and this runs on every square ten times a second
	-- while a sale sweeps. SetParent is the dear one: it takes the frame out of
	-- one tree and puts it in another, and a square that was already there
	-- pays that for nothing.
	local holder = Holder(entry.bag)
	if button:GetParent() ~= holder then
		button:SetParent(holder)
	end
	if button:GetID() ~= entry.slot then
		button:SetID(entry.slot)
	end
	Sweep(button, entry)
end

-- One square, at a column and a line inside a lane that starts `shift` units
-- in. The shift is a distance rather than a column number because the second
-- lane does not begin on a column boundary: half a square of air stands between
-- the two, and that is the whole point of the split.
--
-- The origin and the side both land on whole pixels, for the reason Snap gives.
-- The side is set here rather than once when the square is built because it is
-- a different number of units at every zoom, and a zoom change reaches this
-- file as a repaint. The hairline is measured again on the same condition: it
-- was one pixel at the zoom the square was built at, and a zoom that changes
-- the side has changed what one pixel is.
local function Place(button, top, column, line, shift, side)
	if button.side ~= side then
		button.side = side
		button:SetSize(side, side)
		ns.EdgeSize(button.edges, ns.Pixel(button))
	end
	-- Anchored only when the point moves. A refresh that changed nothing, which
	-- is what PLAYER_MONEY and most ITEM_LOCK_CHANGEDs are, lays every square
	-- on the point it is already on, and a SetPoint is a relayout whether or
	-- not the number moved. The parent is part of the key: Paint may have moved
	-- the square to another bag's holder just before this, and an anchor
	-- written against the old holder is an anchor to the wrong frame even
	-- though the two are the same size.
	local x, y = Snap(shift + column * (SLOT + GAP)), -Snap(top + line * (SLOT + GAP))
	local parent = button:GetParent()
	if button.x == x and button.y == y and button.on == parent then
		return
	end
	button.x, button.y, button.on = x, y, parent
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
end

-- One pile's squares, in one lane or two, from `left`, `top` down, and how
-- many lines they took. `lane` is how many squares across the left lane is and
-- `rest` the right; a pile drawn in one lane has a `rest` of nought. The
-- entries arrive sorted, and dispatching them one at a time keeps each lane in
-- the order the sort put them.
--
-- The two lanes are counted rather than collected. A split pile could be
-- partitioned into two lists and walked twice, and that is two tables per
-- pile per bag update for an answer a running count already has.
--
-- A square an empty pile folded into is marked as it is laid, for the hold
-- below: it is a square whose number is not about the item on it. There is one
-- for the Empty pile and one for each special bag with room in it.

-- The pass being laid out: how many squares, captions and rules it has used,
-- where the line being filled starts, how many blocks are on it and how many
-- rows they are asked for, and what every square on it is painted with. One
-- table for the file, reset at the top of every paint, so a pass allocates
-- nothing.
local flow = {
	at = 0, named = 0, captions = 0, rules = 0,
	top = 0, count = 0, rows = 1,
	columns = 0, side = 0, selling = false,
}

local function Lay(group, lane, rest, left, top)
	local entries = group.entries
	local split = lane > 0 and rest > 0
	local shift = left + lane * (SLOT + GAP) + Gap()
	local empty = ns.Piles.Vacant(group.key)
	local at, mine, theirs = flow.at, 0, 0
	for index = 1, #entries do
		at = at + 1
		local entry = entries[index]
		local button = Square(at)
		Paint(button, entry, flow.selling, empty and (entry.count or 1) or nil)
		-- The pile the square was laid for and the lane fact it was laid on,
		-- which the hold compares against, and whether it is a fold.
		button.laid, button.laidYours, button.fold = group.key, entry.yours, empty
		if split and not entry.yours then
			Place(button, top, theirs % rest, math.floor(theirs / rest), shift, flow.side)
			theirs = theirs + 1
		else
			Place(button, top, mine % lane, math.floor(mine / lane), left, flow.side)
			mine = mine + 1
		end
		button:Show()
	end
	-- As tall as the taller lane. On a pile in one lane the right one is empty.
	return at, math.max(math.ceil(mine / lane), split and math.ceil(theirs / rest) or 0)
end

--------------------------------------------------------------------------
-- The hold
--
-- What the first paint after the window opened laid out, kept until the window
-- shuts: how many squares, the columns and the side
-- they were laid at, and the height they came to. Nil while nothing is held,
-- which is every moment the window is shut.
--
-- Five things end a hold early, and each is a layout the held one cannot
-- describe. Something landing in a slot no held square points at, which is a
-- loot or a purchase going into a free slot the fold was not drawn on. A held
-- square's slot holding an item from a different pile than the one it was laid
-- for, which is two items swapped, a session started, or a grey the client
-- graded at last. A held square's item changing lane, which is a quest taken
-- or abandoned, Questie gone, or a sword bound in place. The column setting
-- moving. And the zoom moving, which changes
-- what a square's side is and is only ever written in Place.
--------------------------------------------------------------------------

local held

local function Keep(count, columns, side, height)
	held = held or {}
	held.count = count
	held.columns, held.side, held.height = columns, side, height
end

-- The held layout painted again from a fresh scan, or false where the scan
-- describes something it cannot, which is the caller's cue to lay the piles
-- out again.
--
-- Every held square asks for the entry on its own slot and is painted from it
-- where it stands. A slot that emptied paints as an empty square with nothing
-- on it. A fold keeps counting its pile's empty slots, off the scan's count
-- rather than the entry's, because the entry that carries the count after a
-- sale is whichever empty slot sorted first and that is now a hole somewhere
-- else in the grid. A fold whose slot moved to another pile, which is a bag
-- swapped for one of another kind, ends the hold.
local function Hold(state, columns, side, selling)
	if held.columns ~= columns or held.side ~= side then
		return false
	end
	local carrying = 0
	for index = 1, held.count do
		local button = squares[index]
		local entry = ns.Bags.Entry(button.bag, button.slot)
		if not entry then
			return false
		end
		if (entry.link or button.fold)
			and (entry.group ~= button.laid or entry.yours ~= button.laidYours) then
			return false
		end
		if entry.link then
			carrying = carrying + 1
		end
		local counted = (button.fold and not entry.link) and state.vacant[button.laid] or nil
		Paint(button, entry, selling, counted)
	end
	return carrying == state.carried
end

--------------------------------------------------------------------------
-- The flow
--
-- A block is one pile: its caption and its squares under it. A line is filled
-- one block at a time. Every block on the line is asked for the same number of
-- rows, `flow.rows`, and answers with the width it comes to at that many. When
-- the line comes out wider than the window the rows go up by one and the line
-- is measured again. A block never takes more rows than its ceiling, so once
-- no block on the line can take another, the new block comes off, the line is
-- laid out at the rows it last fitted at, and the new block starts the next.
--
-- The ceiling is the height of a golden rectangle of the block's squares,
-- floor(sqrt(n / 1.618)): nine squares may stand two rows tall, forty may
-- stand four. It is a ceiling on sharing a line. A pile too wide for the
-- window at one row takes the rows it needs, alone.
--------------------------------------------------------------------------

local GOLDEN = 1.618

-- The blocks on the line being filled, pooled by their place on the line, and
-- where each laid block ended up, pooled by its row in the scan's state. Both
-- are reused every pass for the reason the squares are.
local blocks, placed = {}, {}

-- How wide this many squares are, nought for none. UI.SlotSpan counts the gaps
-- between squares, and nought squares have minus one of those.
local function Span(across)
	return across > 0 and UI.SlotSpan(across) or 0
end

-- The most rows a block of this many squares takes while it shares a line.
local function Ceiling(count)
	return math.max(1, math.floor(math.sqrt(count / GOLDEN)))
end

-- How many of a pile's squares go in the left lane, or nought for a pile drawn
-- in one. Counted once when the block joins a line, because the line is
-- measured again every time its rows go up.
local function Mine(group, columns)
	if not Splits(group, columns) then
		return 0
	end
	local mine = 0
	for index = 1, #group.entries do
		if group.entries[index].yours then
			mine = mine + 1
		end
	end
	return mine
end

-- A block asked for at `rows` rows: the squares across its left lane and its
-- right lane, and how wide it is. A split pile with everything on one side is
-- drawn in one lane, because half a square of air beside nothing divides
-- nothing. A block is never narrower than its caption's words.
local function Shape(block, rows, columns)
	local count, mine = #block.group.entries, block.mine
	if mine == 0 or mine == count then
		local across = math.min(columns, math.ceil(count / rows))
		return across, 0, math.max(Span(across), block.words)
	end
	local lane = math.min(columns, math.ceil(mine / rows))
	local rest = math.min(columns, math.ceil((count - mine) / rows))
	return lane, rest, math.max(Span(lane) + Gap() + Span(rest), block.words)
end

-- The rows a block takes when its line asks for `rows`: no more than its
-- ceiling, and no fewer than it needs to fit the window at all.
local function Rows(block, rows)
	return math.max(block.least, math.min(rows, block.ceiling))
end

-- The fewest rows at which a block fits the window on its own.
local function Least(block, columns)
	local most = math.max(1, #block.group.entries)
	for rows = 1, most do
		local _, _, width = Shape(block, rows, columns)
		if width <= Grid.Width(columns) then
			return rows
		end
	end
	return most
end

-- Whether the line fits the window at `flow.rows`. Every block spends a lane
-- gap after it, the last one included, which is the air Grid.Width carries.
local function Fits()
	local used = 0
	for index = 1, flow.count do
		local block = blocks[index]
		local _, _, width = Shape(block, Rows(block, flow.rows), flow.columns)
		used = used + width + Gap()
	end
	return used <= Grid.Width(flow.columns) + Gap()
end

-- Whether any block on the line would take another row if asked.
local function Grows()
	for index = 1, flow.count do
		local block = blocks[index]
		if Rows(block, flow.rows + 1) ~= Rows(block, flow.rows) then
			return true
		end
	end
	return false
end

-- The line laid out at `flow.top`, and the next one begun under it.
local function Flush()
	if flow.count == 0 then
		return
	end
	local left, tall = 0, 0
	for index = 1, flow.count do
		local block = blocks[index]
		local lane, rest, width = Shape(block, Rows(block, flow.rows), flow.columns)
		flow.named = flow.named + 1
		headings:Name(flow.named, block.group.name, flow.top, Snap(left))
		local high = UI.SLOT_HEADER
		if lane + rest > 0 then
			local lines
			flow.at, lines = Lay(block.group, lane, rest, left, flow.top + UI.SLOT_HEADER)
			high = high + lines * SLOT + (lines - 1) * GAP
		end
		local spot = placed[block.index]
		if not spot then
			spot = {}
			placed[block.index] = spot
		end
		spot.left, spot.top, spot.lane, spot.rest, spot.width = left, flow.top, lane, rest, width
		tall = math.max(tall, high)
		left = left + width + Gap()
	end
	flow.top = flow.top + tall + BREAK
	flow.count, flow.rows = 0, 1
end

-- One pile onto the line being filled, or onto the next line when this one
-- cannot make room for it. `index` is the pile's row in the scan's state.
local function Push(group, index)
	local count = flow.count + 1
	local block = blocks[count]
	if not block then
		block = {}
		blocks[count] = block
	end
	block.group, block.index = group, index
	-- Measured on the caption this block will be drawn with: the next one after
	-- everything already on the line.
	block.words = headings:Width(flow.named + count, group.name)
	block.mine = Mine(group, flow.columns)
	block.ceiling = Ceiling(#group.entries)
	block.least = Least(block, flow.columns)
	flow.count = count
	local fitted = flow.rows
	while count > 1 and not Fits() do
		if not Grows() then
			flow.count, flow.rows = count - 1, fitted
			Flush()
			blocks[1], blocks[count] = block, blocks[1]
			flow.count = 1
			return
		end
		flow.rows = flow.rows + 1
	end
end

-- The rule under the session and over the junk: one pixel of the theme's edge
-- across the grid, pooled like the captions.
local function Rule()
	flow.rules = flow.rules + 1
	local rule = rules[flow.rules]
	if not rule then
		rule = UI.Rule(canvas, C.edge)
		rules[flow.rules] = rule
	end
	local px = ns.Pixel(canvas)
	rule:ClearAllPoints()
	rule:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -Snap(flow.top))
	rule:SetSize(UI.SlotSpan(flow.columns), px)
	rule:Show()
	flow.top = flow.top + px + BREAK
end

-- A row that is not a pile. Every one ends the line being filled; a section
-- caption and a rule then take a line of their own.
local function Mark(group)
	Flush()
	if group.kind == "section" then
		flow.captions = flow.captions + 1
		flow.top = headings:Sub(flow.captions, group.name, flow.top, 0)
	elseif group.kind == "rule" then
		Rule()
	end
end

-- Everything the pools made and this pass did not use.
local function Trim()
	for index = flow.at + 1, #squares do
		squares[index]:Hide()
	end
	for index = flow.rules + 1, #rules do
		rules[index]:Hide()
	end
	headings:Trim(flow.named, flow.captions)
end

--------------------------------------------------------------------------

-- Where the squares are drawn. Called once, before any square exists, because a
-- square is parented to this frame when it is made.
function Grid.Attach(where)
	canvas = where
	headings = UI.Headings(canvas)
	return canvas
end

-- Every pile laid out, and how tall the result is.
--
-- The height is handed back rather than written anywhere, because the thing that
-- has to know is the scroll view and the scroll view belongs to the window.
--
-- One row of the scan at a time: a pile joins the line being filled, and a
-- caption, a rule or a break ends it. See The flow.
function Grid.Paint(state, columns)
	-- Asked once for the whole pass rather than per square. It cannot change
	-- inside one layout, and a hundred and fifty squares asking the same
	-- question is a hundred and fifty answers that are the same.
	local selling = ns.BagsMerchant.Open()
	-- Walking away from a vendor with the pointer still on a square you could
	-- have sold. There is no OnLeave for that, because the mouse did not move:
	-- the merchant closed under it, and the repaint is where this file finds
	-- out. The hold stays: the gaps close when the window shuts.
	if not selling then
		Give()
	end
	-- Once a pass, like the merchant check above and for the same reason: the
	-- zoom cannot change inside one layout.
	local side = Snap(SLOT)
	if held and Hold(state, columns, side, selling) then
		Follow()
		return held.height
	end
	flow.at, flow.named, flow.captions, flow.rules = 0, 0, 0, 0
	flow.top, flow.count, flow.rows = 0, 0, 1
	flow.columns, flow.side, flow.selling = columns, side, selling
	for index = 1, state.shown do
		local group = state.groups[index]
		if group.kind then
			Mark(group)
		else
			Push(group, index)
		end
	end
	Flush()
	Trim()
	Follow()
	-- The last line added a break under itself that nothing follows.
	local height = math.max(flow.top - BREAK, 1)
	-- The first paint after the window opened, or the one after a hold broke,
	-- is the one the squares are held at from here until the window shuts.
	Keep(flow.at, columns, side, height)
	return height
end

-- The hold let go, so the next paint lays the piles out again. The window
-- calls it as it hides, however it was hidden.
function Grid.Release()
	held = nil
end

-- How many squares the hold is keeping in place, or nothing while none are.
-- Handed out because "the squares did not move when one of them sold" is a
-- claim scripts/harness.lua makes about a layout, and whether a layout is
-- held is the fact under it.
function Grid.Held()
	return held and held.count or nil
end

-- The pool, for the harness. It reads the squares to say that a click on one
-- lands on the bag and slot the scan put there, which is the one claim about
-- this file that cannot be made from the outside.
function Grid.Squares()
	return squares
end

function Grid.Headers()
	return headings:All()
end

-- The section captions, for the harness, for the same reason.
function Grid.Subs()
	return headings:Subs()
end

-- The rules, for the harness, which counts the ones that are up.
function Grid.Rules()
	return rules
end

-- Where one pile of the last layout went, by its row in the scan's state: its
-- left edge and the top of its caption in units, the squares across its left
-- lane and its right lane, and its width. The harness reads a lane's start off
-- this rather than working the flow out a second time.
function Grid.Block(index)
	local spot = placed[index]
	if not spot then
		return nil
	end
	return spot.left, spot.top, spot.lane, spot.rest, spot.width
end

function Grid.Describe()
	if #squares == 0 then
		return "no squares drawn yet"
	end
	if not inherited then
		return ("%d squares, and this client refused the bag button template, so a click does nothing")
			:format(#squares)
	end
	if held then
		return ("%d squares on the client's own bag button, %d of them held in place while the window is open")
			:format(#squares, held.count)
	end
	return ("%d squares on the client's own bag button"):format(#squares)
end
