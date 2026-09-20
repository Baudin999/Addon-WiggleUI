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
-- bar moves the bar under it, key and all, onto a different frame; and that a
-- square on a shown ring is drawn on the tick.
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
	local reach = 100

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
	ns.Options.Hide()

end

--------------------------------------------------------------------------
-- The foot: nothing held, nothing on the screen
--------------------------------------------------------------------------

while AdHoc.Count() > 0 do
	AdHoc.Remove(AdHoc.Count())
end
check(bound("SHIFT-T") ~= holds(1) and bound("E") ~= holds(1), "a deleted bar left a key held")
_G.ClearCursor()
