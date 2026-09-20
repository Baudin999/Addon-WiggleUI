local ADDON, ns = ...

local UI = ns.UI
local C, M = UI.Color, UI.Metric
local Previews = ns.SetupPreviews

--------------------------------------------------------------------------
-- The setup: five questions, asked once
--
-- A new player opens the options window and finds forty pages. Five of the
-- answers on them decide what the game looks like, and the rest are numbers
-- that were dragged into place on the author's screen and ship as they are. So
-- the five are asked on the first login, one page each, as cards with a
-- picture of the answer on them:
--
--   size      how big everything is, ns.db.generalSize, shown live
--   mode      how much of the addon is on the screen, ns.db.theme
--   colours   the palette, ns.db.palette
--   frames    modern or flat unit frames; modern takes the portraits off
--   tooltips  every hover's box in the corner, or beside what you hovered;
--             a map pin's is beside the pin either way
--
-- Nothing is written until the last page. Skipping, closing the window or
-- pressing Escape keeps what is there, which on a fresh install is the shipped
-- screen, and the setup never comes up on its own again: it is under the game
-- menu as WiggleUI Setup, and /wui setup.
--
-- Three of the five are drawn at a /reload, for the reason Theme/Theme.lua
-- gives, so finishing reloads when one of those three moved. The size and the
-- tooltips apply on the spot.
--
-- Finishing also lays the chosen mode's shipped screen over the profile this
-- character wears, windows and sizes included. Setup.Apply says why.
--------------------------------------------------------------------------

local Setup = {}
ns.Setup = Setup

local WIDTH = 660
local GAP = 10
local INNER = WIDTH - M.pad * 2

-- The picture on a card and the room round it. A palette card has no sentence
-- under its picture, because the picture is the whole of the answer.
local PREVIEW = 108
local SWATCH = 72
local CARD_TITLE = 16
local BLURB = 44

-- How far down the page the cards start: the step rail, the question and a
-- sentence under it.
local HEADER = 84

-- How tall one card is, how tall the page holding them all is, and how tall
-- that makes the window.
--
-- **The window is as tall as its tallest page and not a number.** It was 400,
-- which is the mode page's one row of cards and nothing to spare, and the
-- colours page is seven palettes in three columns: three rows, a hundred and
-- fifty units more, drawn straight through the footer and out of the bottom of
-- the window. A card count is the sort of thing that grows, and the palettes
-- have an epic of their own, so the page says how much room it needs and the
-- window takes the largest answer.
local function CardHeight(step)
	local tall = step.swatch and SWATCH or PREVIEW
	return M.gutter * 2 + CARD_TITLE + tall + (step.swatch and 0 or BLURB)
end

