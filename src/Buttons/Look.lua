local ADDON, ns = ...

local Look = {}
ns.BarLook = Look

local UI = ns.UI

--------------------------------------------------------------------------
-- What one bar looks like, and when it is up
--
-- The third question about a cloned bar. Buttons/Which.lua answers which bars
-- there are and which of them you want, Buttons/Placing.lua answers where one
-- goes, and this answers what shape it is, how much of its ground shows and
-- whether it is on the screen at all right now. What colour that ground is
-- belongs to the theme, not to one bar.
--
-- Its own file for the reason those two are theirs. Buttons/Bars.lua is what a
-- bar is made of: twelve secure buttons, the slots they press, the keys they
-- answer to and the client's own buttons hidden behind them. None of that
-- changes when you ask for three rows instead of one, and none of what is in
-- here knows what an action slot is.
--
-- Every setting is per bar and every one of them has a default that is not a
-- setting. The shape's default is the plan's `columns` in Which.lua and both
-- visibility answers default to no. So a bar nobody has touched
-- carries no record at all, `ns.db.barLook` is empty on a fresh install, and
-- `actionbars plain` is a deletion rather than a write. That is the shape
-- Which.lua already uses for the tick boxes and the argument is the same one:
-- the shipping state travels with a clone of the repo, and a saved variable
-- that merely restates it is a saved variable that can drift from it.
--
-- Two of the five cannot be done from Lua at all, which is why they are here
-- rather than in a switch somewhere.
--
--   Hiding a bar in combat. Everything inside a bar is a secure button, and a
--   frame with one of those under it cannot be shown or hidden while the
--   client is in lockdown. Combat starting is exactly the moment you would
--   want to, so the only path is a visibility state driver: the client
--   evaluates the macro conditions itself, inside the restricted environment,
--   and does the hiding on its own account. Same machinery as the page driver
--   in Bars.lua and the charge key's binder, and probed the same way, because
--   nothing installed here proves it is on 2.5.6.
--
--   Showing a bar while a key is held. The same driver, on `[mod:shift]`
--   rather than on `[combat]`. A key held is not an event Lua is told about
--   often enough to drive a frame off, and hiding on the up edge would be a
--   protected call again the moment you were in a fight.
--------------------------------------------------------------------------

-- Twelve, the same twelve Buttons/Bars.lua lays out. Written here as well
-- because this file loads first and the shape arithmetic is the whole of what
-- it does: the rows below are the ways twelve breaks into a rectangle.
local SLOTS = 12

-- The shapes twelve buttons make. Every one of these divides twelve, because a
-- last row with a gap on the end of it is not a bar, it is a bar and a stump.
-- One row is the bar every client ships, twelve rows is the column down the
-- side of the screen, and the four between them are the same twelve buttons
-- folded.
Look.ROWS = { 1, 2, 3, 4, 6, 12 }

-- A bar that is not twelve says so in `slots`, which is the pet bar's ten, and
-- its shapes are the ways ten breaks into a rectangle for the same reason.
local function Slots(def)
	return def.slots or SLOTS
end

