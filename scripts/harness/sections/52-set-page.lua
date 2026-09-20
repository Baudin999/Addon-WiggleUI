-- The sets on the gear page
--
-- A line of circles under every gear row, one per set, and a stack of toggles
-- over the left column. Character/SetRow.lua draws both and the page hosts
-- them, which is the split this section measures from the page's side: what is
-- asserted here is the row, the circle and the gesture, never the store.
--
-- **The page a character with no sets opens is the page that shipped.** That
-- is the promise the growth makes to everybody who never saves one, and it is
-- the first block below: a row is thirty-six until there are two sets to
-- disagree with each other, and forty-eight after. One set grows nothing,
-- because one circle answers no question. The number is read off the row rather
-- than off the constant, so a layout that grew the page and forgot the rows,
-- or grew the rows and left the figure standing on the old block, fails here.
--
-- **The four states are four different pictures and that is the whole feature.**
-- A set naming the piece you already have on is the one that has to be dimmer
-- than the others: a glance down the column after a swap is meant to stop on
-- the circles that disagree with the disc above them, and a state that drew
-- like its neighbour would be a column that answers nothing. The pair worth
-- the most care is the last two, a slot nobody has told the set about against
-- one deliberately left bare, which are opposite intentions ten pixels wide.
--
-- **A click builds the set.** Not a menu, not a window: the gesture that puts
-- what you are wearing into a set is a press on the circle for that set on the
-- row for that slot, and the assertion is that the press lands there at all.
-- It goes through the pointer rather than by naming the handler, so a circle
-- under the secure square, under the figure or under nothing at all is a
-- circle the player cannot press and this fails rather than passing on a
-- handler nobody could reach.
--
-- **None of it on somebody else's sheet.** Every call behind a circle answers
-- about your own sets, so a circle under their boots would be a fact about you
-- drawn under their name, which is the same refusal the durability rule and
-- the cooldown arc already make on that page.
--
-- What this cannot prove: that the dimmed circle reads as dimmer to an eye. An
-- alpha is a number the client answers nothing about, and what is asserted is
-- that the four states write four different sets of numbers.

local H = ...
local ns, check = H.ns, H.check
local mouse, itemLink = H.mouse, H.itemLink

local Window, Theirs, Sets = ns.CharWindow, ns.InspectWindow, ns.Sets

-- The head slot, which is the row every block below drives. One slot and not
-- nineteen: what is under test is the row, and the row is the same row twenty
-- times.
local HEAD = 1

-- What a row is worth before and after the circles land on it.
local PLAIN, GROWN = 36, 48

-- Dimmed, which is the theme's own word for a control that is not the one you
-- are looking at.
local REST = ns.UI.Metric.rest

-- One row off a page, by the inventory slot it is drawn for.
local function square(pane, slot)
	for _, box in ipairs(pane.squares) do
		if box.entry.slot == slot then
			return box
		end
	end
	return nil
end

-- The circle on that row for a named set, and nothing if that set is not one
-- of the three the row is showing. By the name rather than by the position,
-- because which circle is which is the store's display order and this section
-- is not the place that decides it.
local function circle(box, name)
	local list = box.circles or {}
	for index = 1, #list do
		if list[index]:IsShown() and list[index].set == name then
			return list[index]
		end
	end
	return nil
end

-- How many circles a row is showing at all.
local function showing(box)
	local list, count = box.circles or {}, 0
	for index = 1, #list do
		if list[index]:IsShown() then
			count = count + 1
		end
	end
	return count
end

----------------------------------------------------------------------
-- Nothing until there are two sets
----------------------------------------------------------------------

Window.Show()

local pane = Window.Pane()
local head = square(pane, HEAD)
local worn = ns.Worn.Link(HEAD, "player")

check(head ~= nil and worn ~= nil,
	"the head row is not on the page or nothing is in it, and every block below drives it")
