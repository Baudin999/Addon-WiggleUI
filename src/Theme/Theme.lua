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
-- world. The one exception is the frames being placed: /wk unlock brings every
-- element up so it can be dragged, and locking puts the theme back.
--------------------------------------------------------------------------

-- The palettes in the order the options page cycles them. Every palette file
-- has to be on this list and the list may hold nothing else, which the load
-- checks below hold it to.
Theme.PALETTES = { "dark", "forest", "desert", "arcane", "horde", "alliance" }

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
local chosen

function Theme.Drawn()
	return drawnTheme, drawnPalette
end

-- How a gauge is drawn: flat, the fill as one colour and a hairline round
-- everything, or modern, a sheen down the fill, the bars of one unit stacked
-- with no line between them and the unit's edge in the palette's accent.
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
function Theme.Mode(key)
	local mode = (chosen or Themes.informational)[key]
	if mode == nil then
		error(("%q is not an element in Themes.lua"):format(tostring(key)), 2)
	end
	return mode
end

--------------------------------------------------------------------------
-- Dressing a frame
--------------------------------------------------------------------------

local worn = {} -- { key, frame } for every frame a part has handed over

local function Dress(frame, mode)
	if mode == "show" and not UI.Veiled(frame) then
		return true
	end
	if ns.Blocked(frame) then
		return false
	end
	local veil = UI.Veil(frame)
	if not veil then
		return false
	end
	if not ns.db.locked then
		-- Being placed. Up and whole, so it can be found and dragged.
		if frame.wkReveal then
			frame.wkReveal:Hide()
		end
		veil:SetAlpha(1)
		veil:Show()
		return true
	end
	if mode == "hide" then
		veil:Hide()
	elseif mode == "hover" then
		veil:Show()
		UI.Reveal(frame, 0)
	else
		veil:Show()
		veil:SetAlpha(mode == "show" and 1 or mode)
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
		if not Dress(entry.frame, chosen[entry.key]) then
			complete = false
		end
	end
	return ns.Lockdown.Done(Pass, complete)
end

-- A part hands over the frame that is one element, once, where it builds it.
-- The key is a row in Themes.ELEMENTS. An element may be several frames, the
-- action bars are, and each is worn under the same key.
--
-- An element the theme leaves as drawn costs one comparison here and nothing
-- else, ever: no veil, no reparent.
function Theme.Wear(key, frame)
	assert(known[key], ("%q is not an element in Themes.lua"):format(tostring(key)))
	assert(type(frame) == "table", ("the element %q was worn with no frame"):format(key))
	if frame.wkWorn then
		return
	end
	frame.wkWorn = key
	worn[#worn + 1] = { key = key, frame = frame }
	if chosen and not Dress(frame, chosen[key]) then
		ns.Lockdown.Done(Pass, false)
	end
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
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON then
		return
	end
	self:UnregisterEvent("ADDON_LOADED")
	if not themed[ns.db.theme] then
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
	Paint(drawnPalette)
	chosen = themed[drawnTheme]
	Pass()
end)

--------------------------------------------------------------------------
-- The command and the page
--------------------------------------------------------------------------

local function Describe(mode)
	if mode == "show" then
		return "as drawn"
	elseif mode == "hide" then
		return "hidden"
	elseif mode == "hover" then
		return "under the pointer"
	end
	return ("at %d%%"):format(math.floor(mode * 100 + 0.5))
end

-- A list of names as the rows a picker drops down, each row showing its name.
local function Choices(names)
	local options = {}
	for index, name in ipairs(names) do
		options[index] = { value = name, text = name }
	end
	return options
end

local function Pending()
	return ns.db.theme ~= drawnTheme or ns.db.palette ~= drawnPalette
		or ns.db.gaugeLook ~= drawnLook or (ns.db.portraits ~= false) ~= drawnPortraits
end

-- One word, the saved setting it writes, and the list it has to be on.
local function Word(setting, names, arg, noun)
	local wanted = arg:match("^(%S*)"):lower()
	local valid = {}
	for _, candidate in ipairs(names) do
		valid[candidate] = true
	end
	if wanted == "" then
		ns.Print(("%s %s; choose from %s."):format(noun, ns.db[setting], table.concat(names, ", ")))
		return
	end
	if not valid[wanted] then
		ns.Print(("there is no %s called %s; choose from %s.")
			:format(noun, wanted, table.concat(names, ", ")))
		return
	end
	ns.db[setting] = wanted
	ns.Print(("%s %s from the next /reload."):format(noun, wanted))
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
	},

	words = {
		theme = function(arg)
			Word("theme", Themes.ORDER, arg, "theme")
		end,
		palette = function(arg)
			Word("palette", Theme.PALETTES, arg, "palette")
		end,
		gauges = function(arg)
			Word("gaugeLook", Theme.BAR_LOOKS, arg, "bar look")
		end,
	},

	help = {
		"theme informational|immersive|exploration, how much of the addon is on the screen, from the next /reload",
		"palette dark|forest|desert|arcane, the addon's colours, from the next /reload",
		"gauges flat|modern, how every health, power and cast bar is drawn, from the next /reload",
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

		local themes, palettes = Choices(Themes.ORDER), Choices(Theme.PALETTES)
		local looks = Choices(Theme.BAR_LOOKS)

		ui.Picker("theme",
			function() return ns.db.theme end,
			function(value) ns.db.theme = value end,
			function() return themes end)
		ui.Hint(function() return Themes.LABEL[ns.db.theme] end)

		ui.Picker("palette",
			function() return ns.db.palette end,
			function(value) ns.db.palette = value end,
			function() return palettes end)

		ui.Picker("bar look",
			function() return ns.db.gaugeLook end,
			function(value) ns.db.gaugeLook = value end,
			function() return looks end)
		ui.Hint("Modern shades each bar light to dark, stacks health on power with no line between, and edges each unit in the palette's accent.")

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
				return Describe(themed[ns.db.theme][element.key])
			end)
		end
	end,
})
