local ADDON, ns = ...

local Bars = {}
ns.AdHocBars = Bars

local UI = ns.UI
local Ability = ns.UI.Ability
local C = ns.UI.Color

--------------------------------------------------------------------------
-- The ring on the screen, and the key that opens it
--
-- A bar you made is an OPie ring. Hold its key and the squares come up on a
-- circle round the cursor; push the mouse toward one and let the key go, and
-- that one fires. Nothing is clicked. The pick is a direction, so every square
-- owns a wedge of the whole screen rather than its own 27 units, and a mouse
-- that overshoots still lands on the right spell.
--
-- The direction is measured from where the cursor stood when the key went
-- down, and the ring opens round that point. The client has no call that moves
-- the cursor, so the picture goes to the pointer rather than the pointer to
-- the picture: the hole in the middle of the ring is the dead zone drawn where
-- the cursor is standing, the slice the cursor is over is the slice that
-- fires, and letting go without moving fires nothing.
--
-- It used to open in the middle of the screen with the direction still
-- measured from the cursor, which is one gesture drawn as two. Every slice was
-- out by however far the pointer happened to be from the middle of the screen,
-- and a cursor parked on the ring's own middle was a push the length of that
-- gap, which cast. Neither was visible until the ring drew its slices.
--
-- Why this works in a fight, link by link, because every link is a protected
-- thing an addon is refused under lockdown:
--
--   The key is a secure action button that UI/Press.lua's Press.Held builds:
--   registered on both edges, acting on the release. The ring wraps its
--   OnClick, and the pre body runs on both edges before the client's half.
--
--   The press shows the ring and writes down where the cursor is. A snippet
--   may show a secure frame in a fight; an addon may not.
--
--   The release reads the cursor again, turns the angle into a wedge, and
--   copies that square's action onto the key. Then the client's half runs,
--   sees the release, and casts whatever the key now carries. The release is
--   the hardware event, which is the whole reason a cast is allowed at all:
--   a cursor passing over a button is not one, and never casts.
--
-- That chain is OPie's, read off the copy installed next to this addon:
-- OPieCore.lua reads `SCREEN:GetMousePosition()` off a hidden full-screen
-- frame, turns atan2 into a slice in ORL_GetCursorSlice, and writes the
-- slice's macrotext onto the bound button in ORL_PerformSliceAction.
--
-- A square can still be clicked while the ring is up. It is a secure button
-- of its own, and a click on it casts and puts the ring away, so the release
-- that follows finds the ring gone and does nothing.
--
-- The frames are made on first use and never destroyed, because a secure frame
-- cannot be. A bar you delete keeps its frame and the next bar you add takes
-- it, so the pool never grows past the cap, and every attribute on it is
-- written again from the list on every Apply, which is what makes a deleted
-- bar's key land on the right frame.
--------------------------------------------------------------------------

local MAX = ns.AdHoc.MAX
local PER_BAR = ns.AdHoc.PER_BAR

-- 54, the big sharp size. UI.IconSizes answers { 54, 27 } and those two are
-- the drawn sizes where a stored texel lands on a pixel, which is the reason
-- Buttons/Look.lua gives at length. A bar takes the small one because a bar is
-- on the screen all night and a part you read all night wants to be small. A
-- ring is up for the second your thumb is on its key and has to be read in one
-- look, so it takes the big one.
--
-- It was 27 with a default zoom of 1.4 over it, which is 38 and is neither of
-- the two sharp sizes: every icon on the ring was resampled, and a player whose
-- saved zoom was 1, which is every player who ever typed `adhoc zoom`, got a
-- ring of 27 pixel squares in the middle of a 1440 pixel screen.
--
-- Units, not pixels. UI.Adopt puts the ring on the grid in UI/Pixel.lua, which
-- multiplies one unit by the screen's height over the author's times the
-- general size, so this is 54 physical pixels on the author's monitor and the
-- same share of the screen everywhere else. `Everything` on the zoom page moves
-- it, and so does this ring's own row.
local SIZE = 54

