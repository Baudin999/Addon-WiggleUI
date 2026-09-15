local ADDON, ns = ...

local Window = {}
ns.TalentWindow = Window

local UI = ns.UI
local C, M = UI.Color, UI.Metric
local Read, Board, Cost = ns.TalentRead, ns.TalentBoard, ns.TalentCost
local Training, Pet = ns.TalentTraining, ns.TalentPet

--------------------------------------------------------------------------
-- The talent window
--
-- Three trees side by side, every talent in every one of them on the screen
-- at once, and nothing to scroll.
--
-- **That is the whole argument.** The client's own frame shows one tree at a
-- time behind three tabs, in a scroll view that on the wider trees hides the
-- last two tiers under the fold, so the question everybody opens it with,
-- "where are my forty one points", is answered by three tabs and a scroll bar.
-- This window is sized to the tallest tree this character has: seven tiers on
-- the older client, nine on the newer, read off the client rather than written
-- here, and every square of all three is in front of you the moment it opens.
--
-- **It replaces the client's window rather than sitting beside it.**
-- Blizzard.lua puts the client's frame in the attic and takes the N key,
-- behind the one switch on the page where every other Blizzard frame this
-- addon replaces is switched. Nothing on this window is secure, because
-- spending a point is not a protected act, so the key is the plain global the
-- client already routes it through and the window opens in a fight.
--
-- **Two specs are a strip across the top.** Where the client has dual
-- specialisation the window carries two tabs, the one you are standing in
-- marked, and a button that makes the other one live. Points go into the live
-- one only, which is the client's own rule, and the boards say so on a hover
-- rather than by refusing quietly. A client with one group and a class with
-- no pet draws no strip at all: the boards start under the title and the
-- window is that much shorter.
--
-- **A hunter's pet is the last tab.** The client has no talent tree for a pet;
-- it has Beast Training, a craft session that spends training points, and
-- Pet.lua draws it where the trees are. The session is the client's to open,
-- so CRAFT_SHOW for beast training opens this window on that tab the way it
-- would have opened CraftFrame, and closing the window closes the session the
-- way closing that frame would have.
--
-- **The foot is the two numbers the client's frame does not put together.**
-- How many points are waiting, and what unlearning them all would cost, the
-- second off Talents/Cost.lua and worded as a quote where there is one and as
-- an estimate where there is not. On the pet's tab it is the pet's points.
--
-- Nothing here is on a ticker. The window paints when it opens and when the
-- client says the talents moved, and a window nobody has open is not painted
-- at all.
--------------------------------------------------------------------------

-- The air between two boards, and the hairline down the middle of it.
local BETWEEN = 20

-- How tall the strip across the top is where there are two specs, and the
-- room under it before the boards start.
local STRIP = M.tab + M.gutter

-- The pet's tab, after the two specs.
local PET = 3

local window, tabs, activate, foot, page
local boards = {}

-- Which group the boards are showing. The live one until a tab is pressed,
-- and back to the live one whenever the client says the live one changed.
local viewing = 1

-- Whether the pet's page is up in place of the boards.
local onPet = false

-- The tallest tree drawn, so the window can be sized to it exactly, and how
-- tall the pet's page came out.
local tiers = 1
local petTall = 0

--------------------------------------------------------------------------
-- Size
--
-- Worked out from what the boards drew rather than from a constant, because
-- the two clients disagree about how many tiers a tree has and a window sized
-- for the taller one on the shorter client is two tiers of nothing.
--------------------------------------------------------------------------

local function Width()
	return M.pad * 2 + Read.Tabs() * Board.Width() + (Read.Tabs() - 1) * BETWEEN
end

-- Whether there is a strip: a second spec to switch to, or a pet to train.
local function Striped(count)
	return count > 1 or Training.Offered()
end

local function Height(count)
	local strip = Striped(count) and STRIP or 0
	local body = Board.Height(tiers)
	if onPet and petTall > body then
		body = petTall
	end
	return M.title + M.pad + strip + body + M.pad + M.footer
end

-- Every board placed, the strip shown or not, and the window sized to fit.
function Window.Fit()
	if not window then
		return false
	end
	local count, active = Read.Groups()
	local striped = Striped(count)
	local strip = striped and STRIP or 0
	local width, height = Width(), Height(count)
	window:Resize(width, height)

	tabs.frame:SetShown(striped)
	tabs:SetShown(2, count > 1)
	tabs:SetShown(PET, Training.Offered())
	activate:SetShown(not onPet and count > 1 and viewing ~= active)
	if striped then
		tabs:Resize(width - M.pad * 2 - activate:GetWidth() - M.gutter)
	end

	for index = 1, #boards do
		local board = boards[index]
		board.frame:ClearAllPoints()
		board.frame:SetPoint("TOPLEFT", window.content, "TOPLEFT",
			M.pad + (index - 1) * (Board.Width() + BETWEEN), -(M.pad + strip))
		board.frame:SetShown(not onPet)
		if board.rule then
			board.rule:ClearAllPoints()
			board.rule:SetPoint("TOPLEFT", board.frame, "TOPRIGHT", math.floor(BETWEEN / 2), 0)
			board.rule:SetPoint("BOTTOMLEFT", board.frame, "BOTTOMRIGHT", math.floor(BETWEEN / 2), 0)
			board.rule:SetShown(not onPet)
		end
	end
	page:ClearAllPoints()
	page:SetPoint("TOPLEFT", window.content, "TOPLEFT", M.pad, -(M.pad + strip))
	page:SetShown(onPet)
	return true
