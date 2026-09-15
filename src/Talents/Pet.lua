local ADDON, ns = ...

local Pet = {}
ns.TalentPet = Pet

local UI = ns.UI
local C, M = UI.Color, UI.Metric
local Training, Board = ns.TalentTraining, ns.TalentBoard

--------------------------------------------------------------------------
-- The pet's page
--
-- The third tab on a hunter's talent window. A heading with the pet, its level
-- and the training points it has to spend, and under it every ability Beast
-- Training offers, in three columns the width of the three trees, one square
-- each with its rank and its price. A press teaches the pet, and only where
-- the pet is high enough and the points are there.
--
-- **The squares are the talent board's.** The same dressed square and the same
-- rims: gold for an ability the pet already has, green for one a press would
-- teach, the theme's edge for one the points do not stretch to, and the
-- hairline with the picture greyed for one the pet is too young for. A page
-- that coloured the same four facts differently from the trees beside it would
-- be two windows sharing a frame.
--
-- **The list is only there while the client's session is.** Training.lua says
-- why: nothing answers about beast training until the spell has been cast. So
-- with the session shut the page draws one square, Beast Training itself, and
-- a press on it casts the spell. The client opens the session, the window hears
-- CRAFT_SHOW and the list arrives.
--
-- **That one square is secure, and it is not on the window.** Casting is
-- protected, so the square is a SecureActionButtonTemplate. A protected frame
-- makes every frame it hangs off protected as well, and the talent window is
-- insecure on purpose: it opens with N in a fight. So the square is parented
-- to UIParent, anchored to UIParent, and laid over an empty spot on the page by
-- position and scale, which ties nothing on the window to it. Moving it is
-- refused in a fight, so it is placed out of one, and a state driver hides it
-- the moment a fight starts; PLAYER_REGEN_ENABLED puts it back. Everything
-- else on the page is an ordinary button, because teaching a pet an ability is
-- not a protected act.
--
-- Nothing here is on a ticker. The page paints when the window does.
--------------------------------------------------------------------------

local SQUARE = UI.SLOT

-- One row's pitch, the spell book's: a square and the air to the next one.
local PITCH = SQUARE + 6

local COLUMNS = 3

local page, head, title, points, spot, invite
local rows = {}
local shown = 0

-- Whether the square belongs on the page right now, and whether a fight
-- refused the last attempt to say so.
local wanted, pending = false, false

-- The pet's level and the points left at the last paint, which is what a hover
-- and a press read.
local petLevel, left = 0, 0

--------------------------------------------------------------------------
-- The secure square
--------------------------------------------------------------------------

local cast = CreateFrame("Button", "WarriorKitBeastTraining", UIParent, "SecureActionButtonTemplate")
cast:SetSize(SQUARE, SQUARE)
UI.Dress(cast, SQUARE)
-- The up edge and the attribute that says so, in agreement, for the reason
-- Hover/Cast.lua gives: a secure button acts only on the edge useOnKeyDown
-- names, whatever it registered for.
cast:RegisterForClicks("AnyUp")
cast:SetAttribute("useOnKeyDown", false)
cast:SetAttribute("type", "spell")
cast:SetAttribute("spell", Training.SPELL)
cast:Hide()