-- The gap between two neighbours at the widest a ring gets, which is what the
-- packing term below keeps: every square owns SIZE plus SPACE of the
-- circumference, so a ring of sixteen is a circle of squares rather than a
-- circle of overlapping squares.
local SPACE = math.floor(SIZE * 0.37)

-- What the player may set the circle to, in units at zoom one.
--
-- The low end is where the ring used to be, near enough. It was 86, which is
-- `SIZE * 1.6` and the tightest circle that keeps the name in the middle clear
-- of the squares; at four or five squares that is a cluster in the middle of
-- the screen rather than a ring, so it is the floor now and not the answer. 80
-- rather than 86 because the row steps in tens and a range that starts off the
-- step lands on no number anybody would choose.
--
-- The high end is a push of 320 units, which on a screen of 768 is most of the
-- way to the edge. Past that the ring stops being a gesture and becomes a menu
-- you travel to.
local RADIUS_LOW, RADIUS_HIGH = 80, 320

-- The one line in the middle of the ring, naming what the cursor points at. A
-- share of the square for the same reason the circle is: it was 12 against a
-- 27 unit square, and a number left behind while everything round it doubled
-- is the way this ring ended up unreadable the first time.
local NAME_FONT = math.floor(SIZE * 0.44)

-- The least a push can be and still mean something, in units of the screen
-- frame. Twenty is a flick; less than that is a thumb letting go of a key it
-- pressed by mistake, and a cast nobody meant is worse than none.
--
-- It is the floor under the reach below rather than the reach itself. It was
-- the whole of the test, and a ring drawn 140 units out that fires on a push of
-- 21 is a picture and an arithmetic that disagree: you are shown squares to aim
-- at and the thing you are actually doing is twitching in a direction.
local DEAD = 20

-- Over every window, because a ring is up for the second a key is held and has
-- to be read over whatever is open. The bags, the quest log and the options
-- are DIALOG, and a ring at MEDIUM came up underneath them. FULLSCREEN is where
-- OPie's RingView.lua puts its ring on this client.
local STRATA = "FULLSCREEN"

local entries = {}

local function FrameName(index)
	return ("WiggleUIAdHoc%d"):format(index)
end

local function KeyName(index)
	return ("WiggleUIAdHoc%dKey"):format(index)
end

local function ButtonName(index, at)
	return ("WiggleUIAdHoc%dButton%d"):format(index, at)
end

Bars.KeyName = KeyName
Bars.ButtonName = ButtonName
Bars.DEAD = DEAD

-- The radius a ring of `count` squares is drawn at, and where the `at`th of
-- them sits on that circle: square one at twelve and the rest clockwise, which
-- is the order Bars.Wedge and the snippet count in.
--
-- The radius is the player's `adhocRadius` with the packing term as a floor
-- under it. A circle set tighter than the squares fit on is widened rather than
-- obeyed, because two squares overlapping is not a setting anybody chose, and
-- the page says when that happened rather than leaving the number on the row
-- looking ignored.
--
-- All three are public, the size of a square included, because the page you
-- design a bar on draws the same circle at the size of a square on a settings
-- page. The page multiplies all three by one number and lays nothing out
-- itself, so the picture on the page and the ring under your thumb cannot
-- drift: an angle written out a second time is a second rule, and this addon
-- has already paid for one of those in the snippet above.
Bars.SIZE = SIZE

function Bars.RadiusRange()
	return RADIUS_LOW, RADIUS_HIGH
end

function Bars.Radius(count)
	local wanted = tonumber(ns.db.adhocRadius) or RADIUS_LOW
	return math.max(wanted, count * (SIZE + SPACE) / (2 * math.pi))
end

-- Whether that ring is wider than the player asked for, and only because the
-- squares would not fit on the circle they asked for.
function Bars.Packed(count)
	return Bars.Radius(count) > (tonumber(ns.db.adhocRadius) or RADIUS_LOW)
end

function Bars.Where(at, count)
	local angle = (at - 1) * 2 * math.pi / count
	local radius = Bars.Radius(count)
	return radius * math.sin(angle), radius * math.cos(angle)
end