check(#Sets.All() == 0,
	("%d sets were saved before this section made any"):format(#Sets.All()))
check(head:GetHeight() == PLAIN,
	("a row on a page with no sets is %d and the page that shipped is %d")
		:format(head:GetHeight(), PLAIN))
check(showing(head) == 0,
	("%d circles were drawn for no sets at all"):format(showing(head)))

do
	-- One set, and the page does not move. One circle under a row says which
	-- of your sets disagrees with what you have on out of a field of one, which
	-- is not a question anybody has, and the row it would be drawn on belongs
	-- to the twenty rows of everybody who never saves a set.
	Sets.New("prot")
	check(head:GetHeight() == PLAIN,
		("one set grew the row to %d and one set is not worth a line"):format(head:GetHeight()))
	check(showing(head) == 0,
		("%d circles were drawn for a single set"):format(showing(head)))

	-- The toggle is there all the same, because a set you cannot press is a set
	-- you can only put on by typing. It is the store's write that put it there:
	-- nothing below fires an event or repaints the page by hand.
	check(pane.sets ~= nil and pane.sets.toggles[1] ~= nil
		and pane.sets.toggles[1]:IsShown(),
		"saving the first set drew no toggle over the left column")
	check(pane.sets.toggles[1].name:GetText() == "prot",
		("the toggle reads %q and the set is called prot")
			:format(tostring(pane.sets.toggles[1].name:GetText())))
end

----------------------------------------------------------------------
-- Three sets, and four states on one row
----------------------------------------------------------------------

do
	Sets.New("fury")
	Sets.New("resist")
	check(head:GetHeight() == GROWN,
		("a row with three sets on it is %d and the line needs %d")
			:format(head:GetHeight(), GROWN))
	check(showing(head) == 3,
		("%d circles were drawn for three sets"):format(showing(head)))

	-- The figure stands on the rows' own block and the toggles took their room
	-- off the top of the page, so he came down with the first row. A page that
	-- moved one of the two is a page whose picture no longer lines up with its
	-- columns.
	check(pane.panel:GetTop() == pane.left[1]:GetTop(),
		"the rows moved down for the toggles and the figure stayed where he was")

	-- What you are wearing, saved into the first set. The circle for it is the
	-- one that must not draw like the others: it agrees with the disc above it,
	-- so there is nothing on that row to go and look at.
	Sets.Capture("prot", HEAD)
	local mine = circle(head, "prot")
	check(mine ~= nil and mine.art:IsShown() and mine.art:GetAlpha() == REST,
		("the circle for the piece you have on drew at %s and rest is %s")
			:format(tostring(mine and mine.art:GetAlpha()), tostring(REST)))

	-- A set naming something else in that slot. The same picture at full
	-- strength, which is the one a glance down the column is meant to stop on.
	-- Any saved link will do: the page draws what the set says and never asks
	-- whether the piece would go in the slot, because that is the store's
	-- question and the answer to it is a refusal to wear rather than a refusal
	-- to draw.
	Sets.Put("fury", HEAD, itemLink("Breastplate of Might"))
	local other = circle(head, "fury")
	check(other ~= nil and other.art:IsShown() and other.art:GetAlpha() == 1,
		("a set naming a piece you are not wearing drew at %s")
			:format(tostring(other and other.art:GetAlpha())))
	check(other.art:GetTexture() ~= mine.art:GetTexture(),
		"two sets naming two different pieces drew the same picture")

	-- A slot nobody has told the third set about. Nothing inside the ring at
	-- all, and the ring itself at half strength, which is the difference the
	-- socket discs on the line above already draw between a gem and a hole.
	local bare = circle(head, "resist")
	check(bare ~= nil and not bare.art:IsShown() and not bare.bar:IsShown(),
		"an unset slot drew something inside its ring")
	check(select(4, bare.ring:GetVertexColor()) == 0.5,
		("an unset ring drew at %s and a hole is half strength")
			:format(tostring(select(4, bare.ring:GetVertexColor()))))

	-- And the same slot left bare on purpose, which is the opposite intention
	-- and has to be the opposite picture. This is the pair that would ship
	-- wrong: both of them are a circle with no item icon in it.
	Sets.Empty("resist", HEAD)
	check(bare.bar:IsShown() and not bare.art:IsShown(),
		"a slot left empty on purpose drew the same as one nobody has set")
	check(select(4, bare.ring:GetVertexColor()) == 1,
		("a deliberate hole drew its ring at %s and it is not the unset ring")
			:format(tostring(select(4, bare.ring:GetVertexColor()))))
end

----------------------------------------------------------------------
-- The gestures that edit a set
----------------------------------------------------------------------

do
	-- A click takes what you have on into that set's slot, which is how a set
	-- is actually built: a piece at a time, from the page that is already
	-- showing you the pieces.
	Sets.Clear("prot", HEAD)
	local mine = circle(head, "prot")
	check(Sets.Entry("prot", HEAD) == "unset",
		("clearing the slot left it %q"):format(tostring(Sets.Entry("prot", HEAD))))

	mouse.On(mine, "LeftButton")
	local state, link = Sets.Entry("prot", HEAD)
	check(state == "item" and link == worn,
		("a click on the circle left the slot %q holding %s")
			:format(tostring(state), tostring(link)))
	check(mine.art:GetAlpha() == REST,
		"the circle did not go dim on taking the piece that is already on the disc")

	-- A piece dragged out of a bag and let go over a circle fills that slot and
	-- puts the cursor down. Leaving the item on the cursor is the failure worth
	-- naming: a player one click away from dropping their own helmet.
	H.hold({ id = 4004, link = itemLink("Band of the Eternal") })
	mouse.Give(circle(head, "fury"))
	local dropped, ring = Sets.Entry("fury", HEAD)
	check(dropped == "item" and ring == itemLink("Band of the Eternal"),
		("a drop onto the circle left the slot %q"):format(tostring(dropped)))
	check(_G.GetCursorInfo() == nil, "the drop filled the slot and kept the item on the cursor")
end

----------------------------------------------------------------------
-- Nobody else's sheet
----------------------------------------------------------------------

do
	check(ns.Inspect.Look("target"), "the inspect page would not open")
	local theirs = Theirs.Pane()
	local box = square(theirs, HEAD)
	check(theirs.sets == nil, "somebody else's sheet grew a stack of your sets")
	check(box:GetHeight() == PLAIN,
		("an inspect row is %d and it has no line of yours to carry"):format(box:GetHeight()))
	check(showing(box) == 0,
		("%d of your circles were drawn on their gear"):format(showing(box)))
	Theirs.Close()
end

----------------------------------------------------------------------
-- Left as it was found
--
-- The sets are saved state on this character, so a section that left three of
-- them behind would leave every gear assertion after it reading a row twelve
-- pixels taller than the one it was written against.
----------------------------------------------------------------------

Sets.Remove("prot")
Sets.Remove("fury")
Sets.Remove("resist")

check(#Sets.All() == 0,
	("%d sets were left behind"):format(#Sets.All()))
check(head:GetHeight() == PLAIN,
	("the last set was dropped and the row is still %d"):format(head:GetHeight()))
check(showing(head) == 0,
	("%d circles were left showing with no sets behind them"):format(showing(head)))

Window.Hide()

print(("sets   a row grows %d to %d for three sets, four states drawn on one slot, and none of it on an inspect page")
	:format(PLAIN, GROWN))