local function CastSubject()
	local name = Training.Name() or "Beast Training"
	local lines = { { "Opens the list of what your pet can learn", color = C.hint } }
	if not UnitExists("pet") then
		lines[#lines + 1] = { "Call your pet first", color = C.dim }
	end
	return { kind = "spell", spell = Training.SPELL, title = name, lines = lines }
end

cast:SetScript("OnEnter", function(this)
	ns.Tip.Open(this, CastSubject(), nil, UI.Tooltip.BESIDE)
end)
cast:SetScript("OnLeave", function()
	ns.Tip.Close()
end)

-- Hidden in the secure environment when a fight starts, because that is the
-- only place a protected frame can still be hidden from once it has. Charge
-- /Icon.lua's binder is the same shape. Absent where the client has no state
-- driver, and then the square simply stays where it was for the fight.
local driver
if _G.RegisterStateDriver then
	local ok, made = pcall(CreateFrame, "Frame", nil, UIParent, "SecureHandlerStateTemplate")
	if ok and made and made.Execute then
		driver = made
		driver:SetFrameRef("cast", cast)
		driver:Execute([[ cast = self:GetFrameRef("cast") ]])
		driver:SetAttribute("_onstate-combat", [[ if newstate == "on" then cast:Hide() end ]])
		RegisterStateDriver(driver, "combat", "[combat] on; off")
	end
end

-- Over the spot, at the spot's own scale, or off the screen. Refused in a fight
-- and put right when it ends.
--
-- The offsets are the spot's own left and top. With the square scaled to the
-- spot's effective scale the two share a unit, and UIParent's bottom left is
-- the screen's.
function Pet.Place()
	if InCombatLockdown() then
		pending = true
		return false
	end
	pending = false
	local up = wanted and spot ~= nil and spot:IsVisible()
	local x, y = spot and spot:GetLeft(), spot and spot:GetTop()
	if up and x and y then
		cast:SetScale(spot:GetEffectiveScale() / UIParent:GetEffectiveScale())
		cast:ClearAllPoints()
		cast:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		cast:SetFrameStrata(page:GetFrameStrata() or "HIGH")
		cast:SetFrameLevel((spot:GetFrameLevel() or 0) + 10)
		cast.art:SetTexture((select(3, GetSpellInfo(Training.SPELL))))
		cast:Show()
		return true
	end
	cast:Hide()
	return false
end

--------------------------------------------------------------------------
-- The rows
--------------------------------------------------------------------------

-- What a row costs and what stands in the way, in the words its second line and
-- its hover share.
local function Price(row)
	if row.cost < 1 then
		return "free"
	end
	return ("%d points"):format(row.cost)
end

local function Label(row, rest)
	if row.rank == "" then
		return rest
	end
	return ("%s, %s"):format(row.rank, rest)
end

local function Verdict(row)
	if row.known then
		return "Your pet knows this", C.heading
	end
	if row.level > petLevel then
		return ("Needs your pet at level %d"):format(row.level), C.dim
	end
	if row.cost > left then
		return ("Needs %d training points and your pet has %d"):format(row.cost, left), C.dim
	end
	return "Click to teach your pet", C.hint
end

local function Subject(row)
	local verdict, color = Verdict(row)
	local lines = { { Label(row, Price(row)) }, { verdict, color = color } }
	return { kind = "craft", index = row.index, title = row.name, lines = lines }
end

local function OnEnter(row)
	UI.Tint(row.square.bg, C.hover)
	ns.Tip.Open(row, Subject(row), nil, UI.Tooltip.BESIDE)
end

local function OnLeave(row)
	UI.Tint(row.square.bg, C.sunken)
	ns.Tip.Close()
end

-- Refused without a word where the hover already says why, for the reason the
-- talent squares give.
local function OnClick(row)
	if not row.learnable then
		return false
	end
	return Training.Learn(row.index)
end

local function Row(at)
	local row = rows[at]
	if row then
		return row
	end
	row = CreateFrame("Button", nil, page)
	row:SetHeight(SQUARE)
	row:RegisterForClicks("LeftButtonUp")
	row:SetScript("OnEnter", OnEnter)
	row:SetScript("OnLeave", OnLeave)
	row:SetScript("OnClick", OnClick)
	UI.PassCamera(row)

	row.square = CreateFrame("Frame", nil, row)
	row.square:SetSize(SQUARE, SQUARE)
	row.square:SetPoint("LEFT")
	UI.Dress(row.square, SQUARE)

	row.title = UI.Label(row, M.font, C.text, "LEFT", UI.FLAT)
	UI.Wrap(row.title, false)
	row.title:SetPoint("TOPLEFT", row.square, "TOPRIGHT", M.gutter, 0)
	row.title:SetPoint("RIGHT")

	row.sub = UI.Label(row, M.small, C.dim, "LEFT", UI.FLAT)
	UI.Wrap(row.sub, false)
	row.sub:SetPoint("BOTTOMLEFT", row.square, "BOTTOMRIGHT", M.gutter, 0)
	row.sub:SetPoint("RIGHT")

	rows[at] = row
	return row
end

-- The rim, the picture and the two lines, off what the row now knows.
local function Paint(row)
	local edge, dim
	if row.known then
		edge = C.heading
	elseif row.level > petLevel then
		edge, dim = C.hairline, true
	elseif row.cost > left then
		edge, dim = C.edge, true
	else
		edge = C.tick
	end
	row.learnable = edge == C.tick
	ns.Recolor(row.square.edges, edge)
	row.square.art:SetTexture(row.icon)
	row.square.art:SetDesaturated(dim and true or false)
	row.square.art:SetAlpha(dim and 0.55 or 1)
	row.dim = dim and true or false

	row.title:SetText(row.name)
	local ink = row.known and C.heading or C.text
	row.title:SetTextColor(ink[1], ink[2], ink[3])
	if row.known then
		row.sub:SetText(Label(row, "known"))
	elseif row.level > petLevel then
		row.sub:SetText(Label(row, ("pet level %d"):format(row.level)))
	else
		row.sub:SetText(Label(row, Price(row)))
	end
end

--------------------------------------------------------------------------
-- Building and painting
--------------------------------------------------------------------------

function Pet.Build(parent)
	if page then
		return page
	end
	page = CreateFrame("Frame", nil, parent)
	page:Hide()

	head = UI.Icon(page, "ARTWORK")
	head:SetSize(Board.HEAD, Board.HEAD)
	head:SetPoint("TOPLEFT")

	points = UI.Label(page, M.font, C.dim, "RIGHT", UI.FLAT)
	UI.Wrap(points, false)
	points:SetPoint("RIGHT", page, "TOPRIGHT", 0, -math.floor(Board.HEAD / 2))

	title = UI.Label(page, M.heading, C.heading, "LEFT", UI.FLAT)
	UI.Wrap(title, false)
	title:SetPoint("LEFT", head, "RIGHT", M.gutter, 0)
	title:SetPoint("RIGHT", points, "LEFT", -M.gutter, 0)

	-- Where the secure square is laid. An empty frame the size of one, which is
	-- what gives the square a place on the page without the page holding it.
	spot = CreateFrame("Frame", nil, page)
	spot:SetSize(SQUARE, SQUARE)
	spot:SetPoint("TOPLEFT", 0, -(Board.HEAD + M.gutter))

	invite = UI.Label(page, M.font, C.text, "LEFT", UI.FLAT)
	UI.Wrap(invite, false)
	invite:SetPoint("LEFT", spot, "RIGHT", M.gutter, 0)
	invite:SetPoint("RIGHT")

	page:SetScript("OnShow", Pet.Place)
	page:SetScript("OnHide", Pet.Place)
	return page
end

local function Heading()
	local name, family, level = Training.Pet()
	petLevel = level or 0
	head:SetTexture((select(3, GetSpellInfo(Training.SPELL))))
	if not name then
		title:SetText("No pet")
	elseif family then
		title:SetText(("%s, level %d %s"):format(name, petLevel, family))
	else
		title:SetText(("%s, level %d"):format(name, petLevel))
	end
	local total
	left, total = Training.Points()
	if total < 1 then
		points:SetText("no training points")
	elseif left == 1 then
		points:SetText("1 point to spend")
	else
		points:SetText(("%d points to spend"):format(left))
	end
	return name
end

-- Every ability the session lists, laid into columns. Answers how many rows
-- that came to.
local function List(width, gap)
	local column = math.floor((width - (COLUMNS - 1) * gap) / COLUMNS)
	local count = Training.Count()
	local found = {}
	for index = 1, count do
		local name, rank, known, cost, level, icon = Training.Entry(index)
		if name then
			local row = Row(#found + 1)
			row.index, row.name, row.rank, row.known = index, name, rank, known
			row.cost, row.level, row.icon = cost, level, icon
			found[#found + 1] = row
		end
	end
	local per = math.max(1, math.ceil(#found / COLUMNS))
	for at = 1, #found do
		local row = found[at]
		local across, down = math.floor((at - 1) / per), (at - 1) % per
		row:SetWidth(column)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", page, "TOPLEFT", across * (column + gap), -(Board.HEAD + M.gutter + down * PITCH))
		Paint(row)
		row:Show()
	end
	for at = #found + 1, #rows do
		rows[at]:Hide()
	end
	return #found, per
end

-- The page, for a window this wide with this much air between columns. Answers
-- how tall it came out.
function Pet.Paint(width, gap)
	page:SetWidth(width)
	local pet = Heading()
	local tall = Board.HEAD + M.gutter
	if Training.Open() then
		wanted = false
		invite:Hide()
		local count, per = List(width, gap)
		shown = count
		tall = tall + per * PITCH - (PITCH - SQUARE)
	else
		wanted = true
		shown = 0
		for at = 1, #rows do
			rows[at]:Hide()
		end
		invite:SetText(pet and ("Beast Training: press the square to list what %s can learn."):format(pet)
			or "Beast Training teaches the pet you have out. Call your pet first.")
		invite:Show()
		tall = tall + SQUARE
	end
	page:SetHeight(tall)
	Pet.Place()
	return tall
end

function Pet.Page()
	return page
end

function Pet.Square()
	return cast
end

function Pet.Spot()
	return spot
end

function Pet.Driver()
	return driver
end

function Pet.Rows()
	return shown
end

function Pet.Row(at)
	if at > shown then
		return nil
	end
	return rows[at]
end

-- The fight ended with a placement owed.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
	if pending then
		Pet.Place()
	end
end)