-- Which square a push of dx, dy points at, on a ring of `count`, or nil for a
-- push that has not reached the squares. Square one is at twelve and the rest
-- follow clockwise, and a wedge is centred on its square, which is the half
-- wedge added before the floor. atan2 is handed x first so the angle is
-- measured from straight up toward the right, which is clockwise from twelve.
--
-- `reach` is how far the push has to go, in the same units as dx and dy, and it
-- is the ring's own rather than this file's: Arrange works it out per ring and
-- writes it where both readers of it can get at it. Left off, it is the bare
-- floor, which is what a caller asking only about an angle wants.
--
-- The snippet below does the same sum in the restricted environment. The two
-- are one rule written twice because a snippet cannot call Lua, and
-- 76-adhoc.lua holds them to the same answer at every square.
function Bars.Wedge(dx, dy, count, reach)
	reach = reach or DEAD
	if count < 1 or dx * dx + dy * dy < reach * reach then
		return nil
	end
	local wedge = 360 / count
	return math.floor(((math.deg(math.atan2(dx, dy)) + wedge / 2) % 360) / wedge) + 1
end

--------------------------------------------------------------------------
-- The snippets
--------------------------------------------------------------------------

-- The key's wrap, run with the key as self and the ring as owner, on both
-- edges and before the client's half. The start point goes on the ring as two
-- attributes rather than into the snippet's own scope, so the plain Lua that
-- lights the square under the cursor reads the same two numbers.
--
-- `down` nil is the arm the old key had and the reason is the same: nothing
-- installed proves the client hands a wrap the edge, and a client that hands
-- over nothing would otherwise leave a ring up that never goes away. There the
-- key toggles, a press to open and a press to fire.
--
-- Returning false stops the click before the client's half runs, which is how
-- the press, the dead zone and an empty square all cast nothing. Returning a
-- message is what makes the client run the post body, and the post body is
-- what takes the action back off the key.
local PICK = ([[
	local screen = owner:GetFrameRef("screen")
	if down == nil then
		down = not owner:IsShown()
	end
	if down then
		local x, y = screen:GetMousePosition()
		owner:SetAttribute("wk-from-x", x)
		owner:SetAttribute("wk-from-y", y)
		if x then
			-- The ring opens round the cursor. The offsets are in the ring's
			-- own units and the screen frame's are UIParent's, and the one
			-- number between them is what Arrange leaves on wk-scale: a
			-- snippet cannot ask two frames for their scales and divide.
			local scale = owner:GetAttribute("wk-scale") or 1
			owner:ClearAllPoints()
			owner:SetPoint("CENTER", screen, "BOTTOMLEFT",
				x * screen:GetWidth() * scale, y * screen:GetHeight() * scale)
		end
		owner:Show()
		return false
	end
	if not owner:IsShown() then
		return false
	end
	owner:Hide()
	local x, y = screen:GetMousePosition()
	local fromX, fromY = owner:GetAttribute("wk-from-x"), owner:GetAttribute("wk-from-y")
	local count = owner:GetAttribute("wk-count") or 0
	if not (x and fromX) or count < 1 then
		return false
	end
	local dx = (x - fromX) * screen:GetWidth()
	local dy = (y - fromY) * screen:GetHeight()
	local reach = owner:GetAttribute("wk-reach") or %d
	if dx * dx + dy * dy < reach * reach then
		return false
	end
	local wedge = 360 / count
	local at = floor(((math.deg(math.atan2(dx, dy)) + wedge / 2) %% 360) / wedge) + 1
	local square = owner:GetFrameRef("square" .. at)
	local kind = square and square:GetAttribute("type")
	if not kind then
		return false
	end
	self:SetAttribute("type", kind)
	self:SetAttribute("spell", square:GetAttribute("spell"))
	self:SetAttribute("macro", square:GetAttribute("macro"))
	self:SetAttribute("macrotext", square:GetAttribute("macrotext"))
	return nil, at
]]):format(DEAD)

-- After the cast. A key that kept the last action would fire it again for a
-- stray /click, and a stray /click is how the hover macro reaches a button.
local DISARM = [[
	self:SetAttribute("type", nil)
]]

