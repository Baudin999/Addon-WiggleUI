-- The sets on the gear page
--
-- A line of circles under every gear row, one per set, and a stack of toggles
-- over the left column. Character/SetRow.lua draws both and the page hosts
-- them, which is the split this section measures from the page's side: what is
-- asserted here is the row, the circle and the gesture, never the store.
--
-- **The page a character with no sets opens is the page that shipped.** That
-- is the promise the growth makes to everybody who never saves one, and it is
-- the first block below: a row is thirty-six until a set exists and fifty-four
-- from the first one on. One set is where the line starts and not two, because
-- one saved set you are not fully wearing is exactly what a circle that
-- disagrees with the disc above it is for. The number is read off the row rather
-- than off the constant, so a layout that grew the page and forgot the rows,
-- or grew the rows and left the figure standing on the old block, fails here.
--
-- **A set is made from the page or it may as well not exist.** The stack ends
-- in a toggle that is not a set, drawn on a page with no sets at all, and it
-- opens the window the rest of this section drives: a name, a tick for whether
-- the set starts from what you have on, and a button refused before the press
-- rather than after it. What shipped first had none of that, and the only way
-- to make a set was a slash command nobody was ever shown.
--
-- **The four states are four different pictures and that is the whole feature.**
-- A set naming the piece you already have on is the one that has to be dimmer
-- than the others: a glance down the column after a swap is meant to stop on
-- the circles that disagree with the disc above them, and a state that drew
-- like its neighbour would be a column that answers nothing. The pair worth
-- the most care is the last two, a slot nobody has told the set about against
-- one deliberately left bare, which are opposite intentions sixteen pixels
-- wide.
--
-- **A click builds the set.** Not a menu, not a window: the gesture that puts
-- what you are wearing into a set is a press on the circle for that set on the
-- row for that slot, and the assertion is that the press lands there at all.
-- It goes through the pointer rather than by naming the handler, so a circle
-- under the secure square, under the figure or under nothing at all is a
-- circle the player cannot press and this fails rather than passing on a
-- handler nobody could reach.
--
-- **Both right clicks, because both were missing and one of them was the
-- feature.** Nothing reached the deliberate hole: a click captures, a drop
-- names a piece and a drag off unsets, so a set could be built and could never
-- say "take the shield off", which is the half of a set that takes anything
-- off you. And a set could be made from what you were wearing exactly once,
-- because the toggles put a set on and nothing on the page took one again. Both
-- are asserted through the pointer with the button named, so a circle or a
-- toggle that never registered the right button fails here rather than passing
-- on a handler called by name.
--
-- **A set with nothing in it says so.** Wearing one used to report "0 changed,
-- 0 already on", which is the sentence a set you are already wearing gets and
-- says nothing about which of the two happened. The refusal names the gesture
-- that fills the set, and that is the line asserted rather than the return.
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
local SetRow = ns.SetRow

-- The head slot, which is the row every block below drives. One slot and not
-- nineteen: what is under test is the row, and the row is the same row twenty
-- times.
local HEAD = 1

-- What a row is worth before and after the circles land on it. The line is a
-- sixteen pixel disc and two of air, and the row carries it whole.
local PLAIN, GROWN = 36, 54

-- What the toggle at the foot of the stack says. A word for what it does and
-- not a name, because it is the one toggle in the column that is not a set.
local MAKE = "new set"

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
-- Nothing until there is a set, and a way to make one either way
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

-- The stack, on a character who has never saved anything. One toggle, and it
-- is not a set: without it the page draws nothing at all about sets and the
-- feature is reachable only by typing a command nobody was shown.
local stack = pane.sets
check(stack ~= nil and stack.toggles[1] ~= nil and stack.toggles[1]:IsShown(),
	"a page with no sets drew nothing that makes one")
check(stack.toggles[1].set == nil,
	"the toggle on a page with no sets is carrying a set")
check(stack.toggles[1].name:GetText() == MAKE,
	("the empty toggle reads %q"):format(tostring(stack.toggles[1].name:GetText())))

----------------------------------------------------------------------
-- The window a set is made in
----------------------------------------------------------------------

