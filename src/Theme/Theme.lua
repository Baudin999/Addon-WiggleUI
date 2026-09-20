local ADDON, ns = ...

local UI = ns.UI
local Themes = ns.Themes
local Palettes = ns.Palettes

local Theme = {}
ns.Theme = Theme

--------------------------------------------------------------------------
-- The theme and the palette, applied once at load
--
-- Themes.lua says what each theme does to each element and the palette files
-- say what colour the addon is. This file reads both saved choices at
-- ADDON_LOADED, paints the palette into UI.Color before any part has built a
-- frame, and dresses each element's frame as the part that owns it hands it
-- over with Theme.Wear.
--
-- Nothing here runs after that. A change of theme or palette is written to the
-- saved variables and drawn at the next /reload, because a live switch would
-- mean every window repainting itself on a signal and every part listening for
-- one, and the theme's promise is that it costs nothing once you are in the
-- world. Two exceptions. The frames being placed: /wui unlock brings every
-- element up so it can be dragged, and locking puts the theme back. And the
-- wiggle: a shake of the mouse swaps the theme for the one it is set to wiggle
-- to, and the next shake swaps it back.
--------------------------------------------------------------------------

-- The palettes in the order the options page cycles them. Every palette file
-- has to be on this list and the list may hold nothing else, which the load
-- checks below hold it to.
Theme.PALETTES = { "dark", "forest", "desert", "arcane", "horde", "alliance", "fire", "parchment" }

--------------------------------------------------------------------------
-- The tables are checked where they are read
--
-- A theme missing an element would leave that element to whatever the code
-- happened to do with a nil, which is the undecided cell Themes.lua refuses. A
-- palette missing a colour would leave dark's entry standing in the middle of
-- a forest. Both are load errors, which the harness raises.
--------------------------------------------------------------------------

local known = {}
for _, element in ipairs(Themes.ELEMENTS) do
	assert(not known[element.key], ("the element %q is listed twice"):format(element.key))
	known[element.key] = element
end

local function Valid(mode)
	return mode == "show" or mode == "hide" or mode == "hover"
		or (type(mode) == "number" and mode > 0 and mode < 1)
end

local themed = {}
for _, name in ipairs(Themes.ORDER) do
	local theme = Themes[name]
	assert(type(theme) == "table", ("the theme %q has no table"):format(name))
	assert(Themes.LABEL[name], ("the theme %q has no label"):format(name))
	for key in pairs(known) do
		assert(Valid(theme[key]),
			("the theme %q says %s for %q, which is not show, hide, hover or a fraction")
				:format(name, tostring(theme[key]), key))
	end
	for key in pairs(theme) do
		assert(known[key], ("the theme %q names %q, which is not an element"):format(name, key))
	end
	themed[name] = theme
end

-- One level of a palette against the same level of dark: the top, which is
-- UI.Color's, and the unit table under it, which is Unit.Color's.
local function Match(name, colours, reference, level)
	assert(type(colours) == "table", ("the palette %q has no %s table"):format(name, level))
	for key in pairs(reference) do
		assert(colours[key], ("the palette %q has no %s colour for %q"):format(name, level, key))
	end
	for key in pairs(colours) do
		assert(reference[key],
			("the palette %q colours %s %q, which dark does not"):format(name, level, key))
	end
end

local listed = {}
for _, name in ipairs(Theme.PALETTES) do
	local palette = Palettes[name]
	assert(type(palette) == "table", ("the palette %q has no file"):format(name))
	Match(name, palette, Palettes.dark, "window")
	Match(name, palette.unit, Palettes.dark.unit, "unit")
	listed[name] = true
end
local rails = {}
for _, style in ipairs(Themes.RAILS) do
	rails[style] = true
end
for name, style in pairs(Themes.RAIL) do
	assert(themed[name], ("Themes.RAIL names %q, which is not a theme"):format(name))
	assert(rails[style],
		("Themes.RAIL draws %s as %s, which is not a rail style"):format(name, tostring(style)))
end

for name in pairs(Palettes) do
	assert(listed[name], ("the palette %q is not on Theme.PALETTES"):format(name))