-- A click on a square, with the square as self and the ring as owner. The
-- message is only there so the client runs the post body: a wrap whose pre body
-- returns nothing never runs its post body, which is SecureHandlers.lua's
-- Wrapped_Click on 2.5.6 read straight, and why the old close never ran.
local CLICKED = [[
	return nil, true
]]

local CLOSE = [[
	owner:Hide()
]]

--------------------------------------------------------------------------
-- Building one
--------------------------------------------------------------------------

-- The item cooldown call, resolved once. Two names across the clients this
-- runs on, and neither is proven by anything installed, so a client with
-- neither draws an item with no swipe rather than an error a tick.
local ItemCooldown = (C_Container and C_Container.GetItemCooldown) or _G.GetItemCooldown

-- One hidden frame over the whole screen, shared by every ring, for the
-- snippet to read the cursor off. A handle answers GetMousePosition as a
-- fraction of its own rectangle and nil outside it, so a frame the size of the
-- screen is one that always answers. Hidden, because it is a ruler and nothing
-- else, and OPie's SCREEN is hidden too. Built on SecureFrameTemplate because a
-- snippet only gets a handle to a protected frame.
local screen

local function Screen()
	if not screen then
		screen = CreateFrame("Frame", "WiggleUIAdHocScreen", UIParent, "SecureFrameTemplate")
		screen:SetAllPoints(UIParent)
		screen:Hide()
	end
	return screen
end

-- What a square says to a hover.
local function Says(w)
	local record = w.record
	if not record then
		return { kind = "note", title = "an empty square",
			lines = { "Drag a spell, an item or a macro here." } }
	end
	return { kind = "note", title = record.name,
		lines = { "Push toward it and let the key go, or click it.",
			"Drop something else on it to replace it." } }
end

-- A drop on a square, off the ring itself. OnReceiveDrag and PostClick both,
-- for the reason Buttons/Square.lua registers both: a spell let go over a
-- square arrives as a drag, and one clicked onto it arrives as a click. Neither
-- is protected, which is why a secure button takes them in plain Lua.
local function Drop(w)
	if type(GetCursorInfo) ~= "function" then
		return
	end
	local kind, a, b, c = GetCursorInfo()
	if not kind then
		return
	end
	local record, why = ns.AdHoc.Carry(kind, a, b, c)
	if not record then
		if why then
			ns.Print(why)
		end
		return
	end
	local ok, refused = ns.AdHoc.Put(w.bar, w.at, record)
	if not ok then
		ns.Print(refused)
		return
	end
	ClearCursor()
end

local function Handle(w)
	ns.Tip.Hang(w, Says, "control")
	w:SetScript("OnReceiveDrag", Drop)
	w:SetScript("PostClick", Drop)
end

-- Where the cursor is, as the same fractions of the screen the snippet reads.
-- The cursor counts from the bottom left of the screen and the screen frame is
-- the whole of it, so the fraction is the cursor over the screen's size and no
-- frame edge comes into it.
local function Cursor()
	local x, y = GetCursorPosition()
	local own = UIParent:GetEffectiveScale()
	return x / (own * GetScreenWidth()), y / (own * GetScreenHeight())
end

-- The square the cursor points at, lit, while the ring is up. Plain Lua on a
-- plain child of the ring: OnUpdate runs only while the ring is shown, and it
-- is never inside the snippet's own call, so nothing it does can reach the
-- cast. It reads the start point the snippet wrote rather than keeping its
-- own, so the lit square and the square that fires are one answer.
local function Aim(entry)
	local x, y = Cursor()
	local fromX, fromY = entry.frame:GetAttribute("wk-from-x"), entry.frame:GetAttribute("wk-from-y")
	local at
	if fromX then
		at = Bars.Wedge((x - fromX) * GetScreenWidth(), (y - fromY) * GetScreenHeight(),
			entry.count, entry.reach)
		if at and not entry.buttons[at].record then
			at = nil
		end
	end
	if at == entry.aimed then
		return
	end
	if entry.aimed then
		entry.buttons[entry.aimed].aim:Hide()
	end
	entry.aimed = at
	ns.AdHocRing.Aim(entry.chrome, at)
	local w = at and entry.buttons[at]
	if w then
		w.aim:Show()
		entry.name:SetText(w.record.name)
		entry.name:SetTextColor(C.heading[1], C.heading[2], C.heading[3])
	else
		-- The bar's own name in the hole, which is the one thing worth saying
		-- while the push has not reached a slice: which ring you are holding.
		entry.name:SetText(entry.label or "")
		entry.name:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
	end
