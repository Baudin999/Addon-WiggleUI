-- Ad hoc bars
--
-- A bar you made yourself is a list, a key and a ring, and this section
-- asserts the seams between the three: that a bar added to the list gets a
-- ring that starts hidden and a key the ring's snippet is wrapped round; that
-- what the cursor was holding lands on the square as the attribute a press
-- would cast; that the squares sit on the circle in the order the pick counts
-- in; that holding the key, pushing toward a square and letting go casts that
-- square and only that square; that a key is read back off the binding layer
-- rather than trusted; that a fight defers the whole apply; that deleting a
-- bar moves the bar under it, key and all, onto a different frame; that a gear
-- set carried off the character page lands as a macro square whose line the
-- slash word answers, and follows the set through a rename; and that a square
-- on a shown ring is drawn on the tick.
--
-- The snippets run, through 21-restricted.lua, and the key is pressed through
-- the binding layer on both edges. What this cannot prove is that the client's
-- own parser takes the snippet and that its GetMousePosition agrees with the
-- stub's. Those are a key press in game.

local H = ...
local ns, fire, check = H.ns, H.fire, H.check

local AdHoc, Bars = ns.AdHoc, ns.AdHocBars

local function frame(index)
	return _G[("WiggleUIAdHoc%d"):format(index)]
end

local function key(index)
	return _G[Bars.KeyName(index)]
end

local function square(index, at)
	return _G[Bars.ButtonName(index, at)]
end

local function bound(combo)
	return _G.GetBindingAction(combo, true)
end

local function holds(index)
	return ("CLICK %s:LeftButton"):format(Bars.KeyName(index))
end

-- A key on the keyboard going down or coming up, delivered to whatever the
-- binding layer says it clicks. The layer is read rather than the button named,
-- so a key this section never bound presses nothing.
local function press(combo, down)
	local action = bound(combo)
	local name, button = tostring(action):match("^CLICK ([^:]+):(.+)$")
	if not name then
		return false
	end
	return _G[name]:Click(button, down)
end

-- Where the middle of the screen is, and the pointer put a push away from it.
local function centre()
	return H.mouse.Point(_G.UIParent)
end

-- How far a push has to go on that ring, in the pixels push() moves by.
--
-- Bars.Reach answers in UIParent's own units, which is what the snippet and
-- Bars.Wedge both measure a push in. The pointer here is placed in physical
-- pixels, and the two differ by the UI scale on every client that is not at 1,
-- which is every client. A test that forgot the conversion passed a push of 89
-- against a reach of 93 and read that as the dead zone not working.
local function reachOf(index)
	return Bars.Reach(index) * _G.UIParent:GetEffectiveScale()
end

local function push(dx, dy)
	local x, y = centre()
	H.mouse.Place(x + dx, y + dy)
end

