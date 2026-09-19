local ADDON, ns = ...

local Pet = {}
ns.TalentPet = Pet

local UI = ns.UI
local C, M = UI.Color, UI.Metric
local Training, Board = ns.TalentTraining, ns.TalentBoard
local PetTrace = ns.PetTrace

--------------------------------------------------------------------------
-- The pet's page
--
-- The third tab on a hunter's talent window. A heading with the pet, its level
-- and its training points, spent and left. Under it what the pet already
-- knows, read off its own spell book, and under that what Beast Training can
-- still teach it, in three columns the width of the three trees.
--
-- **The squares are the talent board's.** The same dressed square and the same
-- rims: gold for an ability the pet has, green for one a press would teach, the
-- theme's edge for one the points do not stretch to, and the hairline with the
-- picture greyed for one the pet is too young for.
--
-- **The list of what can be taught is only there while the session is.**
-- Training.lua says why. With the session shut the page draws one square,
-- Beast Training itself, and a press on it casts the spell.
--
-- **Two presses are protected, and neither button is on the window.** Casting
-- is one. DoCraft is the other: a row that called it from its own OnClick put
-- up the client's interface error, because on 2.5.6 an addon may not teach a
-- pet. Blizzard's CraftCreateButton may, from its own OnClick, and a secure
-- button of type `click` presses it for us. So a hover on a teachable row lays
-- the secure button over the row, and the press does the rest in one click:
-- PreClick picks the row and enables the create button for it, the secure
-- button presses CraftCreateButton, and that button's OnClick calls DoCraft on
-- the row picked. Picked in the press rather than on the hover, so nothing
-- between the two can leave the button disabled or on another row.
--
-- A protected frame makes every frame it hangs off protected as well, and the
-- talent window is insecure on purpose: it opens with N in a fight. So both
-- secure buttons are parented to UIParent, anchored to UIParent, and laid over
-- the page by position and scale, which ties nothing on the window to them.
-- Moving them is refused in a fight, so they are placed out of one, and a
-- state driver hides both the moment a fight starts.
--
-- Nothing here is on a ticker. The page paints when the window does.
--------------------------------------------------------------------------

local SQUARE = UI.SLOT

-- One row's pitch, the spell book's: a square and the air to the next one.
local PITCH = SQUARE + 6

local COLUMNS = 3

-- A line of small heading text above each list.
local LABEL = M.row

local page, head, title, points, spot, invite, knownLabel, knownNone, trainLabel
local rows, known, book = {}, {}, {}
local shown, shownKnown = 0, 0

-- Whether the cast square belongs on the page right now.
local wanted = false

-- The pet's level and the points left at the last paint, which is what a hover
-- reads.
local petLevel, left = 0, 0

--------------------------------------------------------------------------
-- The secure buttons
--------------------------------------------------------------------------

-- The release, because the mouse is what presses these.
local function Secure(name)
	local button = ns.UI.Press.Button(UIParent, name, "up")
	button:Hide()
	return button
end

local cast = Secure("WarriorKitBeastTraining")
cast:SetSize(SQUARE, SQUARE)
UI.Dress(cast, SQUARE)
cast:SetAttribute("type", "spell")
cast:SetAttribute("spell", Training.SPELL)

-- Clear, and the size of whichever row it is laid over. The row under it draws
-- the square and the words.
local teach = Secure("WarriorKitBeastTeach")
teach:SetAttribute("type", "click")

-- Hidden in the secure environment when a fight starts, because that is the
-- only place a protected frame can still be hidden from once it has. Charge
-- /Icon.lua's binder is the same shape.
local driver
if _G.RegisterStateDriver then
	local ok, made = pcall(CreateFrame, "Frame", nil, UIParent, "SecureHandlerStateTemplate")
	if ok and made and made.Execute then
		driver = made
		driver:SetFrameRef("cast", cast)
		driver:SetFrameRef("teach", teach)
		driver:Execute([[ cast = self:GetFrameRef("cast") teach = self:GetFrameRef("teach") ]])
		driver:SetAttribute("_onstate-combat", [[ if newstate == "on" then cast:Hide() teach:Hide() end ]])
		RegisterStateDriver(driver, "combat", "[combat] on; off")
	end
end

-- A secure button over a region of the page, at the region's scale.
--
-- The offsets are the region's own left and top. With the button scaled to the
-- region's effective scale the two share a unit, and UIParent's bottom left is
-- the screen's.
local function Over(button, region)
	local x, y = region:GetLeft(), region:GetTop()
	if not x or not y then
		return false
	end
	button:SetScale(region:GetEffectiveScale() / UIParent:GetEffectiveScale())
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	button:SetSize(region:GetWidth(), region:GetHeight())
	button:SetFrameStrata(page:GetFrameStrata() or "HIGH")
	button:SetFrameLevel((region:GetFrameLevel() or 0) + 10)
	button:Show()
	return true
end