end

-- A painting is optional and belongs to a palette on the list, and one that is
-- there has all nine pieces, each a path and a drawn size. A painting under a
-- misspelt palette would never be drawn and nothing would say so; a piece
-- missing would be a hole in the frame at one corner of one window.
for name, art in pairs(ns.Backdrops) do
	assert(listed[name], ("the painting %q is for no palette on Theme.PALETTES"):format(name))
	for key in pairs(UI.BACKDROP_PIECES) do
		local piece = art[key]
		assert(type(piece) == "table" and type(piece[1]) == "string"
			and type(piece[2]) == "number" and piece[2] > 0
			and type(piece[3]) == "number" and piece[3] > 0,
			("the painting %q has no %s piece with a path and a size"):format(name, key))
	end
	assert(type(art.corner) == "number" and type(art.thickness) == "table",
		("the painting %q has no corner or thickness"):format(name))
end

--------------------------------------------------------------------------
-- What was chosen, and what is drawn
--------------------------------------------------------------------------

-- The theme and palette this session was loaded with. The saved choice can
-- move away from these in the options window, and the difference is what the
-- reload button is for.
local drawnTheme, drawnPalette

-- The theme on the screen this moment: drawnTheme's table at rest, its wiggle
-- target's while the wiggle is up. Every read of a mode goes through this, so
-- a part asking from a ticker follows a wiggle without being told.
local chosen, showing

function Theme.Drawn()
	return drawnTheme, drawnPalette
end

-- How a gauge is drawn: flat, the fill as one colour and a hairline round
-- everything, or modern, a sheen down the fill, the bars of one unit stacked
-- with no line between them and the unit's edge in the palette's dark.
--
-- Drawn at the reload like the palette and for its reason, and read through
-- here rather than off ns.db by the parts that draw it. A relayout runs
-- whenever a size slider moves, and one reading the saved choice would draw
-- the new look's spacing round the old look's fills until the reload.
Theme.BAR_LOOKS = { "flat", "modern" }

local drawnLook

function Theme.Modern()
	return drawnLook == "modern"
end

-- Whether the player, pet, target and target of target blocks draw their
-- portrait. Off, the block keeps its width and the bars take the square's room.
-- Drawn at the reload with the bar look, for the same reason.
local drawnPortraits

function Theme.Portraits()
	return drawnPortraits ~= false
end

-- What the theme loaded with this session does to one element. Informational
-- until the saved variables arrive, which is what a part building a frame at
-- file scope would want: the frame as drawn, dressed a moment later.
--
-- Asked from a ticker by the Charge marker, so the miss is an if rather than
-- an assert, which would build its message on every call.
local function Chosen(key)
	local theme = chosen or Themes.informational
	if theme[key] == nil then
		error(("%q is not an element in Themes.lua"):format(tostring(key)), 3)
	end
	return theme
end

function Theme.Mode(key)
	return Chosen(key)[key]
end

-- Whether an element is off the screen in the theme showing this moment.
--
-- The question the three parts that ask anything actually ask, and until a
-- theme of your own existed they asked it by comparing Theme.Mode against
-- "hide", which was the whole vocabulary. It is not any more: a cell drawn at
-- nothing with no pointer to bring it back is hidden by every measure a caller
-- cares about, and a cell that says "hide" in a fight is not hidden now.
function Theme.Hidden(key)
	local _, _, hidden = Themes.Cell(Chosen(key), key)
	return hidden
end

--------------------------------------------------------------------------
-- Dressing a frame
--------------------------------------------------------------------------

local worn = {} -- { key, frame } for every frame a part has handed over

-- The theme a wiggle swaps in, nil when the drawn theme wiggles to nothing,
-- and whether it is the one up. See the wiggle, below.
local rest, target, drawnTarget
local pinned = false

-- The theme the creator page is editing, drawn over both of those for as long
-- as that page has it open, and whether the page is holding every element up
-- so you can point at one. See Theme.Try and Theme.Showcase below the wiggle,
-- which is the machinery both are built on.
local trying, showcase = nil, false