-- What the key sent, for as long as the section looks.
local sent = {}
local function spy()
	local cast, macro = _G.CastSpellByName, _G.RunMacroText
	_G.CastSpellByName = function(name) sent[#sent + 1] = "cast " .. tostring(name) end
	_G.RunMacroText = function(text) sent[#sent + 1] = tostring(text) end
	return function()
		_G.CastSpellByName, _G.RunMacroText = cast, macro
	end
end

check(ns.db.adhoc == true, "ad hoc bars did not ship switched on")
check(AdHoc.Count() == 0, "a fresh character started with a bar")
check(frame(1) == nil, "a frame was built before any bar asked for one")

--------------------------------------------------------------------------
-- A bar, its frame and its key
--------------------------------------------------------------------------

local trade = AdHoc.Add("trade")
check(trade == 1, "the first bar was not bar 1")
check(AdHoc.Get(1).name == "trade", "the bar did not keep its name")
check(AdHoc.Shown() == 1, "the page did not turn to the bar just added")

local f = frame(1)
check(f ~= nil, "adding a bar built no ring")
check(f ~= nil and f:IsShown() == false, "a new ring was on the screen before its key was held")

local k = key(1)
check(k ~= nil, "adding a bar built no key button")
check(k ~= nil and k.secure == true, "the key is not a secure action button, so a release cannot cast")
check(k ~= nil and k:GetRegisteredClicks().AnyDown == true and k:GetRegisteredClicks().AnyUp == true,
	"the key button is not registered on both edges, so letting the key go would not fire the ring")
check(k ~= nil and k:GetAttribute("useOnKeyDown") == false,
	"the key acts on the press, so it would cast before the mouse moved")
check(k ~= nil and k.wraps ~= nil and k.wraps.OnClick ~= nil and k.wraps.OnClick.header == f,
	"the key's OnClick is not wrapped by its own ring")
check(Bars.CanPick(1) == true, "the ring does not report that it can pick a square")
check(f ~= nil and f:GetFrameRef("screen") ~= nil and f:GetFrameRef("screen"):IsShown() == false,
	"the ring was not handed the hidden screen frame it reads the cursor off")

local s1 = square(1, 1)
check(s1 ~= nil and s1.secure == true, "a square is not a secure button")
check(s1 ~= nil and s1:GetRegisteredClicks().AnyUp == true and s1:GetAttribute("useOnKeyDown") == false,
	"a square's two edges disagree")
check(s1 ~= nil and s1.wraps ~= nil and s1.wraps.OnClick ~= nil
	and s1.wraps.OnClick.header == f
	and tostring(s1.wraps.OnClick.post):find("Hide", 1, true) ~= nil,
	"a square's OnClick is not wrapped by the ring with a snippet that hides it")
check(f ~= nil and f:GetFrameRef("square1") == s1, "the ring's snippet was not handed its first square")

local entry = Bars.Entry(1)
check(entry ~= nil and entry.count == 1, "an empty bar did not draw the one square a drop lands on")
check(s1 ~= nil and s1:IsShown() == true and square(1, 2):IsShown() == false,
	"an empty bar shows the wrong squares")
check(s1 ~= nil and s1:GetAttribute("type") == nil, "an empty square carries a type, so a press would do something")
check(f ~= nil and f:GetAttribute("wk-count") == 0, "an empty ring tells its snippet it holds something")

--------------------------------------------------------------------------
-- What lands on a square
--------------------------------------------------------------------------

_G.WiggleUICarrySpell(1, "spell")
local rend, why = AdHoc.Carry(_G.GetCursorInfo())
check(rend ~= nil and rend.kind == "spell" and rend.name == "Rend" and rend.icon ~= nil,
	("a spell off the book read as %s"):format(tostring(rend and rend.name or why)))
_G.ClearCursor()

check(AdHoc.Put(1, 1, rend) == true, "the first spell would not go on the first square")
check(#AdHoc.Squares(1) == 1 and AdHoc.Squares(1)[1].name == "Rend", "the list did not take the spell")
check(s1:GetAttribute("type") == "spell" and s1:GetAttribute("spell") == "Rend",
	"the square was not armed with the spell by name")
check(Bars.Entry(1).count == 1 and square(1, 2):IsShown() == false,
	"a bar of one spell drew a second square")

_G.WiggleUICarrySpell(2, "spell")
local clap = AdHoc.Carry(_G.GetCursorInfo())
_G.ClearCursor()
check(AdHoc.Put(1, 9, clap) == true, "a spell dropped past the end was refused")
check(#AdHoc.Squares(1) == 2 and AdHoc.Squares(1)[2].name == "Thunder Clap",
	"a drop past the end did not land on the next square")
check(Bars.Entry(1).count == 2, "two spells did not draw two squares")

do
	local item = AdHoc.Carry("item", 1001, H.itemLink("Bloodspiller"))
	check(item ~= nil and item.kind == "item" and item.id == 1001 and item.name == "Bloodspiller",
		"an item off a bag did not come back with its id and name")
	check(AdHoc.Put(1, 3, item) == true, "an item would not go on the bar")
	check(square(1, 3):GetAttribute("type") == "macro"
		and square(1, 3):GetAttribute("macrotext") == "/use Bloodspiller",
		"an item square does not carry a /use line")

	local refused, reason = AdHoc.Carry("macro", 3)
	check(refused == nil and type(reason) == "string",
		"a macro this client cannot name was accepted")

	local nothing, silence = AdHoc.Carry(nil)
	check(nothing == nil and silence == nil, "an empty cursor was answered with a sentence")

	-- Replacing, moving and taking away
	check(AdHoc.Put(1, 1, clap) == true and AdHoc.Squares(1)[1].name == "Thunder Clap",
		"a drop on a full square did not replace what was there")
	check(AdHoc.Move(1, 3, 1) == true and AdHoc.Squares(1)[1].name == "Bloodspiller"
		and AdHoc.Squares(1)[2].name == "Thunder Clap",
		"a move did not put the record where it was dragged")
	local taken = AdHoc.Take(1, 1)
	check(taken ~= nil and taken.name == "Bloodspiller" and #AdHoc.Squares(1) == 2
		and AdHoc.Squares(1)[1].name == "Thunder Clap",
		"taking a square away did not close the gap")
	check(square(1, 3):GetAttribute("type") == nil and square(1, 3):IsShown() == false,
		"the square past the end kept its old attribute")

	-- The width of a bar is a cap that says so
	for _ = 1, AdHoc.PER_BAR do
		AdHoc.Put(1, AdHoc.PER_BAR + 1, rend)
end
check(#AdHoc.Squares(1) == AdHoc.PER_BAR, "a bar took more squares than its width")
local over, full = AdHoc.Put(1, AdHoc.PER_BAR + 1, rend)
check(over == false and type(full) == "string", "the seventeenth square was dropped silently")
while #AdHoc.Squares(1) > 2 do
	AdHoc.Take(1, #AdHoc.Squares(1))
end

end

--------------------------------------------------------------------------
-- The key
--------------------------------------------------------------------------

do
	check(bound("T") ~= holds(1), "T was held before anyone bound it")
	local displaced, refusal = Bars.Bind(1, "T")
	check(displaced == "", ("binding T was refused: %s"):format(tostring(refusal)))
	check(bound("T") == holds(1), "T does not click the bar's key button")
	check(AdHoc.Get(1).key == "T" and AdHoc.Get(1).displaced == "", "the key was not written down")
	check(Bars.Describe(1) == "T", ("the bar describes its key as %s"):format(Bars.Describe(1)))

	local shadowed = Bars.Bind(1, "E")
	check(shadowed == "ACTIONBUTTON1", "taking a key off the action bar did not say what it displaced")
	check(bound("T") ~= holds(1) and bound("E") == holds(1), "rebinding left the old key held")

	local bare, bareWhy = Bars.Bind(1, "BUTTON1")
	check(bare == nil and type(bareWhy) == "string", "a bare mouse button was taken")
	check(bound("E") == holds(1), "a refused key cleared the key that was held")

	local totems = AdHoc.Add("totems")
	check(totems == 2 and frame(2) ~= nil and key(2) ~= nil, "a second bar built no frame")
	local twice, twiceWhy = Bars.Bind(2, "E")
	check(twice == nil and type(twiceWhy) == "string" and twiceWhy:find("trade", 1, true) ~= nil,
		"one key was taken by two bars")
	check(Bars.Bind(2, "SHIFT-T") == "", "a modified key was refused")
	check(bound("SHIFT-T") == holds(2), "the second bar's key does not click its own button")

	check(AdHoc.Find("totems") == 2 and AdHoc.Find("TRADE") == 1 and AdHoc.Find("2") == 2
		and AdHoc.Find("swords") == nil, "a bar is not found by name and by number")

end

--------------------------------------------------------------------------
-- The ring: hold, push, let go
--------------------------------------------------------------------------

do
	-- The screen gets a size for the length of the ring and hands back the one
	-- it had. The ring reads the cursor off a frame the size of the screen, and
	-- 48-tooltips.lua leaves UIParent at none, which is a frame no cursor is
	-- ever inside.
	local screenWidth, screenHeight = _G.UIParent:GetWidth(), _G.UIParent:GetHeight()
	_G.UIParent:SetSize(_G.GetScreenWidth(), _G.GetScreenHeight())

	local item = AdHoc.Carry("item", 1001, H.itemLink("Bloodspiller"))
	AdHoc.Put(1, AdHoc.PER_BAR + 1, item)
	check(#AdHoc.Squares(1) == 3 and f:GetAttribute("wk-count") == 3,
		"a ring of three does not tell its snippet it holds three")

	-- The squares sit where the pick counts: every square, measured from the
	-- middle of the ring, is inside its own wedge. This is what ties the
	-- picture to the arithmetic, so a ring drawn counter-clockwise, or from
	-- three o'clock, fails here rather than casting the neighbour in game.
	f:Show()
	local cx, cy = H.mouse.Point(f)
	for at = 1, 3 do
		local x, y = H.mouse.Point(square(1, at))
		check(Bars.Wedge(x - cx, y - cy, 3) == at,
			("square %d is drawn outside its own wedge"):format(at))
	end
	check(select(2, H.mouse.Point(square(1, 1))) > cy, "the first square is not at twelve")
	f:Hide()

	local restore = spy()

	-- Far enough out to pick a square, read off the ring rather than written
	-- here: how far that is is the circle's own business now, and a number
	-- typed in this file is one that stops meaning what it says the first time
	-- the ring opens wider.
	local reach = reachOf(1) + 20

	-- Hold E. The ring comes up and nothing is sent.
	push(0, 0)
	press("E", true)
	check(f:IsShown() == true, "holding the key did not open the ring")
	check(#sent == 0, "holding the key cast something before the mouse moved")

	-- Push toward the third square, down and to the left, and the plain Lua
	-- that lights a square agrees with the snippet about which one.
	local angle = math.rad(240)
	push(reach * math.sin(angle), reach * math.cos(angle))
	Bars.Aim(Bars.Entry(1))
	check(Bars.Entry(1).aimed == 3, ("the ring lit square %s for a push toward square 3")
		:format(tostring(Bars.Entry(1).aimed)))
	check(square(1, 3).aim:IsShown() == true, "the square under the push is not lit")

	press("E", false)
	check(f:IsShown() == false, "letting the key go left the ring up")
	check(#sent == 1 and sent[1] == "/use Bloodspiller",
		("a release toward the item sent %s"):format(tostring(sent[1])))
	check(k:GetAttribute("type") == nil, "the key kept the action after the cast, so a stray click fires it again")

	-- Straight up is the first square, a spell.
	sent = {}
	push(0, 0)
	press("E", true)
	push(0, reach)
	press("E", false)
	check(#sent == 1 and sent[1] == "cast Thunder Clap",
		("a release toward the first square sent %s"):format(tostring(sent[1])))

	-- Let go without moving and nothing is cast.
	sent = {}
	push(0, 0)
	press("E", true)
	push(Bars.DEAD / 2, 0)
	press("E", false)
	check(#sent == 0 and f:IsShown() == false, "a release inside the dead zone cast something")

	-- The ring opens round the cursor and not in the middle of the screen.
	--
	-- The two points have to be one, because one is the picture and the other
	-- is the arithmetic. Drawn anywhere else, the slice the cursor is over and
	-- the slice a release fires are two different slices, and a cursor sitting
	-- in the drawn hole is a push as long as the gap between the ring and the
	-- pointer. Both of those shipped, and neither could be seen until the ring
	-- drew its slices.
	sent = {}
	push(90, -50)
	press("E", true)
	local wantX, wantY = centre()
	local own = f:GetEffectiveScale()
	local gotX, gotY = (f:GetLeft() + f:GetWidth() / 2) * own, (f:GetTop() - f:GetHeight() / 2) * own
	check(math.abs(gotX - (wantX + 90)) < 1 and math.abs(gotY - (wantY - 50)) < 1,
		("the ring opened at %.0f, %.0f with the cursor at %.0f, %.0f")
			:format(gotX, gotY, wantX + 90, wantY - 50))
	press("E", false)
	check(#sent == 0, "a release that never left the middle of an off centre ring cast something")

	--------------------------------------------------------------------------
	-- The push has to reach the squares
	--
	-- Both pushes are the ring's own reach either side of it rather than two
	-- numbers written here, because the thing being asserted is that the
	-- arithmetic and the picture are one: a ring drawn 140 units out that fires
	-- on a push of 21 is what this replaced.
	--------------------------------------------------------------------------

	local out = reachOf(1)
	check(Bars.Reach(1) > Bars.DEAD,
		"the reach is the bare floor, so the circle is not what a push has to cross")

	sent = {}
	push(0, 0)
	press("E", true)
	push(0, out - 4)
	Bars.Aim(Bars.Entry(1))
	check(Bars.Entry(1).aimed == nil, "a push that stopped short of the squares lit one")
	press("E", false)
	check(#sent == 0, ("a push short of the squares sent %s"):format(tostring(sent[1])))

	sent = {}
	push(0, 0)
	press("E", true)
	push(0, out + 4)
	press("E", false)
	check(#sent == 1 and sent[1] == "cast Thunder Clap",
		("a push out to the squares sent %s"):format(tostring(sent[1])))

	-- And the reach is the circle, so moving the circle moves it.
	sent = {}
	local wasRadius = ns.db.adhocRadius
	ns.db.adhocRadius = wasRadius + 100
	Bars.Apply()
	check(reachOf(1) > out, "opening the ring out did not lengthen the push")
	push(0, 0)
	press("E", true)
	push(0, out + 4)
	press("E", false)
	check(#sent == 0, "the push that reached the old circle still cast on the wider one")

	ns.db.adhocRadius = wasRadius
	Bars.Apply()
	check(math.abs(reachOf(1) - out) < 1e-9, "putting the radius back did not put the push back")

	-- A click on a square while the ring is up casts that square and puts the
	-- ring away, so the release after it finds nothing to do. The click is
	-- aimed at the screen, and the windows the sections before this one left
	-- open in the middle of it are under the ring rather than over it.
	sent = {}
	push(0, 0)
	press("E", true)
	H.mouse.Click(H.mouse.Point(square(1, 2)))
	check(#sent == 1 and sent[1] == "cast Thunder Clap", "a click on a square did not cast it")
	check(f:IsShown() == false, "a click on a square left the ring up")
	push(0, reach)
	press("E", false)
	check(#sent == 1, "the release after a click cast a second time")

	restore()
	sent = {}
	AdHoc.Take(1, 3)
	H.mouse.Place(0, 0)
	_G.UIParent:SetSize(screenWidth, screenHeight)
end

--------------------------------------------------------------------------
-- The tick
--------------------------------------------------------------------------

do
	local tick = H.tick("adhoc")
	f:Show()
	tick:Beat(0.2)
	check(s1.shownTexture == AdHoc.Squares(1)[1].icon,
		"a square on a shown bar was not drawn with its record's picture")
	check(square(1, 2).shownTexture == AdHoc.Squares(1)[2].icon,
		"the second square on a shown bar was not drawn")
	f:Hide()

	local hidden = frame(2)
	local empty = square(2, 1)
	tick:Beat(0.2)
	check(empty.shownTexture == nil, "a square on a hidden bar was drawn")
	hidden:Show()
	tick:Beat(0.2)
	check(empty.shownLook ~= nil and empty.shownLook.blank == true,
		"the empty square on a shown bar was not drawn as empty")
	hidden:Hide()

end

--------------------------------------------------------------------------
-- A fight
--------------------------------------------------------------------------

do
	local realLockdown = _G.InCombatLockdown
	_G.InCombatLockdown = function() return true end
	check(AdHoc.Put(2, 1, rend) == true, "a drop in a fight was refused rather than held")
	check(Bars.Pending() == true, "a drop in a fight did not leave the apply pending")
	check(square(2, 1):GetAttribute("type") == nil, "a secure attribute was rewritten in combat")
	local fought, fightWhy = Bars.Bind(2, "Y")
	check(fought == nil and type(fightWhy) == "string", "a key was rebound in combat")
	_G.InCombatLockdown = realLockdown
	fire("PLAYER_REGEN_ENABLED")
	check(Bars.Pending() == false and square(2, 1):GetAttribute("spell") == "Rend",
		"the fight ending did not land the drop it had held")

end

--------------------------------------------------------------------------
-- Deleting the first bar moves the second
--------------------------------------------------------------------------

check(AdHoc.Remove(1) == true, "the first bar would not go")
check(AdHoc.Count() == 1 and AdHoc.Get(1).name == "totems", "the second bar did not move up")
check(bound("SHIFT-T") == holds(1), "the moved bar's key does not click the first key button")
check(bound("E") ~= holds(1) and bound("E") ~= holds(2), "the deleted bar's key is still held")
check(square(1, 1):GetAttribute("spell") == "Rend", "the moved bar's squares did not move with it")
check(frame(2):IsShown() == false, "the frame the deleted bar left behind is on the screen")

--------------------------------------------------------------------------
-- The switch
--------------------------------------------------------------------------

ns.db.adhoc = false
Bars.Apply()
check(bound("SHIFT-T") ~= holds(1), "a bar that is switched off still holds its key")
check(frame(1):IsShown() == false, "a bar that is switched off is on the screen")
check(Bars.Describe(1):find("off", 1, true) ~= nil, "the key is described as held while the bars are off")
ns.db.adhoc = true
Bars.Apply()
check(bound("SHIFT-T") == holds(1), "switching the bars back on did not take the key again")

--------------------------------------------------------------------------
-- A save from before the ring
--------------------------------------------------------------------------

AdHoc.Get(1).point = { "TOPLEFT", "UIParent", "TOPLEFT", 40, -40 }
AdHoc.Get(1).columns, AdHoc.Get(1).close = 2, false
Bars.Apply()
check(AdHoc.Get(1).point == nil and AdHoc.Get(1).columns == nil and AdHoc.Get(1).close == nil,
	"a bar saved before it was a ring kept the fields a ring does not read")
check(select(1, frame(1):GetPoint(1)) == "CENTER", "the ring is not in the middle of the screen")

--------------------------------------------------------------------------
-- The page
--------------------------------------------------------------------------

do
	ns.Options.Open("Ad hoc bars")
	ns.Options.Refresh()
	local first = ns.AdHocPanel.Square(1)
	check(first ~= nil and first.record ~= nil and first.record.name == "Rend",
		"the page's first square does not show the bar's first record")
	local next = ns.AdHocPanel.Square(2)
	check(next ~= nil and next.record == nil and next:IsShown() == true,
		"the page does not draw the empty square a drop lands on")
	check(ns.AdHocPanel.Square(3) ~= nil and ns.AdHocPanel.Square(3):IsShown() == false,
		"the page draws squares past the empty one")

	-- The circle on the page is the ring's own circle, smaller.
	--
	-- Where a square sits is AdHocBars.Where's answer for a ring of that many,
	-- times the size of a square here over the size of one there. Asserted
	-- against that call rather than against numbers typed out a second time,
	-- because the failure this is here for is the two pictures drifting: a page
	-- carrying its own copy of the angle passes a test carrying the same copy.
	local shown = AdHoc.Shown()
	for _, spell in ipairs({ "Hamstring", "Cleave", "Overpower" }) do
		AdHoc.Put(shown, 99, { kind = "spell", name = spell, icon = "Interface\\Icons\\Ability" })
	end
	ns.Options.Refresh()
	local count = #AdHoc.Squares(shown)
	check(count == 4, "the page did not get the bar of four it lays out")

	local drift = 0
	for at = 1, count do
		local w = ns.AdHocPanel.Square(at)
		local _, _, _, x, y = w:GetPoint(1)
		local scale = w:GetWidth() / Bars.SIZE
		local wantX, wantY = Bars.Where(at, count)
		drift = math.max(drift, math.abs(x - wantX * scale), math.abs(y - wantY * scale))
	end
	check(drift <= 1,
		("a square on the page is %.1f units off the circle the ring draws it on"):format(drift))

	local middle = ns.AdHocPanel.Square(count + 1)
	local _, _, _, middleX, middleY = middle:GetPoint(1)
	check(middle:IsShown() == true and middle.record == nil and middleX == 0 and middleY == 0,
		"the square a drop lands on is not empty in the middle of the circle")
	check(middle.at == count + 1,
		"the middle square is not the place after the last one, so a drop would replace rather than add")

	--------------------------------------------------------------------------
	-- A gear set on a bar, as a macro square
	--
	-- One mechanism in both places a set can be pressed, and the mechanism is a
	-- macro. A set cannot ride the client's cursor, because there is nothing to
	-- pick up, so it comes off the character page's toggle stack through
	-- UI/Carry.lua and lands here as a square with one line in it.
	--
	-- The line is read off the square and then typed at the slash prompt rather
	-- than compared to a string written out here. That is the failure worth
	-- catching: a square carrying a line the word does not answer presses
	-- perfectly and does nothing.
	--------------------------------------------------------------------------

	do
		local Sets = ns.Sets
		check(Sets.New("bling") ~= nil, "the set this block puts on a bar could not be made")

		local at = middle.at
		ns.UI.Carry.Lift({ kind = "set", name = "bling",
			icon = "Interface\\Icons\\INV_Chest_Plate01" })
		H.mouse.Place(H.mouse.Point(middle.button))
		check(ns.UI.Carry.Land(), "a set let go over a bar square was not taken")

		local record = AdHoc.Squares(shown)[at]
		check(record ~= nil and record.kind == "set" and record.name == "bling",
			("the square took %s rather than the set"):format(
				record and tostring(record.kind) or "nothing"))
		check(square(shown, at):GetAttribute("type") == "macro"
			and square(shown, at):GetAttribute("macrotext") == "/wui set wear bling",
			("a set square arms %q"):format(
				tostring(square(shown, at):GetAttribute("macrotext"))))

		-- Renamed, and every square pointing at it moves with it. That is the
		-- one cost of holding a set as macro text: the text names the set, so a
		-- rename either rewrites the squares or leaves them pointing at a name
		-- nobody has. The bars are ours, so it rewrites them.
		check(Sets.Rename("bling", "shiny"), "the set would not be renamed")
		check(AdHoc.Squares(shown)[at].name == "shiny",
			("the square still points at %q after the rename")
				:format(tostring(AdHoc.Squares(shown)[at].name)))
		check(square(shown, at):GetAttribute("macrotext") == "/wui set wear shiny",
			("a renamed set left the square arming %q")
				:format(tostring(square(shown, at):GetAttribute("macrotext"))))

		-- And forgotten while the square is still on the bar. The square stays,
		-- because a bar is yours and nothing here may quietly edit one, and the
		-- press says so in a sentence rather than doing nothing.
		check(Sets.Remove("shiny"), "the set would not be forgotten")
		local line = tostring(square(shown, at):GetAttribute("macrotext"))
		local typed = line:match("^/wui%s+(.*)$")
		check(typed ~= nil,
			("a set square arms %q, which is not a line /wui answers"):format(line))

		local heard = _G.ChatFrame1.messages or {}
		local quiet = #heard
		_G.SlashCmdList.WIGGLEUI(typed)
		check(#heard > quiet
			and tostring(heard[#heard].text):find("no set called", 1, true) ~= nil,
			("a square pointing at a set nobody has said %q")
				:format(tostring(heard[#heard] and heard[#heard].text)))

		AdHoc.Take(shown, at)
		ns.Options.Refresh()
	end

	while #AdHoc.Squares(shown) > 1 do
		AdHoc.Take(shown, #AdHoc.Squares(shown))
	end
	ns.Options.Refresh()

	--------------------------------------------------------------------------
	-- The plus asks what the bar is called
	--------------------------------------------------------------------------

	local before = AdHoc.Count()
	check(ns.AdHocPanel.Add() == true, "the plus refused to ask for a name")
	check(ns.UI.Naming() ~= nil, "the plus did not ask what the bar is called")
	check(AdHoc.Count() == before, "a bar was made before the window was answered")
	check(ns.UI.Called("") == false and ns.UI.Naming() ~= nil,
		"an empty name was taken rather than refused")
	check(ns.UI.Called(nil) == true and ns.UI.Naming() == nil,
		"the window would not close on a cancel")
	check(AdHoc.Count() == before, "closing the window without a name made a bar")

	ns.AdHocPanel.Add()
	check(ns.UI.Called("  totems and such  ") == true, "a name was refused")
	check(AdHoc.Count() == before + 1, "an answered window made no bar")
	check(AdHoc.Get(before + 1).name == "totems and such",
		"the bar was not called what the window was told, or the spaces came with it")
	check(AdHoc.Shown() == before + 1, "the page did not turn to the bar it just made")
	check(AdHoc.Remove(before + 1) == true, "the bar the page section made would not go")
	ns.Options.Refresh()
	ns.Options.Hide()

end

--------------------------------------------------------------------------
-- How big a ring is drawn, and what moves it
--
-- Two separate promises, and the second is the one that has been broken twice
-- in this addon already, in the enemy bars and then here. A square is written
-- in design units, and the grid in UI/Pixel.lua turns one unit into the
-- screen's height over the author's times the general size times this ring's
-- own zoom. So the units never move and the scale carries the whole of it: a
-- design that reached for UI.Pixel and multiplied its own numbers by it would
-- divide itself straight back out and the size slider would be inert.
--------------------------------------------------------------------------

do
	local ring, first = frame(1), square(1, 1)

	local function drawn()
		return first:GetWidth() * ring:GetEffectiveScale()
	end

	check(ns.UI.OnGrid(ring) == true,
		"the ring is not on the pixel grid, so no size the player sets reaches it")
	check(first:GetWidth() == 54 and first:GetHeight() == 54,
		("a square is %s units across, and the big sharp size is 54")
			:format(tostring(first:GetWidth())))

	local want = ns.UI.Scale() * ns.UI.ScreenZoom() * ns.db.adhocZoom
	check(math.abs(ring:GetScale() - want) < 1e-9,
		("the ring is drawn at %.4f where the grid and its own zoom say %.4f")
			:format(ring:GetScale(), want))

	-- The ring's own row on the zoom page.
	local before = drawn()
	ns.db.adhocZoom = 2
	Bars.Apply()
	check(math.abs(drawn() - before * 2) < 1e-6,
		("doubling the ring's zoom drew the square at %.2f where %.2f was wanted")
			:format(drawn(), before * 2))
	check(first:GetWidth() == 54,
		"the zoom was spent on the square's units rather than on the frame's scale")
	ns.db.adhocZoom = 1
	Bars.Apply()
	check(math.abs(drawn() - before) < 1e-9, "putting the ring's zoom back did not put its size back")

	-- Everything, which is the one the setup asks for and the one every other
	-- row multiplies. It moves the grid rather than this ring, so the proof is
	-- that the ring followed without being told.
	ns.UI.SetGeneral(2)
	check(math.abs(drawn() - before * 2) < 1e-6,
		("the general size drew the square at %.2f where %.2f was wanted")
			:format(drawn(), before * 2))
	check(first:GetWidth() == 54,
		"the general size was spent on the square's units rather than on the frame's scale")
	ns.UI.SetGeneral(1)
	check(math.abs(drawn() - before) < 1e-9, "putting the general size back did not put the ring back")
end

--------------------------------------------------------------------------
-- The pie: the slices, the seams and the hole in the middle
--
-- A push picks the slice it points into, so the slice is the thing being
-- aimed at and the square drawn in it is only a picture of what that slice
-- holds. The ring draws the slices for that reason, and this holds the
-- drawing to the arithmetic: the seam between two slices where the wedge
-- puts it, the lit slice facing the square a push of that direction picks,
-- and the hole in the middle exactly as wide as the push the release is
-- measured against.
--
-- The lit slice is read back off the two masks the client cuts it with rather
-- than off the numbers UI.Turn was handed. A rotation with the sign the wrong
-- way round is a ring that lights the square opposite the one it fires, and
-- the numbers going in cannot tell you that.
--------------------------------------------------------------------------

do
	-- A mask turned to t keeps everything within a quarter turn of t,
	-- anticlockwise from east, so two of them keep the arc between them. This
	-- is that sum run backwards, into the ring's own clockwise from twelve.
	local function slice(wedge)
		local one, two = wedge.masks[1].rotation, wedge.masks[2].rotation
		return (math.pi / 2 - (one + two) / 2) % (2 * math.pi), two - one + math.pi
	end

	local pie = AdHoc.Add("pie")
	for _, name in ipairs({ "Rend", "Cleave", "Hamstring", "Overpower" }) do
		AdHoc.Put(pie, 99, { kind = "spell", name = name, icon = "Interface\\Icons\\Ability" })
	end

	local entry = Bars.Entry(pie)
	local chrome = entry and entry.chrome
	local wedge = 2 * math.pi / 4
	check(chrome ~= nil, "the ring was built with no pie behind it")
	check(chrome ~= nil and chrome.count == 4, "the pie was not cut into one slice per square")

	-- The hole is the reach, in the units the release is measured in.
	local hole = ns.UI.Convert(ns.AdHocRing.Hole(chrome), entry.frame, _G.UIParent)
	check(math.abs(hole - Bars.Reach(pie)) < 1e-6,
		("the hole is %.1f across the middle and a push has to travel %.1f: the picture and the arithmetic disagree")
			:format(hole, Bars.Reach(pie)))

	-- A seam on the edge between every two slices, and none past the count.
	local seams = 0
	for at = 1, 4 do
		local centre, width = slice(chrome.seams[at])
		check(math.abs(centre - (at - 0.5) * wedge) < 1e-6,
			("the seam after square %d faces %.3f rather than %.3f"):format(at, centre, (at - 0.5) * wedge))
		check(width > 0 and width < wedge / 4, "a seam is a slice of its own rather than a line")
		seams = seams + (chrome.seams[at].texture:IsShown() and 1 or 0)
	end
	check(seams == 4, "the ring drew fewer seams than it has slices")
	check(chrome.seams[5] == nil or chrome.seams[5].texture:IsShown() == false,
		"a seam was left over from a wider bar")

	-- The lit slice faces the square a push that way picks, every square round
	-- the circle, and it is the slice rather than the square: as wide as the
	-- wedge, less the seam.
	for at = 1, 4 do
		local x, y = Bars.Where(at, 4)
		local picked = Bars.Wedge(x, y, 4)
		ns.AdHocRing.Aim(chrome, picked)
		local centre, width = slice(chrome.lit)
		check(picked == at, ("a push toward square %d picked %s"):format(at, tostring(picked)))
		check(math.abs(centre - (at - 1) * wedge) < 1e-6,
			("the ring lit a slice facing %.3f for the square at %.3f"):format(centre, (at - 1) * wedge))
		check(math.abs(width - wedge) < wedge / 8 and width < wedge,
			("the lit slice is %.3f wide where the wedge is %.3f"):format(width, wedge))
		check(chrome.lit.texture:IsShown() == true, "the slice under the push is not lit")
	end

	ns.AdHocRing.Aim(chrome, nil)
	check(chrome.lit.texture:IsShown() == false, "a push short of the ring left a slice lit")

	-- A ring of one square is one slice of the whole circle, which is wider
	-- than two masks can cut, so it lights as a disc.
	while #AdHoc.Squares(pie) > 1 do
		AdHoc.Take(pie, #AdHoc.Squares(pie))
	end
	check(chrome.count == 1, "taking the squares off did not cut the pie again")
	ns.AdHocRing.Aim(chrome, 1)
	check(chrome.whole:IsShown() == true and chrome.lit.texture:IsShown() == false,
		"the one square's ring lit a wedge rather than the whole circle")
	ns.AdHocRing.Aim(chrome, nil)
	check(chrome.whole:IsShown() == false, "the one square's ring stayed lit with nothing aimed at")

	AdHoc.Remove(pie)
end

--------------------------------------------------------------------------
-- The foot: nothing held, nothing on the screen
--------------------------------------------------------------------------

while AdHoc.Count() > 0 do
	AdHoc.Remove(AdHoc.Count())
end
check(bound("SHIFT-T") ~= holds(1) and bound("E") ~= holds(1), "a deleted bar left a key held")
_G.ClearCursor()
