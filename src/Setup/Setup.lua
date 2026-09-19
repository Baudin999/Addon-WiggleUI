local ADDON, ns = ...

local UI = ns.UI
local C, M = UI.Color, UI.Metric
local Previews = ns.SetupPreviews

--------------------------------------------------------------------------
-- The setup: four questions, asked once
--
-- A new player opens the options window and finds forty pages. Four of the
-- answers on them decide what the game looks like, and the rest are numbers
-- that were dragged into place on the author's screen and ship as they are. So
-- the four are asked on the first login, one page each, as cards with a
-- picture of the answer on them:
--
--   mode      how much of the addon is on the screen, ns.db.theme
--   colours   the palette, ns.db.palette
--   frames    modern or flat unit frames; modern takes the portraits off
--   tooltips  every hover's box in the corner, or beside what you hovered
--
-- Nothing is written until the last page. Skipping, closing the window or
-- pressing Escape keeps what is there, which on a fresh install is the shipped
-- screen, and the setup never comes up on its own again: it is under the game
-- menu as WarriorKit Setup, and /wk setup.
--
-- Three of the four are drawn at a /reload, for the reason Theme/Theme.lua
-- gives, so finishing reloads when one of those three moved. The tooltips
-- apply on the spot.
--------------------------------------------------------------------------

local Setup = {}
ns.Setup = Setup

local WIDTH = 660
local HEIGHT = 400
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

-- The modes run from the one that shows least to the one that shows most, which
-- is also from the player who knows the game best to the one who is new to it.
Setup.STEPS = {
	{
		key = "theme",
		rail = "mode",
		question = "How much of the addon do you want on the screen?",
		lede = "The mode you play in. Every element can still be moved and switched on its own later.",
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
		lede = "Every window, bar and tooltip is drawn in these. Forest, desert, arcane, horde and alliance carry a painted frame.",
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
		lede = "For everything you hover: bag items, buttons, spells, units and the addon's own rows.",
		columns = 2,
		draw = Previews.Tip,
		cards = {
			{ value = UI.Tooltip.RIGHT, title = "Bottom right",
				blurb = "Always in the corner the game keeps its own tooltip in, out of the way of what you are looking at." },
			{ value = UI.Tooltip.ATTACHED, title = "Attached",
				blurb = "Next to whatever you hovered, so the box is on the thing it describes." },
		},
	},
}

--------------------------------------------------------------------------
-- What is chosen now, and what writing it does
--------------------------------------------------------------------------

-- Every type of tooltip's place, counted, and the more common of the two the
-- setup offers. A screen with a mixture is one somebody set type by type, and
-- the card that describes most of it is the fair one to light.
local function CurrentTips()
	local right, attached = 0, 0
	for _, each in ipairs(UI.Tooltip.TYPES) do
		local place = ns.Settings.Place(each.key)
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
		theme = ns.db.theme,
		palette = ns.db.palette,
		plates = ns.db.gaugeLook == "modern" and "modern" or "flat",
		tips = CurrentTips(),
	}
end

-- Whether writing these answers needs a reload to be seen. The tooltips never
-- do; the other three are drawn once, at load.
function Setup.NeedsReload(answers)
	local theme, palette = ns.Theme.Drawn()
	local modern = answers.plates == "modern"
	return answers.theme ~= theme or answers.palette ~= palette
		or modern ~= ns.Theme.Modern() or (not modern) ~= ns.Theme.Portraits()
end

-- Write the four answers. Modern takes the portraits off and flat puts them
-- back, which is the one place two settings are one answer: a portrait on a
-- modern frame is the square the look exists to give to the bars.
function Setup.Apply(answers)
	ns.db.theme = answers.theme
	ns.db.palette = answers.palette
	ns.db.gaugeLook = answers.plates
	ns.db.portraits = answers.plates ~= "modern"
	for _, each in ipairs(UI.Tooltip.TYPES) do
		ns.Settings.SetPlace(each.key, answers.tips)
	end
	ns.db.setupDone = true
end

-- Whether a saved key is one of the four answers. scripts/bake-defaults.lua
-- asks, and leaves every such key out of Core/Shipped.lua: the setup is where a
-- new player gives these four, and a capture of the author's screen shipping
-- its own would make the cards the author's choice with a picture on it.
function Setup.Asks(key)
	if key == "theme" or key == "palette" or key == "gaugeLook" or key == "portraits" then
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
		height = M.gutter * 2 + CARD_TITLE + tall + (step.swatch and 0 or BLURB),
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
	page:SetSize(INNER, HEIGHT)

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

-- The four steps across the top, numbered, the one you are on in the accent
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
		name = "WarriorKitSetup",
		title = "WarriorKit Setup",
		width = WIDTH,
		height = HEIGHT,
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
		if not ns.db.setupDone then
			ns.db.setupDone = true
			ns.Print("the setup is under Escape, WarriorKit Setup, or /wk setup, whenever you want it.")
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

function Setup.Pick(key, value)
	answers[key] = value
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