-- Whether a fight is on. Read off the two events at the foot of this file
-- rather than from InCombatLockdown at each frame, because a pass walks every
-- worn frame and the answer is the same for all of them, and whether the pass
-- has to happen at all is one comparison against the theme.
local fighting, fights = false, false

-- Every frame a part has handed over, in the order they were worn, for the
-- page that draws a rim round each one so you can pick the element you mean.
-- One element may be several frames: the action bars are, and so is the
-- minimap, and each is a separate rim over the same key.
function Theme.Worn(each)
	for index = 1, #worn do
		each(worn[index].key, worn[index].frame)
	end
end

-- Whether an element can leave its frame as drawn for the whole session: as
-- drawn at rest and as drawn in the target, at every moment of both. Every
-- other element is veiled when it is worn, because a protected frame cannot
-- take its veil in a fight, and a wiggle or a pull in the middle of one has to
-- find the action bars already under theirs.
local function Untouched(key)
	return Themes.Plain(rest, key) and (not target or Themes.Plain(target, key))
end

-- Two writes a fight refuses on a protected frame: taking the veil, and
-- showing or hiding it, because a veil over a protected frame is protected
-- itself. Its alpha and the catcher, an insecure child, are not, so a frame
-- already veiled and already on the screen is redressed in a fight like out
-- of one. That is the wiggle between exploration and informational in the
-- middle of a pull: the bars go from under the pointer to shown and back on
-- alpha alone. Anything more waits for the end of the fight.
local function Dress(frame, key)
	local alpha, hover, hidden, combat = Themes.Cell(chosen, key)
	if fighting and combat then
		alpha = combat
	end
	local veil = UI.Veiled(frame)
	if alpha == 1 and not hover and not hidden and not veil and Untouched(key) then
		return true
	end
	local blocked = ns.Blocked(frame)
	if not veil then
		if blocked then
			return false
		end
		veil = UI.Veil(frame)
		if not veil then
			return false
		end
	end
	-- Held up: while the frames are unlocked for dragging, and while the
	-- creator page is showing you what there is to point at. Both want every
	-- element on the screen and whole whatever the theme says of it.
	local placing = not ns.db.locked or showcase
	local shown = placing or not hidden
	if veil:IsShown() ~= shown then
		if blocked then
			return false
		end
		veil:SetShown(shown)
	end
	if placing then
		-- Being placed. Up and whole, so it can be found and dragged.
		UI.Unreveal(frame)
		veil:SetAlpha(1)
	elseif hover then
		-- Resting at the cell's own fraction rather than at nothing, because a
		-- theme of yours can ask for a tracker at a fifth that comes to full
		-- under the pointer, which is two answers the shipped words have one
		-- word between them for.
		UI.Reveal(frame, alpha)
	else
		-- Off the reveal first: a wiggle can take a frame from under the
		-- pointer to shown, and a catcher left standing over it would take
		-- every press.
		UI.Unreveal(frame)
		if shown then
			veil:SetAlpha(alpha)
		end
	end
	return true
end

-- Every frame handed over, dressed for the theme and for whether the frames
-- are locked. A protected frame a fight refused is owed to the end of it.
local function Pass()
	if not chosen then
		return true
	end
	local complete = true
	for index = 1, #worn do
		local entry = worn[index]
		if not Dress(entry.frame, entry.key) then
			complete = false
		end
	end
	return ns.Lockdown.Done(Pass, complete)
end