-- The shapes one bar can take: Look.ROWS for the plan's twelve, worked out for
-- anything else rather than written as a second table that could disagree.
function Look.Shapes(def)
	local slots = Slots(def)
	if slots == SLOTS then
		return Look.ROWS
	end
	local shapes = {}
	for rows = 1, slots do
		if slots % rows == 0 then
			shapes[#shapes + 1] = rows
		end
	end
	return shapes
end

-- 27, and it is not a taste decision. UI.IconSizes answers { 54, 27 } on this
-- client: an icon is stored at 64 texels, the crop that takes the border baked
-- into every one of them off leaves 54, and the client keeps each copy at half
-- the size of the one above. Those two are the only drawn sizes where one
-- stored texel lands on one pixel. 32 and 36, which is what every bar addon
-- ships, are the client blending two copies, and halfway between two of them is
-- the worst place to stand.
--
-- It is a setting anyway, and the two facts sit together rather than one
-- winning. A bar you want out of the way at the edge of the screen is worth
-- more small than it is worth sharp, and a bar you press all night is worth
-- more sharp than it is worth any particular size. So the default is the sharp
-- one, the range covers both of them, the step is one pixel so neither can be
-- stepped over, and Look.Sharp says which is which rather than the panel
-- pretending every stop is as good as the next.
local DEFAULT_SIZE = 27
local SIZE_LOW, SIZE_HIGH = 16, 54

-- The key's font, in whole pixels, for the reason Ability.Size floors every
-- string on a square: a glyph at a fractional size is rasterised across two
-- rows. One pixel is therefore the finest step there is, and the range is kept
-- to what a key can be on a square so every stop on the slider is a few
-- pixels of drag apart. Seven is the floor the square already had; 32 is a
-- key a little over the 28 a 54px square gives it.
local KEY_LOW, KEY_HIGH = 7, 32

-- Ninety five rather than the ninety seven the window colour carries, because
-- the opacity control is in fives and a stop the panel cannot reach is a
-- number nobody can put back. Two hundredths of an alpha on a background is
-- not a look anybody has ever seen.
local DEFAULT_ALPHA = 95

-- Which key holds a bar on the screen. `none` is the shipping answer and means
-- the bar is up on its own account; the other three are the modifiers the
-- client's macro conditionals name, which is what the driver below is written
-- in. There is no fourth: `[mod:shift]` and its two siblings are the whole of
-- what a state driver can ask about the keyboard.
Look.KEYS = {
	{ key = "none", label = "no key" },
	{ key = "shift", label = "shift" },
	{ key = "ctrl", label = "ctrl" },
	{ key = "alt", label = "alt" },
}

--------------------------------------------------------------------------
-- The record
--------------------------------------------------------------------------

-- One bar's decisions, or nil where it has none. `make` builds one, and only a
-- setter passes it, so reading a bar never writes to the saved variables.
local function Record(def, make)
	if not (ns.db and ns.db.barLook) then
		return nil
	end
	local record = ns.db.barLook[def.key]
	if not record and make then
		record = {}
		ns.db.barLook[def.key] = record
	end
	return record
end

local function Field(def, name)
	local record = Record(def)
	return record and record[name]
end

-- One field written, or dropped where it is the default again.
--
-- Dropped rather than stored, so "no record" and "the plan" stay the same
-- sentence. Stored, a bar you folded and unfolded would carry a row count that
-- says what the plan says, `Decided` would count it, and the button that puts
-- every bar back to plain would offer to undo nothing. A record with nothing
-- left in it goes with it, for the same reason.
local function Write(def, name, value, fallback)
	local record = Record(def, value ~= fallback)
	if not record then
		return ns.db ~= nil and ns.db.barLook ~= nil
	end
	record[name] = value ~= fallback and value or nil
	if next(record) == nil then
		ns.db.barLook[def.key] = nil
	end
	return true
end

--------------------------------------------------------------------------
-- The shape
--------------------------------------------------------------------------

-- How many rows the twelve are laid out in. The plan's own columns are the
-- default, so bar 1 ships as one row of twelve and the two side bars as six
-- rows of two, which is what the client draws them as.
function Look.Rows(def)
	return Field(def, "rows") or (Slots(def) / def.columns)
end

function Look.Columns(def)
	return Slots(def) / Look.Rows(def)
end

-- Whether a row count is one of the six. Not a clamp: a number that is not a
-- shape has to be refused where it was typed, because rounding 5 to 6 quietly
-- is how a macro comes to say something it does not do.
function Look.IsShape(def, rows)
	local shapes = Look.Shapes(def)
	for index = 1, #shapes do
		if shapes[index] == rows then
			return true
		end
	end
	return false
end

function Look.SetRows(def, rows)
	if not Look.IsShape(def, rows) then
		return false
	end
	return Write(def, "rows", rows, Slots(def) / def.columns)
end

-- The panel's stepper counts in ones and only six of the twelve numbers it can
-- reach are a shape, so the direction of travel is what decides rather than
-- which number was landed on. Up takes the next shape above the one you are
-- standing in, down takes the next below. Without that, +1 from four lands on
-- five, five snaps to the nearest, and the nearest is four again: a control
-- that does nothing on every second press.
function Look.StepRows(def, value)
	local shapes = Look.Shapes(def)
	local current = Look.Rows(def)
	local rows = current
	if value > current then
		for index = 1, #shapes do
			if shapes[index] > current then
				rows = shapes[index]
				break
			end
		end
	elseif value < current then
		for index = #shapes, 1, -1 do
			if shapes[index] < current then
				rows = shapes[index]
				break
			end
		end
	end
	return Look.SetRows(def, rows)
end

--------------------------------------------------------------------------
-- Cloned from another bar
--
-- A bar can take its square, its key and its background from another bar and
-- keep taking them: `from` names the bar, and the three readers below ask
-- that bar instead. Rows are not in it, since ten squares and twelve do not
-- fold the same way, and neither is anything a key presses.
--
-- Setting any of the three on a cloned bar ends the clone. The bar keeps what
-- it was showing and changes the one thing you moved, rather than the other
-- two jumping back to whatever it carried before.
--------------------------------------------------------------------------

-- The bar whose look this one shows: itself, or the end of its `from` chain.
-- SetFrom refuses a loop, and the bound is there for a saved variable that
-- holds one anyway.
function Look.Source(def)
	for _ = 1, 8 do
		local from = Field(def, "from")
		local source = from and Look.Find(from)
		if not source or source == def then
			return def
		end
		def = source
	end
	return def
end

-- The key of the bar this one clones, or "none".
function Look.From(def)
	return Field(def, "from") or "none"
end

-- The clone ended, with the source's three values written into this bar so
-- nothing on the screen moves.
local function Unlink(def)
	if not Field(def, "from") then
		return
	end
	local source = Look.Source(def)
	local size = Field(source, "size")
	local key = Field(source, "keySize")
	local alpha = Field(source, "alpha")
	Write(def, "from", nil, nil)
	Write(def, "size", size or DEFAULT_SIZE, DEFAULT_SIZE)
	Write(def, "keySize", key, nil)
	Write(def, "alpha", alpha or DEFAULT_ALPHA, DEFAULT_ALPHA)
end

-- Clone another bar's look, or "none" to stop. Refused for the bar itself, for
-- a name that is no bar, and for a bar that already clones this one, which
-- would be a loop with no look at either end.
function Look.SetFrom(def, key)
	if key == "none" then
		Unlink(def)
		return true
	end
	local source = Look.Find(key)
	if not source or source == def or Look.Source(source) == def then
		return false
	end
	Write(def, "size", nil, nil)
	Write(def, "keySize", nil, nil)
	Write(def, "alpha", nil, nil)
	return Write(def, "from", source.key, nil)
end

-- One square's edge, in pixels.
function Look.Size(def)
	return Field(Look.Source(def), "size") or DEFAULT_SIZE
end

-- The range the panel and the slash word both clamp to, handed out rather than
-- written twice, which is the rule ns.FrameSkin.LinkRange already states.
function Look.SizeRange()
	return SIZE_LOW, SIZE_HIGH
end

function Look.SetSize(def, size)
	if size < SIZE_LOW or size > SIZE_HIGH or size ~= math.floor(size) then
		return false
	end
	Unlink(def)
	return Write(def, "size", size, DEFAULT_SIZE)
end

-- The key's font size on one bar's squares. Unset, it follows the square, which
-- is the size it has always been drawn at.
function Look.KeySize(def)
	return Field(Look.Source(def), "keySize") or UI.Ability.KeySize(Look.Size(def))
end

-- Whether the bar's key is its own number rather than the square's share.
-- Asked by the layout, which passes nil on to Ability.Size for a bar that has
-- not decided, so resizing the square still resizes its key.
function Look.KeyDecided(def)
	return Field(Look.Source(def), "keySize")
end

function Look.KeyRange()
	return KEY_LOW, KEY_HIGH
end

-- Stored even where it equals the share, unlike every other field here. A key
-- set to 14 on a 27px square and dropped as the default would grow the moment
-- the square did, which is the one thing a player who set it did not ask for.
function Look.SetKeySize(def, size)
	if size < KEY_LOW or size > KEY_HIGH or size ~= math.floor(size) then
		return false
	end
	Unlink(def)
	return Write(def, "keySize", size, nil)
end

-- Whether a stored icon texel lands on a screen pixel at that size, which is
-- true of exactly two sizes and is what the readout says out loud. Asked of
-- UI.IconSizes rather than compared against 27 and 54, because that function is
-- where the crop and the halving are worked out and a second copy of the answer
-- would be a second thing to get wrong.
function Look.Sharp(size)
	for _, sharp in ipairs(UI.IconSizes()) do
		if sharp == size then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------
-- The paint
--------------------------------------------------------------------------

function Look.Alpha(def)
	return Field(Look.Source(def), "alpha") or DEFAULT_ALPHA
end

function Look.SetAlpha(def, alpha)
	if alpha < UI.ALPHA_LOW or alpha > UI.ALPHA_HIGH then
		return false
	end
	Unlink(def)
	return Write(def, "alpha", alpha, DEFAULT_ALPHA)
end

-- Paint one built bar with what the two above say.
--
-- The hairline follows the background, which is Feeds/Stream.lua's rule and is
-- right for the same reason: at nothing the player has asked for squares over
-- the world, and a rectangle of hairline round nothing is a window frame with
-- no window in it.
--
-- A palette with a painting draws its floor under the squares instead of the
-- flat colour, at the bag window's scale so the two read as one floor, and at
-- the same alpha the flat colour would have had. Built on the first paint and
-- laid out on every one, because Paint runs after every Arrange and the
-- arrange is what decides the bar's size.
function Look.Paint(entry)
	local frame = entry.frame
	if not (frame and frame.bg) then
		return false
	end
	local color = UI.Color.window
	local alpha = Look.Alpha(entry.def) / 100
	if frame.floor == nil then
		frame.floor = UI.Backdrop(frame, { frame = false }) or false
	end
	if frame.floor then
		frame.floor:Layout(ns.Measure(frame, "GetWidth") or 0, ns.Measure(frame, "GetHeight") or 0)
		frame.floor:SetAlpha(alpha)
		frame.bg:SetColorTexture(color[1], color[2], color[3], 0)
	else
		frame.bg:SetColorTexture(color[1], color[2], color[3], alpha)
	end
	if frame.edges then
		for index = 1, 4 do
			frame.edges[index]:SetAlpha(alpha > 0 and 1 or 0)
		end
	end
	return true
end

--------------------------------------------------------------------------
-- When it is up
--------------------------------------------------------------------------

function Look.Combat(def)
	return Field(def, "combat") and true or false
end

function Look.SetCombat(def, value)
	return Write(def, "combat", value and true or false, false)
end

function Look.Key(def)
	return Field(def, "key") or Look.KEYS[1].key
end

function Look.KeyLabel(def)
	local wanted = Look.Key(def)
	for index = 1, #Look.KEYS do
		if Look.KEYS[index].key == wanted then
			return Look.KEYS[index].label
		end
	end
	return Look.KEYS[1].label
end

function Look.SetKey(def, key)
	for index = 1, #Look.KEYS do
		if Look.KEYS[index].key == key then
			return Write(def, "key", key, Look.KEYS[1].key)
		end
	end
	return false
end

-- The macro conditions the client evaluates for itself, or nil where the bar is
-- simply up.
--
-- A key beats the combat switch rather than being read alongside it, and that
-- is a decision rather than a shortcut. A bar you hold a key for is off unless
-- you are holding the key, in a fight or out of one, so there is nothing left
-- for a combat rule to decide: `[mod:shift] show; [combat] hide; show` would
-- mean a bar that is up all the time except in combat, which is the other
-- setting wearing this one's name.
--
-- A bar with `needs` is down without it before anything else is asked, which is
-- the pet bar and `[nopet] hide`. Such a bar always has a macro, because being
-- up only with a pet out is already a condition the client has to evaluate.
function Look.Visibility(def)
	local gate = def.needs and ("[no%s] hide; "):format(def.needs) or ""
	local key = Look.Key(def)
	if key ~= Look.KEYS[1].key then
		return ("%s[mod:%s] show; hide"):format(gate, key)
	end
	if Look.Combat(def) then
		return gate .. "[combat] hide; show"
	end
	if def.needs then
		return gate .. "show"
	end
	return nil
end

-- Whether this client can hide a bar on its own account at all. Probed rather
-- than assumed, the way Bars.lua probes the page driver: on a client with no
-- state driver a bar is simply always up, and Describe says so rather than the
-- two switches quietly doing nothing.
function Look.CanDrive()
	return type(RegisterStateDriver) == "function"
		and type(UnregisterStateDriver) == "function"
end

function Look.Unwatch(entry)
	if entry.watching and Look.CanDrive() then
		pcall(UnregisterStateDriver, entry.frame, "visibility")
	end
	entry.watching = nil
end

-- Hand one bar's visibility to the client, or take it back. Returns the macro
-- that is now driving it, or nil where nothing is.
--
-- Always through Unwatch first, because a driver registered twice on one frame
-- is two answers to the same question and the client keeps both.
function Look.Watch(entry)
	Look.Unwatch(entry)
	local macro = Look.Visibility(entry.def)
	if not macro or not Look.CanDrive() then
		return nil
	end
	if not pcall(RegisterStateDriver, entry.frame, "visibility", macro) then
		return nil
	end
	entry.watching = macro
	return macro
end

--------------------------------------------------------------------------
-- What has been decided
--------------------------------------------------------------------------

-- How many bars carry a look of their own rather than the plan's.
function Look.Decided()
	local count = 0
	if ns.db and ns.db.barLook then
		for _ in pairs(ns.db.barLook) do
			count = count + 1
		end
	end
	return count
end

-- The colour a bar used to carry, dropped at login. It went to the theme on
-- 2026-09-19, and a record holding nothing else would count as a decision in
-- Decided and give Plain something to undo that nothing on screen shows.
function Look.Retire()
	if not (ns.db and ns.db.barLook) then
		return 0
	end
	local dropped = 0
	for key, record in pairs(ns.db.barLook) do
		if record.color ~= nil then
			record.color = nil
			dropped = dropped + 1
		end
		if next(record) == nil then
			ns.db.barLook[key] = nil
		end
	end
	return dropped
end

-- Drop every one of them, so every bar is the plan again. The counterpart
-- of Which.Follow, and a deletion for the same reason.
function Look.Plain()
	if not (ns.db and ns.db.barLook) then
		return 0
	end
	local dropped = 0
	for key in pairs(ns.db.barLook) do
		ns.db.barLook[key] = nil
		dropped = dropped + 1
	end
	return dropped
end

-- The modifiers as a typed list, for the slash word that refuses a value.
-- Built rather than written out, because a list in a message that does not
-- match the table above is a message that lies.
function Look.Keys()
	local names = {}
	for index = 1, #Look.KEYS do
		names[index] = Look.KEYS[index].key
	end
	return table.concat(names, ", ")
end

-- Which bar a typed word means: the plan's own key, or the label a tab in the
-- panel carries. Both, because `actionbars rows bottomleft 3` is what a macro
-- says and "bottom left" is what the panel calls it.
function Look.Find(word)
	if type(word) ~= "string" or word == "" then
		return nil
	end
	local wanted = word:lower()
	local tabs = Look.Tabs()
	for index = 1, #tabs do
		local def = tabs[index]
		if def.key:lower() == wanted or def.tab:lower() == wanted
			or def.label:lower() == wanted then
			return def
		end
	end
	return nil
end

-- What shape one bar is, in a phrase. One of the two readouts on the panel's
-- page and the first line of the tooltip on a bar's drag handle.
function Look.Shape(def)
	local rows = Look.Rows(def)
	local size = Look.Size(def)
	local source = Look.Source(def)
	return ("%d row%s of %d at %dpx%s, ground at %d%%%s"):format(
		rows, rows == 1 and "" or "s", Look.Columns(def), size,
		Look.Sharp(size) and "" or ", blended", Look.Alpha(def),
		source == def and "" or (", cloned from " .. source.label))
end

-- And when it is on the screen, which is the other readout and is a different
-- question with a different answer. Split because a reading on that page is one
-- line that never wraps, and because the two are set by different controls.
function Look.Hours(def)
	local key = Look.Key(def)
	local line = "always up"
	local driven = true
	if key ~= Look.KEYS[1].key then
		line = ("up only while %s is held"):format(key)
	elseif Look.Combat(def) then
		line = "down in combat"
	else
		driven = false
	end
	if driven and not Look.CanDrive() then
		line = line .. ", except this client cannot, so it stays up"
	end
	if def.needs then
		line = ("%s, with a %s out"):format(line, def.needs)
	end
	return line
end

-- The same across every bar that is standing, for /wk status and the panel's
-- one line on the clone. nil where none of them has been given hours, which is
-- the shipping state and the common one.
function Look.Summary(order)
	local keyed, hidden = 0, 0
	for index = 1, #order do
		local def = order[index].def
		if Look.Key(def) ~= Look.KEYS[1].key then
			keyed = keyed + 1
		elseif Look.Combat(def) then
			hidden = hidden + 1
		end
	end
	if keyed == 0 and hidden == 0 then
		return nil
	end
	local parts = {}
	if keyed > 0 then
		parts[#parts + 1] = ("%d wait%s on a key"):format(keyed, keyed == 1 and "s" or "")
	end
	if hidden > 0 then
		parts[#parts + 1] = ("%d go%s down in combat"):format(hidden, hidden == 1 and "es" or "")
	end
	if not Look.CanDrive() then
		parts[#parts + 1] = "and this client has no state driver, so neither happens"
	end
	return table.concat(parts, ", ")
end

--------------------------------------------------------------------------
-- Which bar the panel is showing, said on the screen
--
-- A tab strip that says "bottom left bar" names a bar you then have to find by
-- counting, and the two on the right of the screen are a pair of identical
-- columns. So while the options window is open, whichever bar its strip is on
-- wears an accent rim, in the colour the selected tab is marked in, so the two
-- read as one thing.
--
-- Outside the bar rather than on it. A rim drawn on the bar's own edge covers
-- the hairline already there and reads as the bar having changed colour, which
-- is the row above pretending to have moved.
--
-- It goes down with the window. A mark that outlived the panel would be an
-- accent rectangle round one bar for the rest of the session with nothing on
-- screen to say why, and the buttons feature's `showing` hook is what takes it
-- off.
--------------------------------------------------------------------------

-- Two physical pixels and two out from the bar. Every other line this addon
-- draws is a hairline, which is right for a border and wrong for a highlight: a
-- highlight you have to look for is not one.
local RIM, RIM_GAP = 2, 2

local marking = false

local function Rim(entry)
	if entry.rim then
		return entry.rim
	end
	local accent = UI.Color.accent
	local rim = CreateFrame("Frame", nil, entry.frame)
	rim:SetPoint("TOPLEFT", -RIM_GAP, RIM_GAP)
	rim:SetPoint("BOTTOMRIGHT", RIM_GAP, -RIM_GAP)
	rim.edges = ns.Outline(rim, accent[1], accent[2], accent[3], 1)
	ns.EdgeSize(rim.edges, ns.Pixel(rim) * RIM)
	rim:Hide()
	entry.rim = rim
	return rim
end

-- Whether the window that does the marking is up.
function Look.Marking(open)
	marking = open and true or false
	return marking
end

function Look.Marked()
	return marking
end

-- The rim on the bar the page is on and off every other one. Called when the
-- window opens or closes, when the strip picks another bar, and on every apply,
-- because a bar built while the window was open has to arrive marked or not on
-- its own account.
--
-- Built on demand, so a player who never opens that page never pays for five
-- frames, and asked for at all only where there is one already or one is
-- wanted.
function Look.Mark(order)
	local chosen = Look.Chosen()
	for index = 1, #order do
		local entry = order[index]
		local wanted = marking and entry.def == chosen
		if wanted or entry.rim then
			Rim(entry):SetShown(wanted)
		end
	end
end

--------------------------------------------------------------------------
-- Which bar the panel is showing
--
-- Not a saved setting. It is which tab is in front while the window is open,
-- which is the same thing ns.People.Shown answers and is kept the same way.
--------------------------------------------------------------------------

-- The plan's five and the pet bar after them. The pet bar is not in the plan,
-- for the reason Buttons/Pet.lua gives, but it is a bar you shape and paint the
-- same way, so it has a tab. Built on each call rather than once, because this
-- file loads before Pet.lua.
function Look.Tabs()
	local tabs = {}
	for index = 1, #ns.WhichBars.PLAN do
		tabs[index] = ns.WhichBars.PLAN[index]
	end
	if ns.PetBar then
		tabs[#tabs + 1] = ns.PetBar.DEF
	end
	return tabs
end

local shown = 1

function Look.Shown()
	if shown > #Look.Tabs() then
		shown = 1
	end
	return shown
end

function Look.Show(index)
	if index >= 1 and index <= #Look.Tabs() then
		shown = index
	end
	return shown
end

function Look.Chosen()
	return Look.Tabs()[Look.Shown()]
end