end

--------------------------------------------------------------------------
-- The strip
--------------------------------------------------------------------------

local function SpecLabel(group, active, count)
	if count < 2 then
		return "Talents"
	end
	local word
	if group == 1 then
		word = type(_G.TALENT_SPEC_PRIMARY) == "string" and _G.TALENT_SPEC_PRIMARY or "Primary"
	else
		word = type(_G.TALENT_SPEC_SECONDARY) == "string" and _G.TALENT_SPEC_SECONDARY or "Secondary"
	end
	if group == active then
		return word .. ", live"
	end
	return word
end

-- Whether the paint below is the one moving the strip, in which case the
-- strip's own callback must not paint again.
local quiet = false

local function Select(index)
	if quiet then
		return false
	end
	if index == PET then
		onPet = true
	else
		onPet = false
		viewing = index
	end
	return Window.Paint()
end

local function Activate()
	local count, active = Read.Groups()
	if count < 2 or viewing == active then
		return false
	end
	if InCombatLockdown() then
		ns.Print("the other spec cannot be made live in a fight.")
		return false
	end
	return Read.Activate(viewing)
end

--------------------------------------------------------------------------

-- The window going down takes a beast training session with it, which is what
-- closing CraftFrame did, and takes the secure square off the page.
local function Hidden()
	Training.Close()
	Pet.Place()
end

function Window.Build()
	if window then
		return window
	end

	window = UI.Window({
		name = "WarriorKitTalents",
		title = "Talents",
		width = Width(),
		height = Height(1),
		zoom = function() return ns.Zoom("talentsZoom") end,
		rescale = function(apply)
			apply()
			Window.Fit()
			Window.Refresh()
		end,
	})
	ns.Remember(window)

	-- The secure square sits over the page by position, so a drag that moved
	-- the window has to move it too. Wrapped around whatever Remember asked to
	-- be told, never in place of it.
	local told = window.place and window.place.moved
	if window.place then
		window.place:OnMoved(function(...)
			if told then
				told(...)
			end
			Pet.Place()
		end)
	end

	tabs = UI.TabStrip(window.content, { onSelect = Select })
	tabs.frame:SetPoint("TOPLEFT", M.pad, -M.pad)
	tabs:Add(SpecLabel(1, 1, 1))
	tabs:Add(SpecLabel(2, 1, 2))
	tabs:Add("Pet")

	activate = UI.Button(window.content, { label = "Make this spec live", width = 130, height = M.tab,
		onClick = Activate })
	activate:SetPoint("TOPRIGHT", -M.pad, -M.pad)

	for index = 1, Read.Tabs() do
		local board = Board.New(window.content)
		if index < Read.Tabs() then
			board.rule = UI.Rule(window.content, C.hairline, true)
		end
		boards[index] = board
	end
	page = Pet.Build(window.content)

	foot = UI.Label(window.footer, M.small, C.dim, "LEFT", UI.FLAT)
	UI.Wrap(foot, false)
	foot:SetPoint("LEFT")
	foot:SetPoint("RIGHT")

	window.frame:SetScript("OnShow", function()
		Window.Paint()
	end)
	window.frame:HookScript("OnHide", Hidden)

	viewing = select(2, Read.Groups())
	Window.Fit()
	return window
end

--------------------------------------------------------------------------
-- Painting
--------------------------------------------------------------------------

local function PointsLine(unspent)
	if unspent < 1 then
		return "No points to spend"
	end
	if unspent == 1 then
		return "1 point to spend"
	end
	return ("%d points to spend"):format(unspent)
end

local function Foot(unspent)
	if not onPet then
		return ("%s. %s."):format(PointsLine(unspent), Cost.Describe())
	end
	local left = Training.Points()
	local where = Training.Open() and "Beast Training closes with this window"
		or "Beast Training lists what your pet can learn"
	return ("%s training. %s."):format(PointsLine(left), where)
end