-- A part hands over the frame that is one element, once, where it builds it.
-- The key is a row in Themes.ELEMENTS. An element may be several frames, the
-- action bars are, and each is worn under the same key.
--
-- An element both the theme and its wiggle target leave as drawn costs two
-- comparisons here and nothing else, ever: no veil, no reparent.
function Theme.Wear(key, frame)
	assert(known[key], ("%q is not an element in Themes.lua"):format(tostring(key)))
	assert(type(frame) == "table", ("the element %q was worn with no frame"):format(key))
	if frame.wuiWorn then
		return
	end
	frame.wuiWorn = key
	worn[#worn + 1] = { key = key, frame = frame }
	if chosen and not Dress(frame, key) then
		ns.Lockdown.Done(Pass, false)
	end
end

--------------------------------------------------------------------------
-- The wiggle
--
-- Every theme can name a second theme to wiggle to. A shake of the mouse
-- redresses every worn frame with the target's modes, and the next shake puts
-- the theme at rest back. Exploration wiggles to informational out of the box,
-- so everything it keeps under the pointer or off the screen is one shake away;
-- the other two wiggle to nothing until somebody says otherwise.
--
-- The target is a saved setting per theme and takes effect when it is set,
-- unlike the theme itself: a swap is the same redress a wiggle already is.
-- Whether the wiggle is up is saved too, so a player who lives in the target
-- does not shake the mouse after every loading screen.
--
-- The tick runs only while the theme has a target. With none, nothing reads
-- the mouse.
--------------------------------------------------------------------------

-- Where one theme's target is written down. The three that ship have a setting
-- each, registered below like every other setting. A theme of yours keeps its
-- target on its own record instead, because a setting per theme would be a
-- saved key named after something the player can rename, and renaming it would
-- leave the old key behind holding an answer nothing reads.
local function TargetKey(name)
	return "wiggle" .. name:gsub("^%l", string.upper)
end

local function AimedAt(name)
	local _, own = Themes.Find(name)
	if own then
		return own.wiggle
	end
	return ns.db[TargetKey(name)]
end

local function AimAt(name, wanted)
	local _, own = Themes.Find(name)
	if own then
		own.wiggle = wanted
	else
		ns.db[TargetKey(name)] = wanted
	end
end

-- The target a theme is set to, nil for none or for anything no theme goes by.
-- A theme never wiggles to itself.
local function TargetOf(name)
	local wanted = AimedAt(name)
	if wanted ~= name and Themes.Named(wanted) then
		return wanted
	end
	return nil
end

-- A part that draws differently in a wiggle, beyond its veil. The experience
-- rail is one: its style can be the theme's rather than the setting's.
local pinWatchers = {}

function Theme.OnPin(fn)
	pinWatchers[#pinWatchers + 1] = fn
end

-- Which theme is on the screen this moment, and every worn frame dressed for
-- it. One path, because a wiggle, a theme being edited and the creator holding
-- everything up are the same question asked again, and three paths answering
-- it were three places to forget the pass.
--
-- cold: runs on a shake, which is a second apart at the closest, on a dial
-- being moved on a page, and not on any tick's own frames
local function Settle()
	if trying then
		chosen, showing = trying.elements, trying.name
	elseif pinned then
		chosen, showing = target, drawnTarget
	else
		chosen, showing = rest, drawnTheme
	end
	fights = Themes.Fights(chosen)
	local complete = Pass()
	for index = 1, #pinWatchers do
		pinWatchers[index](pinned)
	end
	return complete
end

function Theme.Pin(on)
	pinned = (on and target) and true or false
	ns.db.wiggled = pinned
	return Settle()
end

function Theme.Pinned()
	return pinned
end

-- The name of the theme on the screen this moment.
function Theme.Showing()
	return showing
end

-- How the experience rail is drawn in the theme on the screen, or nil where
-- the theme leaves it to the setting.
function Theme.RailStyle()
	return showing and Themes.RailOf(showing)
end

local shake = UI.Wiggle()
local shaking

local function Shake()
	if IsMouselooking() then
		UI.WiggleLose(shake)
		return
	end
	local x = GetCursorPosition()
	if UI.WiggleFeed(shake, x / UIParent:GetEffectiveScale(), GetTime()) then
		Theme.Pin(not pinned)
	end
end

-- Read the drawn theme's target off the settings, redress for it, and run the
-- tick only if there is one. At load, and whenever the target is set.
function Theme.Aim()
	drawnTarget = TargetOf(drawnTheme)
	target = drawnTarget and Themes.Named(drawnTarget)
	if target and not shaking then
		shaking = UI.Ticker(UI.Forever, 0.02, "wiggle", Shake)
	elseif target and not shaking:Running() then
		shaking:Start()
	elseif not target and shaking then
		shaking:Stop()
	end
	return Theme.Pin(ns.db.wiggled)
end

--------------------------------------------------------------------------
-- The theme being edited
--
-- A third thing over the drawn theme and its wiggle, lasting exactly as long
-- as the creator page has a theme open. It is what makes that page an editor
-- rather than a form: every dial redresses the screen as it moves, and closing
-- the page puts back whatever was there before it opened.
--
-- The table handed over is the saved record itself and not a copy, so a cell
-- written on the page is the cell the next pass reads.
--------------------------------------------------------------------------

function Theme.Try(theme)
	trying = theme
	return Settle()
end

function Theme.Trying()
	return trying
end

-- Every element up and whole, whatever the theme says of it, so the page can
-- draw a rim round each and you can point at the one you mean. The state the
-- frames are already in while they are unlocked for dragging, for its reason:
-- an element you cannot see is an element you cannot choose.
function Theme.Showcase(on)
	showcase = on and true or false
	return Settle()
end

function Theme.Showcasing()
	return showcase
end

-- A theme of yours was renamed, or dropped. Three kinds of setting name a
-- theme by its name, and every one of them has to follow it or the next login
-- falls back to informational with nothing said about why.
--
-- `now` is nil for a theme that was dropped, and then what named it falls back:
-- the drawn theme to informational, a wiggle target to none. Called by
-- Theme/Custom.lua, which owns the list and knows nothing about which theme is
-- drawn or what wiggles to what.
function Theme.Renamed(was, now)
	if ns.db.theme == was then
		ns.db.theme = now or "informational"
	end
	for _, name in ipairs(Themes.ORDER) do
		if ns.db[TargetKey(name)] == was then
			ns.db[TargetKey(name)] = now or "none"
		end
	end
	for _, own in ipairs(Themes.Own()) do
		if own.wiggle == was then
			own.wiggle = now or "none"
		end
	end
	Theme.Aim()
end

--------------------------------------------------------------------------
-- The palette
--------------------------------------------------------------------------

-- Copied into UI.Color's own tables rather than over them, because a part that
-- took UI.Color.window into a local is holding the table. The unit table and
-- the accent go to Unit/Color.lua, which copies them the same way and then
-- shapes its fills.
local function Paint(name)
	for key, color in pairs(Palettes[name]) do
		if key ~= "unit" then
			local into = UI.Color[key]
			into[1], into[2], into[3], into[4] = color[1], color[2], color[3], color[4]
		end
	end
	ns.Unit.Color.Paint(Palettes[name])
	UI.ChooseBackdrop(ns.Backdrops[name])
end

--------------------------------------------------------------------------
-- The load
--------------------------------------------------------------------------

-- After Core.lua's own ADDON_LOADED, which registered first and is what made
-- ns.db, and before every part that builds a frame at login.
--
-- The two fight events are on the same frame. An element that is drawn
-- differently in a fight is the one thing in a theme that changes without
-- anybody touching anything, and the pass it needs is alpha on a veil that is
-- already there and already on the screen, which the client allows in combat.
-- That is why a cell with a fight fraction is never hidden: see Themes.Cell.
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_REGEN_DISABLED")
loader:RegisterEvent("PLAYER_REGEN_ENABLED")
loader:SetScript("OnEvent", function(self, event, name)
	if event ~= "ADDON_LOADED" then
		fighting = event == "PLAYER_REGEN_DISABLED"
		if fights then
			Pass()
		end
		return
	end
	if name ~= ADDON then
		return
	end
	self:UnregisterEvent("ADDON_LOADED")
	Themes.Load()
	if not Themes.Named(ns.db.theme) then
		ns.db.theme = "informational"
	end
	if not listed[ns.db.palette] then
		ns.db.palette = "dark"
	end
	if ns.db.gaugeLook ~= "modern" then
		ns.db.gaugeLook = "flat"
	end
	drawnTheme, drawnPalette, drawnLook = ns.db.theme, ns.db.palette, ns.db.gaugeLook
	drawnPortraits = ns.db.portraits ~= false
	fighting = InCombatLockdown() and true or false
	Paint(drawnPalette)
	rest = Themes.Named(drawnTheme)
	Theme.Aim()
end)

--------------------------------------------------------------------------
-- The command and the page
--------------------------------------------------------------------------

local function Percent(fraction)
	return math.floor(fraction * 100 + 0.5)
end

-- What one theme does with one element, in a phrase. Read on the page under
-- the element's own name, so it is the predicate and never the whole sentence.
--
-- Public because the creator page says the same thing about the theme you are
-- editing, and two files wording this differently is how a screen ends up
-- calling the same cell two things on two pages.
function Theme.Describe(theme, key)
	local alpha, hover, hidden, combat = Themes.Cell(theme, key)
	local said
	if hidden then
		said = "hidden"
	elseif hover and alpha <= 0 then
		said = "under the pointer"
	elseif hover then
		said = ("at %d%%, full under the pointer"):format(Percent(alpha))
	elseif alpha >= 1 then
		said = "as drawn"
	else
		said = ("at %d%%"):format(Percent(alpha))
	end
	if combat then
		said = ("%s, %d%% in a fight"):format(said, Percent(combat))
	end
	return said
end

-- A list of names as the rows a picker drops down, each row showing its name.
local function Choices(names)
	local options = {}
	for index, name in ipairs(names) do
		options[index] = { value = name, text = name }
	end
	return options
end

-- What a theme can wiggle to: nothing, or any other theme, yours included.
local function Targets(name)
	local names = { "none" }
	for _, other in ipairs(Themes.Names()) do
		if other ~= name then
			names[#names + 1] = other
		end
	end
	return names
end

local function Pending()
	return ns.db.theme ~= drawnTheme or ns.db.palette ~= drawnPalette
		or ns.db.gaugeLook ~= drawnLook or (ns.db.portraits ~= false) ~= drawnPortraits
end

-- One word, where the answer is read and written, and the list it has to be
-- on. Live is an answer that takes effect when it is written rather than at
-- the reload.
--
-- The whole argument is the name rather than the first word of it, and the
-- comparison ignores case, because a theme of yours is called what you called
-- it: `/wui theme Raid nights` is one name with a space in it, and `raid
-- nights` is the same theme typed in a hurry. The answer written down is the
-- name off the list, so the settings hold one spelling however it was typed.
local function Word(get, set, names, arg, noun, live)
	local wanted = arg:gsub("^%s+", ""):gsub("%s+$", ""):lower()
	local found
	for _, candidate in ipairs(names) do
		if candidate:lower() == wanted then
			found = candidate
		end
	end
	if wanted == "" then
		ns.Print(("%s %s; choose from %s."):format(noun, get(), table.concat(names, ", ")))
		return
	end
	if not found then
		ns.Print(("there is no %s called %s; choose from %s.")
			:format(noun, wanted, table.concat(names, ", ")))
		return
	end
	set(found)
	ns.Print(("%s %s%s."):format(noun, found, live and "" or " from the next /reload"))
end

-- The two halves of a setting, for the words above, so a word that reads and
-- writes a plain setting says its name once.
local function Getter(setting)
	return function() return ns.db[setting] end
end

local function Setter(setting)
	return function(value) ns.db[setting] = value end
end

ns.Register({
	name = "theme",
	order = 41,

	defaults = {
		-- Informational is the addon as it was before themes, every element
		-- drawn, so nobody's screen changes by upgrading.
		theme = "informational",
		palette = "dark",
		gaugeLook = "flat",
		portraits = true,
		-- What each theme swaps to on a shake of the mouse. Exploration's is
		-- the point of it: everything it leaves under the pointer or off the
		-- screen, one shake away. The other two change nobody's screen.
		wiggleInformational = "none",
		wiggleImmersive = "none",
		wiggleExploration = "informational",
		-- Whether the wiggle was up at logout, so it is up again at login.
		wiggled = false,
		-- The themes you have made yourself, each naming every element the way
		-- the shipped three do. A record rather than a setting: Core keeps it
		-- out of the reset, because a button about the screen's layout has no
		-- business deleting a theme somebody spent an evening on.
		themes = {},
	},

	words = {
		theme = function(arg)
			Word(Getter("theme"), Setter("theme"), Themes.Names(), arg, "theme")
		end,
		palette = function(arg)
			Word(Getter("palette"), Setter("palette"), Theme.PALETTES, arg, "palette")
		end,
		gauges = function(arg)
			Word(Getter("gaugeLook"), Setter("gaugeLook"), Theme.BAR_LOOKS, arg, "bar look")
		end,
		wiggle = function(arg)
			local name = ns.db.theme
			Word(function() return AimedAt(name) end,
				function(value) AimAt(name, value) end,
				Targets(name), arg,
				("wiggle target for %s:"):format(name), true)
			Theme.Aim()
		end,
	},

	help = {
		"theme informational|immersive|exploration|<yours>, how much of the addon is on the screen, from the next /reload",
		"palette dark|forest|desert|arcane|horde|alliance|fire|parchment, the addon's colours, from the next /reload",
		"gauges flat|modern, how every health, power and cast bar is drawn, from the next /reload",
		"wiggle none|<theme>, what the theme swaps to on a shake of the mouse",
	},

	status = function()
		return ("theme %s, palette %s, gauges %s")
			:format(drawnTheme or "?", drawnPalette or "?", drawnLook or "?")
	end,

	lock = function()
		Pass()
	end,

	panel = function(ui)
		-- First in the window, ahead of On and off's own switches. How much of the
		-- addon is on the screen is the choice every other switch sits under, so
		-- it is the page the window opens on. The panel builds every part before
		-- it builds On and off, which is what puts these two sections above it.
		ui.Section("Theme", "On and off")
		ui.Lede("How much of the addon is on the screen, and what colour it is. Both are drawn at the next reload.")

		local palettes, looks = Choices(Theme.PALETTES), Choices(Theme.BAR_LOOKS)

		ui.Picker("theme",
			function() return ns.db.theme end,
			function(value) ns.db.theme = value end,
			function() return Choices(Themes.Names()) end)
		ui.Hint(function()
			return Themes.LABEL[ns.db.theme]
				or "one of yours, made below and edited on the screen"
		end)

		ui.Picker("wiggle to",
			function() return AimedAt(ns.db.theme) end,
			function(value)
				AimAt(ns.db.theme, value)
				Theme.Aim()
			end,
			function() return Choices(Targets(ns.db.theme)) end)
		ui.Hint("Shake the mouse side to side and the screen swaps to this theme; shake again and it swaps back. Takes effect at once, and a swap is held across a reload.")

		ui.Picker("palette",
			function() return ns.db.palette end,
			function(value) ns.db.palette = value end,
			function() return palettes end)

		ui.Picker("bar look",
			function() return ns.db.gaugeLook end,
			function(value) ns.db.gaugeLook = value end,
			function() return looks end)
		ui.Hint("Modern shades each bar light to dark, stacks health on power with no line between, and edges each unit in the palette's dark.")

		ui.Check("portraits on the player and target frames",
			function() return ns.db.portraits ~= false end,
			function(value) ns.db.portraits = value end)
		ui.Hint("Off, each frame keeps its width and the bars stretch into the portrait's square.")

		ui.Action(function()
			return Pending() and "reload to draw it" or "drawn now"
		end, ReloadUI, Pending)

		ui.Section("What the theme does", "On and off")
		ui.Lede("Each element, and what the chosen theme does with it. Unlocking the frames brings every one of them back up so you can drag it.")
		for _, element in ipairs(Themes.ELEMENTS) do
			ui.Reading(element.label, function()
				return Theme.Describe(Themes.Named(ns.db.theme) or Themes.informational,
					element.key)
			end)
		end

		-- The page that makes one of your own, which is its own file for the
		-- room it takes and not because it is a part of its own: it writes the
		-- same cells this file reads, into the same list.
		ns.ThemeEdit.Panel(ui)
	end,

	-- The creator holds every element up and dims nothing while its page is
	-- open, so the page going away has to put the screen back. There is no
	-- other way out of that state: the window is closed with a cross, with
	-- Escape or by opening something else, and none of those is a button this
	-- addon owns.
	showing = function(open)
		if not open then
			ns.ThemeEdit.Stop()
		end
	end,
})