end

Bars.Aim = Aim

local function Aiming(aim)
	Aim(aim.entry)
end

local function Build(index)
	-- The attribute template because the frame is the header every snippet here
	-- runs under, and a header has to carry a secure handler.
	local frame = CreateFrame("Frame", FrameName(index), UIParent, "SecureHandlerAttributeTemplate")
	UI.Adopt(frame, ns.db.adhocZoom)
	frame:SetFrameStrata(STRATA)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameRef("screen", Screen())
	frame:Hide()

	local entry = { index = index, frame = frame, buttons = {}, count = 0 }
	entries[index] = entry

	-- The pie behind the squares: the palette's paper, a seam on every slice
	-- boundary and the hole in the middle a release fires nothing from.
	-- AdHoc/Ring.lua draws it and the settings page draws the same picture at
	-- the size of a settings page.
	entry.chrome = ns.AdHocRing.Dress(frame)

	-- The name of what the cursor points at, in the middle of the ring, and the
	-- plain frame whose OnUpdate keeps it and the lit square current. Sized
	-- against the square rather than written as a number of its own, so the one
	-- line you read while the ring is up grows with the ring.
	local aim = CreateFrame("Frame", nil, frame)
	aim:SetAllPoints()
	aim.entry = entry
	aim:SetScript("OnUpdate", Aiming)
	entry.name = UI.Label(aim, NAME_FONT, nil, "CENTER", UI.SHADOW)
	entry.name:SetPoint("CENTER")

	for at = 1, PER_BAR do
		-- The release, for the reason the action bars give in Buttons/Bars.lua:
		-- a square you drop a spell onto must not cast on the press that starts
		-- the drag.
		local w = Ability.Dress(ns.UI.Press.Button(frame, ButtonName(index, at), "up"),
			Ability.QUIET)
		w.bar, w.at = index, at
		w.aim = ns.Fill(w, "OVERLAY", C.accent[1], C.accent[2], C.accent[3], 0.45)
		w.aim:SetAllPoints()
		w.aim:SetBlendMode("ADD")
		w.aim:Hide()
		if type(frame.WrapScript) == "function" then
			frame:WrapScript(w, "OnClick", CLICKED, CLOSE)
		end
		frame:SetFrameRef("square" .. at, w)
		Handle(w)
		entry.buttons[at] = w
	end

	-- The key, which is a button the ring's snippet arms on the release.
	local key = ns.UI.Press.Held(KeyName(index))
	if type(frame.WrapScript) == "function" then
		frame:WrapScript(key, "OnClick", PICK, DISARM)
		entry.picks = true
	end
	entry.key = key

	ns.Theme.Wear("loadout", frame)
	return entry
end

--------------------------------------------------------------------------
-- Applying the list
--------------------------------------------------------------------------