-- Every board, the strip and the foot. The window is then fitted again,
-- because how tall the boards came out is only known once they are painted.
--
-- The boards are painted on the pet's tab as well. The window keeps the size
-- the trees give it, so changing tab does not jump, and it cannot know that
-- size without them.
function Window.Paint()
	if not window then
		return false
	end
	local count, active = Read.Groups()
	if count < 2 or viewing < 1 or viewing > count then
		viewing = active
	end
	if onPet and not Training.Offered() then
		onPet = false
	end
	local live = viewing == active
	local unspent = Read.Unspent(viewing)

	tiers = 1
	for index = 1, #boards do
		local _, deep = boards[index]:Set(index, viewing, unspent, live)
		if deep > tiers then
			tiers = deep
		end
	end
	if onPet then
		petTall = Pet.Paint(Width() - M.pad * 2, BETWEEN)
	end

	if Striped(count) then
		tabs:SetLabel(1, SpecLabel(1, active, count))
		tabs:SetLabel(2, SpecLabel(2, active, count))
		local want = onPet and PET or viewing
		if tabs.selected ~= want then
			quiet = true
			tabs:Select(want)
			quiet = false
		end
	end

	foot:SetText(Foot(unspent))
	Window.Fit()
	-- After the fit, because the fit is what put the page where the square has
	-- to follow it.
	Pet.Place()
	return true
end

function Window.Built()
	return window ~= nil
end

function Window.Shown()
	return window ~= nil and window:IsShown()
end

function Window.Show()
	Window.Build()
	if not window:IsShown() then
		window:Show()
	else
		Window.Paint()
	end
	return true
end

-- Open on the pet's tab, which is where the client opening beast training and
-- the slash word both land. Refused on a class with no pet to train.
function Window.ShowPet()
	if not Training.Offered() then
		return false
	end
	Window.Build()
	onPet = true
	return Window.Show()
end

function Window.Hide()
	if not window then
		return false
	end
	window:Hide()
	return true
end

function Window.Toggle()
	if Window.Shown() then
		return Window.Hide()
	end
	return Window.Show()
end

-- The other group's boards, for the harness and the slash word. A group this
-- character does not have is refused rather than drawn empty.
function Window.View(group)
	local count = Read.Groups()
	if group < 1 or group > count then
		return false
	end
	viewing = group
	onPet = false
	return Window.Paint()
end

function Window.Viewing()
	return viewing
end

function Window.OnPet()
	return onPet
end

function Window.Tabs()
	return tabs
end

function Window.Board(index)
	return boards[index]
end

function Window.Tiers()
	return tiers
end

-- Repainted only while it is up. Every event below fires whether or not
-- anybody is looking, and walking a hundred talents to update a window nobody
-- has open is the waste this addon has a gate for.
function Window.Refresh()
	if Window.Shown() then
		return Window.Paint()
	end
	return false
end

-- The three trees in a sentence, for the panel and the slash word.
function Window.Trees()
	local parts = {}
	for tab = 1, Read.Tabs() do
		local name, _, points = Read.Tree(tab)
		parts[#parts + 1] = ("%d %s"):format(points or 0, name or ("tree " .. tab))
	end
	return table.concat(parts, ", ")
end

function Window.Describe()
	if not ns.db.talents then
		return "off"
	end
	if not window then
		return "not built yet"
	end
	if not Window.Shown() then
		return "closed"
	end
	if onPet then
		return "open on the pet"
	end
	local count, active = Read.Groups()
	if count > 1 then
		return ("open on %s"):format(SpecLabel(viewing, active, count))
	end
	return "open"
end

--------------------------------------------------------------------------
-- Events
--
-- Every one is pcalled onto the frame, because the two clients this addon runs
-- on disagree about two of them and registering an event a client has never
-- heard of raises rather than being ignored.
--------------------------------------------------------------------------

local WATCHED = {
	"PLAYER_TALENT_UPDATE",
	"CHARACTER_POINTS_CHANGED",
	"ACTIVE_TALENT_GROUP_CHANGED",
	"PLAYER_LEVEL_UP",
	"CRAFT_SHOW",
	"CRAFT_UPDATE",
	"CRAFT_CLOSE",
	"UNIT_PET",
	"UNIT_PET_TRAINING_POINTS",
}

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
for index = 1, #WATCHED do
	pcall(events.RegisterEvent, events, WATCHED[index])
end
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		if ns.db.talents then
			Window.Build()
		end
		return
	end
	if event == "CRAFT_SHOW" then
		-- UIParent has already loaded and shown CraftFrame by now: it registered
		-- the event before any addon. So the frame is there for the park.
		if Training.Opened() then
			Window.ShowPet()
		end
		ns.TrainingBlizzard.Apply()
		return
	end
	if event == "CRAFT_CLOSE" then
		Training.Closed()
		ns.TrainingBlizzard.Apply()
	elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
		-- Back onto the live one. The tab you were reading was the one you
		-- asked to be made live, and it is now.
		viewing = select(2, Read.Groups())
	end
	Window.Refresh()
end)