local function PageHeight(step)
	local rows = math.ceil(#step.cards / step.columns)
	return HEADER + rows * CardHeight(step) + (rows - 1) * GAP
end

-- Every page's room, plus the title bar, the footer and the pad above and
-- below the page. Window:Body takes the first two off again.
local function Height()
	local tallest = 0
	for _, step in ipairs(Setup.STEPS) do
		tallest = math.max(tallest, PageHeight(step))
	end
	return M.title + M.footer + M.pad * 2 + tallest
end

--------------------------------------------------------------------------
-- The questions
--------------------------------------------------------------------------

local function Capital(word)
	return word:sub(1, 1):upper() .. word:sub(2)
end

local function PaletteCards()
	local cards = {}
	for index, name in ipairs(ns.Theme.PALETTES) do
		cards[index] = { value = name, title = Capital(name) }
	end
	return cards
end

-- The sizes the first page offers. 1 is the author's screen on whatever monitor
-- this is, because the grid already scales by the monitor's height. Snapped,
-- because the saved value is, and 1.2 off the zoom step is not 1.2 in a double.
local SIZES = { UI.ZoomSnap(0.9), UI.ZoomSnap(1), UI.ZoomSnap(1.2), UI.ZoomSnap(1.4) }
local LARGEST = SIZES[#SIZES]

-- The modes run from the one that shows least to the one that shows most, which
-- is also from the player who knows the game best to the one who is new to it.
Setup.STEPS = {
	{
		key = "size",
		rail = "size",
		question = "How big should everything be?",
		lede = "Picking a card sizes your real screen behind this window. Every part can still be sized on its own later, on the zoom page.",
		columns = 4,
		draw = function(preview, width, height, value)
			return Previews.Size(preview, width, height, value, LARGEST)
		end,
		cards = {
			{ value = SIZES[1], title = "Smaller", blurb = "More of the world, less of the addon." },
			{ value = SIZES[2], title = "As shipped", blurb = "The author's screen, on your monitor." },
			{ value = SIZES[3], title = "Larger", blurb = "Easier to read from the couch." },
			{ value = SIZES[4], title = "Largest", blurb = "For a big screen far away." },
		},
	},
	{
		key = "theme",
		rail = "mode",
		question = "How much of the addon do you want on the screen?",
		lede = "The mode you play in. Finishing puts this mode's whole screen on your profile, windows and all; every element can still be moved later.",
		columns = 3,
		draw = Previews.Mode,
		cards = {
			{ value = "immersive", title = "Immersive",
				blurb = "If you can play the game blind. Your frame and your target's, faint, and nothing else." },
			{ value = "exploration", title = "Exploration",
				blurb = "If you know what you are doing. Chat, quests and bars wait under the pointer." },
			{ value = "informational", title = "Informational",
				blurb = "For new players. Everything the addon draws, all of the time." },
		},
	},
	{
		key = "palette",
		rail = "colours",
		question = "Which colours should the addon wear?",
		lede = "Every window, bar and tooltip is drawn in these. Forest, desert, arcane, horde, alliance and fire carry a painted frame.",
		columns = 3,
		swatch = true,
		draw = Previews.Palette,
		cards = PaletteCards(),
	},
	{
		key = "plates",
		rail = "frames",
		question = "How should your unit frames look?",
		lede = "Your frame, your target's and the party's. Both read the same numbers; this is only the drawing.",
		columns = 2,
		draw = function(preview, width, height, value)
			return Previews.Plate(preview, width, height, value == "modern")
		end,
		cards = {
			{ value = "modern", title = "Modern",
				blurb = "Shaded bars stacked tight, one dark edge, no portrait. The bars take its room." },
			{ value = "flat", title = "Flat",
				blurb = "Flat fills with a hairline round each, and your portrait beside them." },
		},
	},
	{
		key = "tips",
		rail = "tooltips",
		question = "Where should a tooltip open?",
		lede = "For everything you hover: bag items, buttons, spells, units and the addon's own rows. A map pin always opens beside the pin.",
		columns = 2,
		draw = Previews.Tip,
		cards = {
			{ value = UI.Tooltip.RIGHT, title = "Bottom right",
				blurb = "In the corner the game keeps its own tooltip in, out of the way of what you are looking at." },
			{ value = UI.Tooltip.ATTACHED, title = "Attached",
				blurb = "Next to whatever you hovered, so the box is on the thing it describes." },
		},
	},
}

--------------------------------------------------------------------------
-- What is chosen now, and what writing it does
--------------------------------------------------------------------------

-- The types the answer does not reach, and where each one always opens. A map
-- pin is attached whatever the player picks: the map is a window you read
-- across, and a box in the screen's corner is a long way from the pin it
-- names, often behind the map itself.
Setup.FIXED_TIPS = {
	pin = UI.Tooltip.ATTACHED,
}

-- Every type of tooltip's place the answer reaches, counted, and the more
-- common of the two the setup offers. A screen with a mixture is one somebody set type by type, and
-- the card that describes most of it is the fair one to light.
local function CurrentTips()
	local right, attached = 0, 0
	for _, each in ipairs(UI.Tooltip.TYPES) do
		local place = not Setup.FIXED_TIPS[each.key] and ns.Settings.Place(each.key)
		if place == UI.Tooltip.RIGHT then
			right = right + 1
		elseif place == UI.Tooltip.ATTACHED then
			attached = attached + 1
		end
	end
	return right > attached and UI.Tooltip.RIGHT or UI.Tooltip.ATTACHED
end

-- The four answers as the saved variables have them, which is what the cards
-- light when the window opens. Running the setup again starts on your screen.
function Setup.Current()
	return {
		size = UI.ZoomSnap(ns.db.generalSize),
		theme = ns.db.theme,
		palette = ns.db.palette,
		plates = ns.db.gaugeLook == "modern" and "modern" or "flat",
		tips = CurrentTips(),
	}
end

-- Whether writing these answers needs a reload to be seen. The tooltips never
-- do; the other three are drawn once, at load, and so is every setting the
-- mode's screen moves.
function Setup.NeedsReload(answers)
	local theme, palette = ns.Theme.Drawn()
	local modern = answers.plates == "modern"
	return answers.theme ~= theme or answers.palette ~= palette
		or modern ~= ns.Theme.Modern() or (not modern) ~= ns.Theme.Portraits()
		or ns.DefaultsMoved(answers.theme, Setup.Asks) > 0
end

-- Put the chosen mode's shipped screen on this profile, then write the four
-- answers over it. The screen is the whole of the profile, so a player who
-- moved a window and runs the setup again gets the shipped spot back: that is
-- how a screen shipped in an update reaches a profile made before it, and the
-- only way, because nothing else writes into a player's profile.
--
-- Modern takes the portraits off and flat puts them back, which is the one
-- place two settings are one answer: a portrait on a modern frame is the
-- square the look exists to give to the bars.
function Setup.Apply(answers)
	ns.RestoreDefaults(answers.theme)
	ns.db.generalSize = UI.ZoomSnap(answers.size)
	UI.SetGeneral(ns.db.generalSize)
	ns.db.theme = answers.theme
	ns.db.palette = answers.palette
	ns.db.gaugeLook = answers.plates
	ns.db.portraits = answers.plates ~= "modern"
	for _, each in ipairs(UI.Tooltip.TYPES) do
		ns.Settings.SetPlace(each.key, Setup.FIXED_TIPS[each.key] or answers.tips)
	end
	ns.db.setupDone = true
end

-- Whether a saved key is one of the four answers. scripts/bake-defaults.lua
-- asks, and leaves every such key out of Core/Shipped.lua: the setup is where a
-- new player gives these four, and a capture of the author's screen shipping
-- its own would make the cards the author's choice with a picture on it.
function Setup.Asks(key)
	if key == "generalSize" or key == "theme" or key == "palette"
		or key == "gaugeLook" or key == "portraits" then
		return true
	end
	for _, each in ipairs(UI.Tooltip.TYPES) do
		if key == ns.Settings.PlaceKey(each.key) then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------
-- A card
--------------------------------------------------------------------------

local function Edge(card, color)
	for index = 1, 4 do
		UI.Tint(card.edges[index], color)
	end
end

-- Lit is the accent round it and the selected floor under it. The floor is the
-- button's tone, so the hover paints over it and the leave puts it back.
local function Light(card, on)
	card.tone = on and C.selected or C.control
	UI.Tint(card.bg, card.tone)
	Edge(card, on and C.accent or C.edge)
	card.title:SetTextColor(unpack(on and C.heading or C.text))
end

local function Card(page, step, entry, width)
	local tall = step.swatch and SWATCH or PREVIEW
	local card = UI.Button(page, {
		width = width,
		height = CardHeight(step),
		onClick = function() Setup.Pick(step.key, entry.value) end,
	})
	card.value = entry.value

	card.title = UI.Label(card, M.heading, C.text, "LEFT", UI.FLAT)
	card.title:SetPoint("TOPLEFT", M.gutter, -M.gutter)
	card.title:SetText(entry.title)

	local preview = CreateFrame("Frame", nil, card)
	preview:SetSize(width - M.gutter * 2, tall)
	preview:SetPoint("TOPLEFT", M.gutter, -(M.gutter + CARD_TITLE))
	step.draw(preview, width - M.gutter * 2, tall, entry.value)

	if entry.blurb then
		local blurb = UI.Label(card, M.small, C.dim, "LEFT", UI.FLAT)
		blurb:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -6)
		blurb:SetWidth(width - M.gutter * 2)
		UI.Wrap(blurb, true)
		blurb:SetText(entry.blurb)
	end
	return card
end

--------------------------------------------------------------------------
-- A page
--------------------------------------------------------------------------

local window, pages, rail
local answers, at

local function Cards(page, step)
	local width = math.floor((INNER - GAP * (step.columns - 1)) / step.columns)
	page.cards = {}
	for index, entry in ipairs(step.cards) do
		local card = Card(page, step, entry, width)
		local column = (index - 1) % step.columns
		local row = math.floor((index - 1) / step.columns)
		card:SetPoint("TOPLEFT", column * (width + GAP), -(HEADER + row * (card:GetHeight() + GAP)))
		page.cards[index] = card
	end
end

local function Page(step)
	local page = CreateFrame("Frame", nil, window.content)
	page:SetPoint("TOPLEFT", M.pad, -M.pad)
	page:SetSize(INNER, PageHeight(step))

	local question = UI.Label(page, M.tally, C.heading, "LEFT", UI.FLAT)
	question:SetPoint("TOPLEFT", 0, -(M.row + M.gutter))
	question:SetText(step.question)

	local lede = UI.Label(page, M.font, C.dim, "LEFT", UI.FLAT)
	lede:SetPoint("TOPLEFT", question, "BOTTOMLEFT", 0, -M.rowGap * 2)
	lede:SetWidth(INNER)
	UI.Wrap(lede, true)
	lede:SetText(step.lede)

	Cards(page, step)
	page:Hide()
	return page
end

-- The steps across the top, numbered, the one you are on in the accent
-- and the ones behind you in the text colour. Pressing one goes back to it.
local function Rail()
	local labels = {}
	local across = math.floor(INNER / #Setup.STEPS)
	for index, step in ipairs(Setup.STEPS) do
		local stop = UI.Button(window.content, {
			width = across - GAP,
			height = M.row,
			label = ("%d  %s"):format(index, step.rail),
			onClick = function() Setup.Go(index) end,
		})
		stop:SetPoint("TOPLEFT", M.pad + (index - 1) * across, -M.pad)
		labels[index] = stop
	end
	return labels
end

local function Footer()
	window.skip = UI.Button(window.footer, {
		label = "skip, keep what is here",
		width = 150,
		onClick = function() window:Hide() end,
	})
	window.skip:SetPoint("LEFT", 0, 0)

	window.next = UI.Button(window.footer, {
		label = "next",
		width = 120,
		onClick = function() Setup.Forward() end,
	})
	window.next:SetPoint("RIGHT", 0, 0)

	window.back = UI.Button(window.footer, {
		label = "back",
		width = 76,
		onClick = function() Setup.Go(at - 1) end,
	})
	window.back:SetPoint("RIGHT", window.next, "LEFT", -M.rowGap, 0)
end

local function Build()
	if window then
		return window
	end
	window = UI.Window({
		name = "WiggleUISetup",
		title = "WiggleUI Setup",
		width = WIDTH,
		height = Height(),
	})
	rail = Rail()
	pages = {}
	for index, step in ipairs(Setup.STEPS) do
		pages[index] = Page(step)
	end
	Footer()

	-- Every way off the screen counts as answered. A window that came back at
	-- every login until the last button was pressed would be a nag, and the
	-- way back to it is on the game menu.
	window.frame:HookScript("OnHide", function()
		UI.SetGeneral(UI.ZoomSnap(ns.db.generalSize))
		if not ns.db.setupDone then
			ns.db.setupDone = true
			ns.Print("the setup is under Escape, WiggleUI Setup, or /wui setup, whenever you want it.")
		end
	end)
	return window
end

--------------------------------------------------------------------------
-- Moving through it
--------------------------------------------------------------------------

local function Last()
	return at == #Setup.STEPS
end

local function FinishLabel()
	return Setup.NeedsReload(answers) and "reload and play" or "done"
end

local function Paint()
	for index, page in ipairs(pages) do
		page:SetShown(index == at)
		local step = Setup.STEPS[index]
		for _, card in ipairs(page.cards) do
			Light(card, answers[step.key] == card.value)
		end
	end
	for index, stop in ipairs(rail) do
		stop.text:SetTextColor(unpack(index == at and C.accent
			or index < at and C.text or C.quiet))
	end
	window.back:SetShown(at > 1)
	window.next.text:SetText(Last() and FinishLabel() or "next")
end

function Setup.Show()
	Build()
	answers = Setup.Current()
	at = 1
	Paint()
	window:Show()
end

function Setup.Hide()
	if window then
		window:Hide()
	end
end

function Setup.IsShown()
	return window ~= nil and window:IsShown()
end

-- The step on the screen and the answer lit on it, for the harness, which has
-- no other way to see a card without naming its frames.
function Setup.Where()
	return at, answers and answers[Setup.STEPS[at or 1].key]
end

-- The size is the one answer shown before it is written: the whole screen is
-- re-scaled to it on the pick, because a card cannot show how big your own
-- frames are on your own monitor. Nothing is saved until the last page, and
-- the window's OnHide puts the saved size back, which after a finish is the
-- size just written.
function Setup.Pick(key, value)
	answers[key] = value
	if key == "size" then
		UI.SetGeneral(value)
	end
	Paint()
end

function Setup.Go(index)
	at = math.max(1, math.min(index, #Setup.STEPS))
	Paint()
end

-- Next, and on the last page the write. Hidden before the reload so the
-- OnHide above finds the setup already answered and says nothing.
function Setup.Forward()
	if not Last() then
		Setup.Go(at + 1)
		return
	end
	local reload = Setup.NeedsReload(answers)
	Setup.Apply(answers)
	window:Hide()
	if reload then
		ReloadUI()
	end
end