-- The cast square over its spot, or off the screen. Held to the end of a
-- fight, because the square is a secure button.
function Pet.Place()
	if ns.Lockdown.Held(Pet.Place) then
		return false
	end
	if wanted and spot and spot:IsVisible() and Over(cast, spot) then
		cast.art:SetTexture((select(3, GetSpellInfo(Training.SPELL))))
		return true
	end
	cast:Hide()
	return false
end

-- The teaching button off whatever row it was over.
local function Lift()
	if InCombatLockdown() then
		return false
	end
	teach.row = nil
	teach:Hide()
	return true
end

local function CastSubject()
	local lines = { { "Opens the list of what your pet can learn", color = C.hint } }
	if not UnitExists("pet") then
		lines[#lines + 1] = { "Call your pet first", color = C.dim }
	end
	return { kind = "spell", spell = Training.SPELL, title = Training.Name() or "Beast Training", lines = lines }
end

cast:SetScript("OnEnter", function(this)
	ns.Tip.Open(this, CastSubject(), "spell")
end)
cast:SetScript("OnLeave", function()
	ns.Tip.Close()
end)

--------------------------------------------------------------------------
-- The rows
--------------------------------------------------------------------------

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
	if row.level > petLevel then
		return ("Needs your pet at level %d"):format(row.level), C.dim
	end
	if row.cost > left then
		return ("Needs %d training points and your pet has %d"):format(row.cost, left), C.dim
	end
	return "Click to teach your pet", C.hint
end

local function Subject(row)
	if row.known then
		return { kind = "note", title = row.name, lines = { { row.rank }, { "Your pet knows this", color = C.heading } } }
	end
	local verdict, color = Verdict(row)
	local lines = { { Label(row, Price(row)) }, { verdict, color = color } }
	return { kind = "craft", index = row.index, title = row.name, lines = lines }
end

local function Look(row)
	UI.Tint(row.square.bg, C.hover)
	ns.Tip.Open(row, Subject(row), "spell")
end

local function Unlook(row)
	UI.Tint(row.square.bg, C.sunken)
	ns.Tip.Close()
end

-- The secure button onto a teachable row. Answers whether it went over the row
-- and why not, which is what the trace says on a hover.
local function Arm(row)
	if not row.learnable then
		return false, "not teachable by the page's reading"
	end
	if InCombatLockdown() then
		return false, "in a fight"
	end
	local button = Training.Button()
	if not button then
		return false, "no beast training session or no create button"
	end
	teach:SetAttribute("clickbutton", button)
	teach.row = row
	if not Over(teach, row) then
		return false, "the row has no position yet"
	end
	return true, "secure button laid over it"
end

local function OnEnter(row)
	Look(row)
	local armed, why = Arm(row)
	PetTrace.Hover(row, petLevel, left, armed, why)
end

-- The pointer leaving a row for the button laid over it has not left the row.
local function OnLeave(row)
	if teach.row == row and teach:IsShown() then
		return
	end
	Unlook(row)
end

-- The row is picked ahead of the client's half of the press, so the create
-- button is enabled and on this row at the moment it is clicked.
--
-- The row is held for PostClick as well: teaching fires CRAFT_UPDATE, and the
-- repaint that follows takes the button off the row.
local pressed
teach:SetScript("PreClick", function(this)
	pressed = this.row
	PetTrace.Press(pressed, this, "before")
	if pressed then
		Training.Select(pressed.index)
	end
	PetTrace.Press(pressed, this, "picked")
end)
teach:SetScript("PostClick", function()
	PetTrace.After(pressed)
end)
teach:SetScript("OnEnter", function(this)
	if this.row then
		Look(this.row)
	end
end)
teach:SetScript("OnLeave", function(this)
	if this.row then
		Unlook(this.row)
	end
	Lift()
end)

local function Row(pool, at)
	local row = pool[at]
	if row then
		return row
	end
	row = CreateFrame("Button", nil, page)
	row:SetHeight(SQUARE)
	row:SetScript("OnEnter", OnEnter)
	row:SetScript("OnLeave", OnLeave)
	-- Only ever reached by a press the secure button did not take.
	row:SetScript("OnClick", function(this)
		PetTrace.Missed(this, teach)
	end)
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

	pool[at] = row
	return row
end

-- The rim, the picture and the two lines, off what the row now knows.
local function Paint(row)
	local edge, dim, sub
	if row.known then
		edge, sub = C.heading, row.rank
	elseif row.level > petLevel then
		edge, dim, sub = C.hairline, true, Label(row, ("pet level %d"):format(row.level))
	elseif row.cost > left then
		edge, dim, sub = C.edge, true, Label(row, Price(row))
	else
		edge, sub = C.tick, Label(row, Price(row))
	end
	row.learnable = edge == C.tick
	row.dim = dim and true or false
	ns.Recolor(row.square.edges, edge)
	row.square.art:SetTexture(row.icon)
	row.square.art:SetDesaturated(row.dim)
	row.square.art:SetAlpha(dim and 0.55 or 1)
	row.title:SetText(row.name)
	local ink = row.known and C.heading or C.text
	row.title:SetTextColor(ink[1], ink[2], ink[3])
	row.sub:SetText(sub)
end

-- A list of rows laid into columns from `top` down. Answers how tall that is.
local function Lay(pool, count, top, width, gap)
	local column = math.floor((width - (COLUMNS - 1) * gap) / COLUMNS)
	local per = math.max(1, math.ceil(count / COLUMNS))
	for at = 1, count do
		local row = pool[at]
		local across, down = math.floor((at - 1) / per), (at - 1) % per
		row:SetWidth(column)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", page, "TOPLEFT", across * (column + gap), -(top + down * PITCH))
		row:Show()
	end
	for at = count + 1, #pool do
		pool[at]:Hide()
	end
	if count < 1 then
		return 0
	end
	return per * PITCH - (PITCH - SQUARE)
end

-- What the pet knows, off its book.
local function FillKnown()
	Training.Known(book)
	for at = 1, #book do
		local entry, row = book[at], Row(known, at)
		row.name, row.rank, row.icon, row.known = entry.name, entry.rank, entry.icon, true
		Paint(row)
	end
	return #book
end

-- What the session can still teach. A row the pet has is on the list above
-- already, so it is not drawn twice.
local function FillTrainable()
	local count = 0
	for index = 1, Training.Count() do
		local name, rank, has, cost, level, icon = Training.Entry(index)
		if name and not has then
			count = count + 1
			local row = Row(rows, count)
			row.index, row.name, row.rank, row.known = index, name, rank, false
			row.cost, row.level, row.icon = cost, level, icon
			Paint(row)
		end
	end
	return count
end

--------------------------------------------------------------------------
-- Building and painting
--------------------------------------------------------------------------

local function Small(text)
	local label = UI.Label(page, M.small, C.dim, "LEFT", UI.FLAT)
	UI.Wrap(label, false)
	label:SetText(text or "")
	return label
end

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

	knownLabel, knownNone, trainLabel = Small(), Small(), Small("Beast Training")

	-- Where the cast square is laid. An empty frame the size of one, which is
	-- what gives the square a place on the page without the page holding it.
	spot = CreateFrame("Frame", nil, page)
	spot:SetSize(SQUARE, SQUARE)

	invite = UI.Label(page, M.font, C.text, "LEFT", UI.FLAT)
	UI.Wrap(invite, false)
	invite:SetPoint("LEFT", spot, "RIGHT", M.gutter, 0)
	invite:SetPoint("RIGHT")

	page:SetScript("OnShow", Pet.Place)
	page:SetScript("OnHide", function()
		Lift()
		Pet.Place()
	end)
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
	local total, spent
	left, total, spent = Training.Points()
	if total < 1 then
		points:SetText("no training points")
	else
		points:SetText(("%d spent, %d left"):format(spent, left))
	end
	return name
end

local function At(region, top)
	region:ClearAllPoints()
	region:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -top)