-- What a press on each square does. A spell by name, an item through /use for
-- the reason Hover/Hover.lua casts one that way, a macro by name. A square
-- past the end of the list is left with no type, so a stray press does nothing
-- rather than whatever the square held last. The key copies these four
-- attributes off the square it picks, so they are the whole of what a square
-- can say.
local function Arm(entry, bar)
	local buttons = bar.buttons
	entry.label = bar.name
	for at = 1, PER_BAR do
		local w = entry.buttons[at]
		local record = buttons[at]
		w.record = record
		w:SetAttribute("type", nil)
		w:SetAttribute("spell", nil)
		w:SetAttribute("macro", nil)
		w:SetAttribute("macrotext", nil)
		if record and record.kind == "spell" then
			w:SetAttribute("type", "spell")
			w:SetAttribute("spell", record.name)
		elseif record and record.kind == "item" then
			w:SetAttribute("type", "macro")
			w:SetAttribute("macrotext", "/use " .. record.name)
		elseif record and record.kind == "macro" then
			w:SetAttribute("type", "macro")
			w:SetAttribute("macro", record.name)
		end
	end
	-- One empty square on a bar with nothing on it, so a ring you just made and
	-- held the key for is a square saying drop something here rather than an
	-- empty disc.
	entry.count = math.max(1, #buttons)
	entry.frame:SetAttribute("wk-count", #buttons)
end

-- The squares on the circle Bars.Where draws, and how far a push has to travel
-- before one of them is picked.
--
-- That is the inner edge of the squares: the push has to reach the ring you are
-- looking at, and a release that never left the middle of it casts nothing. It
-- is measured in the units the snippet measures the push in, which are the
-- screen's and not the ring's, so it goes through UI.Convert rather than being
-- compared across two scales. The ring sits on the pixel grid and UIParent does
-- not, and the two have never been the same number on any screen.
--
-- Worked out here rather than in the snippet because a snippet cannot call Lua
-- or read a saved variable, and written onto the ring as an attribute because
-- that is the one thing both readers of it can get at. Arrange runs on every
-- apply and on every rescale, which is every moment either scale can move.
local function Arrange(entry)
	UI.Adopt(entry.frame, ns.db.adhocZoom)
	local count = entry.count
	local radius = Bars.Radius(count)
	local side = 2 * (radius + SIZE)
	entry.frame:SetSize(side, side)

	entry.reach = math.max(DEAD, UI.Convert(radius - SIZE / 2, entry.frame, UIParent))
	entry.frame:SetAttribute("wk-reach", entry.reach)

	-- One UIParent unit in this ring's units, which is what the snippet
	-- multiplies the cursor by to open the ring round it. Written here for the
	-- reason the reach is: both scales move on a rescale and on a zoom, and
	-- Arrange is what runs on either.
	entry.frame:SetAttribute("wk-scale", UI.Convert(1, UIParent, entry.frame))

	-- The pie under the squares: the same count, the same circle, and the hole
	-- at the same radius the reach was worked out from.
	ns.AdHocRing.Lay(entry.chrome, count, radius, SIZE)

	for at = 1, PER_BAR do
		local w = entry.buttons[at]
		w.aim:Hide()
		if at <= count then
			local x, y = Bars.Where(at, count)
			Ability.Size(w, SIZE)
			w:ClearAllPoints()
			w:SetPoint("CENTER", entry.frame, "CENTER",
				UI.Round(entry.frame, x), UI.Round(entry.frame, y))
			w:Show()
		else
			w:Hide()
		end
	end
	entry.aimed = nil
	entry.name:SetText(entry.label or "")
end

-- Everything protected in one function, so one ns.Lockdown.Held covers the
-- attributes, the anchors and the override bindings.
--
-- Every frame is rewritten from the list every time rather than the one that
-- changed, because deleting a bar shifts every bar under it onto a different
-- frame and a partial pass would leave a key on the wrong one.
function Bars.Apply()
	if ns.Lockdown.Held(Bars.Apply) then
		return false
	end

	local list = ns.AdHoc.All()
	local on = ns.db.adhoc
	for index = 1, MAX do
		local bar = on and list[index] or nil
		local entry = entries[index]
		if bar and not entry then
			entry = Build(index)
		end
		if entry then
			ns.UI.Bound.Drop(entry.key)
			entry.key:SetAttribute("type", nil)
			if bar then
				-- A bar saved before it was a ring carries where it stood, how
				-- many columns it had and whether it closed after a press. None
				-- of the three means anything to a ring.
				bar.point, bar.columns, bar.close = nil, nil, nil
				Arm(entry, bar)
				Arrange(entry)
				ns.UI.Bound.Hold(entry.key, bar.key, KeyName(index))
			else
				entry.frame:Hide()
			end
		end
	end
	return true
end

--------------------------------------------------------------------------
-- The key
--------------------------------------------------------------------------

local function Reads(index, key)
	return ns.UI.Bound.Reads(key, KeyName(index), "LeftButton", false)
end

-- Returns the binding the key was carrying, "" when it carried none, or nil
-- plus a reason when the key cannot be taken. UI/Bound.lua takes it, once this
-- has said whether the bar exists and whether another bar has the key.
function Bars.Bind(index, key)
	local bar = ns.AdHoc.Get(index)
	if not bar then
		return nil, "no such bar."
	end
	key = key or ""
	if key ~= "" then
		for other, each in ipairs(ns.AdHoc.All()) do
			if other ~= index and each.key == key then
				return nil, ("%s already opens %s."):format(key, each.name)
			end
		end
	end

	return ns.UI.Bound.Take(key, function(taken, displaced)
		bar.key = taken
		if displaced then
			bar.displaced = displaced
		end
		Bars.Apply()
	end, function(taken)
		return Reads(index, taken)
	end)
end

function Bars.Describe(index)
	local bar = ns.AdHoc.Get(index)
	if not bar then
		return "unknown"
	end
	return ns.UI.Bound.Describe(bar.key, bar.key ~= "" and Reads(index, bar.key), nil,
		not ns.db.adhoc and "the bars are off" or nil)
end

-- Whether that ring is on the screen right now, or nil for one not built.
function Bars.Visible(index)
	local entry = entries[index]
	if not entry then
		return nil
	end
	return entry.frame:IsShown() and true or false
end

-- How far a push has to travel on that ring before it picks a square, in the
-- units the snippet measures the push in. Nothing in the addon reads it; the
-- page says it in words and the harness pushes by it.
function Bars.Reach(index)
	local entry = entries[index]
	return entry and entry.reach or DEAD
end

-- Whether the client gave this ring the wrap that picks a square on the
-- release. A client with no WrapScript opens nothing.
function Bars.CanPick(index)
	local entry = entries[index]
	return entry ~= nil and entry.picks == true
end

function Bars.Pending()
	return ns.Lockdown.Owed(Bars.Apply)
end

-- The entry, for the harness. Nothing in the addon reads it.
function Bars.Entry(index)
	return entries[index]
end

--------------------------------------------------------------------------
-- The tick
--
-- Only the bars on the screen are drawn, and most of the time that is none of
-- them, so the pass is a walk over six entries and back. A bar that is up is
-- drawn ten times a second, the rate the cloned bars draw range and count at.
--------------------------------------------------------------------------

local function Draw(entry)
	for at = 1, entry.count do
		local w = entry.buttons[at]
		local record = w.record
		if not record then
			Ability.Draw(w, nil, "empty")
		elseif record.kind == "spell" then
			local status, start, duration = ns.Castable.State(record.name)
			Ability.Draw(w, record.icon, status, start, duration)
		elseif record.kind == "item" then
			local count = ns.ItemCount(record.name)
			local start, duration
			if record.id and ItemCooldown then
				start, duration = ItemCooldown(record.id)
			end
			Ability.Draw(w, record.icon, count > 0 and "ready" or "unknown", start, duration, count)
		else
			Ability.Draw(w, record.icon, "ready")
		end
	end
end

function Bars.Update()
	for index = 1, MAX do
		local entry = entries[index]
		if entry and entry.frame:IsShown() then
			Draw(entry)
		end
	end
end

UI.Ticker(UI.Forever, 0.1, "adhoc", Bars.Update)

--------------------------------------------------------------------------
-- Events
--
-- PLAYER_LOGIN rather than ADDON_LOADED, because the binding set the overrides
-- land on top of is not built until then.
--------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", Bars.Apply)

-- And again every time the client rebuilds its binding set, which throws every
-- override away, including the one taken at PLAYER_LOGIN a moment earlier. See
-- ns.Rebind in Core/Core.lua.
ns.Rebind(Bars.Apply)

-- A resolution change moves every size at once, the same way it moves the
-- cooldown row.
UI.OnRescale(Bars.Apply)