do
	-- The press opens the window and writes nothing. A toggle that saved on the
	-- press would be a set named for you, and naming a set is the one thing
	-- about it you cannot do from this page afterwards.
	mouse.On(stack.toggles[1], "LeftButton")
	local namer = SetRow.Naming()
	check(namer ~= nil, "pressing the empty toggle opened no window")
	check(#Sets.All() == 0,
		("the press made %d sets before anything was typed"):format(#Sets.All()))

	-- The spec you are standing in is already in the field, so the player who
	-- wanted that name presses enter. A class run whose spec did not resolve
	-- gets an empty field, which is the same window with a word to type.
	local label = ns.Class.Spec.Label()
	check(namer.field.edit:GetText() == (label or ""),
		("the field opened on %q and the spec is %s")
			:format(tostring(namer.field.edit:GetText()), tostring(label)))
	check(namer.worn.on == true,
		"the box that starts the set from what you are wearing was not ticked")

	-- A name that cannot be saved is refused before the press, with the reason
	-- under the tick. Both halves: a button that is simply dead never says why,
	-- and a sentence on its own sits under a button that still looks pressable.
	namer.field.edit:SetText("")
	check((namer.note:GetText() or "") ~= "", "an empty name was refused in silence")
	check(namer.accept:GetAlpha() < 1, "an empty name left the save button lit")

	namer.field.edit:SetText("prot")
	check((namer.note:GetText() or "") == "",
		("a name nothing is using was refused with %q"):format(tostring(namer.note:GetText())))
	check(namer.accept:GetAlpha() == 1, "a name nothing is using left the save button dim")

	mouse.On(namer.accept, "LeftButton")
	check(SetRow.Naming() == nil, "the window stayed up after the set was saved")
	check(#Sets.All() == 1,
		("accepting the window made %d sets"):format(#Sets.All()))
	check(Sets.All()[1].name == "prot",
		("the set is called %q and the field said prot"):format(tostring(Sets.All()[1].name)))

	-- Ticked, so the set is a photograph of what you have on rather than an
	-- empty list: all nineteen slots and not the one row this section drives.
	local state, link = Sets.Entry("prot", HEAD)
	check(state == "item" and link == worn,
		("the set holds %q in the head slot and you are wearing %s")
			:format(tostring(state), tostring(worn)))

	-- And the row grew on the first set, which is the case the circles exist
	-- for: one saved set you are not fully wearing is a column of circles that
	-- disagree with the discs above them.
	check(head:GetHeight() == GROWN,
		("one saved set left the row at %d and the line needs %d")
			:format(head:GetHeight(), GROWN))
	check(showing(head) == 1,
		("%d circles were drawn for one set"):format(showing(head)))

	-- The stack moved down one: the set took the top and the empty toggle is
	-- under it, which is what keeps the column reading as one thing.
	check(stack.toggles[1].name:GetText() == "prot",
		("the first toggle reads %q and the set is called prot")
			:format(tostring(stack.toggles[1].name:GetText())))
	check(stack.toggles[2] ~= nil and stack.toggles[2]:IsShown()
		and stack.toggles[2].set == nil,
		"saving a set left no way to make another one")
end

do
	-- A name already in use, said before the press rather than after it. The
	-- store answers the same refusal, but it answers by being called and the
	-- call that does not refuse has already written the set.
	mouse.On(stack.toggles[2], "LeftButton")
	local namer = SetRow.Naming()
	check(namer ~= nil, "the empty toggle under a set opened no window")
	namer.field.edit:SetText("prot")
	check((namer.note:GetText() or ""):find("already", 1, true) ~= nil,
		("a name already in use was refused with %q")
			:format(tostring(namer.note:GetText())))
	check(namer.accept:GetAlpha() < 1, "a name already in use left the save button lit")
	check(#Sets.All() == 1,
		("%d sets exist and only prot was ever accepted"):format(#Sets.All()))

	-- Unticked, which is the other half of the one question this window asks.
	-- The set is made and every slot in it is unset, so it is built by clicking
	-- circles rather than by undressing.
	namer.field.edit:SetText("fury")
	mouse.On(namer.worn, "LeftButton")
	check(namer.worn.on == false, "the tick did not come off when it was clicked")
	check(namer.accept:GetAlpha() == 1, "a free name with the tick off left the button dim")

	mouse.On(namer.accept, "LeftButton")
	check(#Sets.All() == 2, ("accepting made %d sets"):format(#Sets.All()))
	check(Sets.Entry("fury", HEAD) == "unset",
		("an unticked set holds %q in the head slot and it was never told about one")
			:format(tostring(Sets.Entry("fury", HEAD))))
end

----------------------------------------------------------------------
-- Three sets, and four states on one row
----------------------------------------------------------------------

do
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
	--
	-- A head piece and not any link that happens to be to hand. Sets.Put asks
	-- ns.Gear.Replaces whether the item lands in the slot and refuses it when it
	-- does not, which is the right place for that refusal: a set naming a chest
	-- in the head slot is a set that can never be worn, and catching it at the
	-- edit is one message where catching it at the wear is nineteen.
	Sets.Put("fury", HEAD, itemLink("Lightbringer Faceguard"))
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
	--
	-- Reached with the right button rather than by calling the store, because
	-- for an hour this state was drawn and unreachable: the file painted four
	-- states and three gestures could ask for three of them.
	mouse.On(bare, "RightButton")
	check(Sets.Entry("resist", HEAD) == "empty",
		("a right click on an unset circle left the slot %q")
			:format(tostring(Sets.Entry("resist", HEAD))))
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
	Sets.Clear("fury", HEAD)
	H.hold({ id = 4101, link = itemLink("Lightbringer Faceguard") })
	mouse.Give(circle(head, "fury"))
	local dropped, ring = Sets.Entry("fury", HEAD)
	check(dropped == "item" and ring == itemLink("Lightbringer Faceguard"),
		("a drop onto the circle left the slot %q"):format(tostring(dropped)))
	check(_G.GetCursorInfo() == nil, "the drop filled the slot and kept the item on the cursor")

	-- The right button, all the way round. A slot holding a piece goes to the
	-- deliberate hole, the hole goes back to unset, and unset goes to the hole
	-- again, so two presses from anywhere put the slot back where they found it
	-- and nothing has to be dragged to undo one.
	local cycled = circle(head, "fury")
	mouse.On(cycled, "RightButton")
	check(Sets.Entry("fury", HEAD) == "empty",
		("a right click on a circle holding a piece left the slot %q")
			:format(tostring(Sets.Entry("fury", HEAD))))
	mouse.On(cycled, "RightButton")
	check(Sets.Entry("fury", HEAD) == "unset",
		("a right click on a deliberate hole left the slot %q")
			:format(tostring(Sets.Entry("fury", HEAD))))
	mouse.On(cycled, "RightButton")
	check(Sets.Entry("fury", HEAD) == "empty",
		("a right click on an unset slot left it %q and the cycle has three stops")
			:format(tostring(Sets.Entry("fury", HEAD))))
end

----------------------------------------------------------------------
-- Taking a whole set again, and a set with nothing in it
----------------------------------------------------------------------

do
	-- A right click on a toggle re-takes the lot. Without it a set was a
	-- photograph that could never be taken twice from the page: nineteen
	-- circles clicked one at a time, or a slash word nobody was shown.
	local toggle = stack.toggles[2]
	check(toggle ~= nil and toggle.set ~= nil and toggle.set.name == "fury",
		("the second toggle carries %q and the set is called fury")
			:format(tostring(toggle and toggle.set and toggle.set.name)))

	mouse.On(toggle, "RightButton")
	local state, link = Sets.Entry("fury", HEAD)
	check(state == "item" and link == worn,
		("a right click on the toggle left the head slot %q holding %s")
			:format(tostring(state), tostring(link)))

	-- All nineteen and not the one row this section drives, which is the whole
	-- difference between this gesture and a click on a circle.
	local chest = Sets.Entry("fury", 5)
	check(chest ~= "unset",
		("the right click left the chest slot %q and it took everything")
			:format(tostring(chest)))

	-- And a set that names nothing refuses rather than reporting a run that did
	-- nothing. The line names the gesture above, because that is what fills it.
	Sets.New("bling")
	local ok, why = Sets.Wear("bling")
	check(ok == false, "a set with nothing in it was worn and reported a run")
	check(tostring(why):find("nothing in it", 1, true) ~= nil,
		("an empty set was refused with %q"):format(tostring(why)))
	check(tostring(why):find("right click", 1, true) ~= nil,
		("an empty set's refusal does not say how to fill it: %q"):format(tostring(why)))
	Sets.Remove("bling")
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

print(("sets   a set made from the page in a window, a row grows %d to %d on the first one, four states drawn on one slot, a right click cycling a circle through the last two and another taking the whole character into a set, an empty set refused with the way to fill it, and none of it on an inspect page")
	:format(PLAIN, GROWN))