end

-- The session half, from `top` down. Answers how tall it came out.
local function Session(pet, top, width, gap)
	At(spot, top)
	if not Training.Open() then
		wanted = true
		shown = Lay(rows, 0, top, width, gap)
		invite:SetText(pet and ("Press the square to list what %s can learn."):format(pet)
			or "Beast Training teaches the pet you have out. Call your pet first.")
		invite:Show()
		return SQUARE
	end
	wanted = false
	shown = FillTrainable()
	invite:SetText(("Beast Training has nothing more to teach %s now."):format(pet or "your pet"))
	invite:SetShown(shown == 0)
	if shown == 0 then
		Lay(rows, 0, top, width, gap)
		return SQUARE
	end
	return Lay(rows, shown, top, width, gap)
end

-- The page, for a window this wide with this much air between columns. Answers
-- how tall it came out.
function Pet.Paint(width, gap)
	Lift()
	page:SetWidth(width)
	local pet = Heading()

	local top = Board.HEAD + M.gutter
	At(knownLabel, top)
	knownLabel:SetText(pet and ("What %s knows"):format(pet) or "What your pet knows")
	top = top + LABEL
	shownKnown = pet and FillKnown() or 0
	local tall = Lay(known, shownKnown, top, width, gap)
	At(knownNone, top)
	knownNone:SetText(pet and "Nothing taught yet" or "Call your pet to see what it knows")
	knownNone:SetShown(shownKnown == 0)
	top = top + math.max(tall, LABEL) + M.gutter * 2

	At(trainLabel, top)
	top = top + LABEL
	top = top + Session(pet, top, width, gap)

	page:SetHeight(top)
	Pet.Place()
	return top
end

function Pet.Page()
	return page
end

function Pet.Square()
	return cast
end

function Pet.Teach()
	return teach
end

function Pet.Spot()
	return spot
end

function Pet.Driver()
	return driver
end

function Pet.Summary()
	return points and points:GetText()
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

function Pet.KnownRows()
	return shownKnown
end

function Pet.Known(at)
	if at > shownKnown then
		return nil
	end
	return known[at]
end

