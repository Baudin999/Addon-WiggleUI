local ADDON, ns = ...

local Pet = {}
ns.PetBar = Pet

local UI = ns.UI
local Ability, Flow = UI.Ability, UI.Flow

--------------------------------------------------------------------------
-- The pet bar, drawn as our own squares
--
-- Ten squares in the look of the action bars, standing in for Blizzard's
-- PetActionBar while the action bar clone is on. Buttons/Bars.lua is the clone
-- of the twelve slot bars and none of its machinery fits here: a pet slot is
-- not an action slot, nothing pages it, and the client already binds its keys
-- to a call that needs no button on the screen.
--
-- What each half of a press reaches, read off Blizzard_ActionBar/Shared/
-- PetActionBar.lua and Blizzard_FrameXML/SecureTemplates.lua on the
-- classic_anniversary source:
--
--   A left press is the secure `pet` action, which the template turns into
--   CastPetAction on the slot in the `action` attribute.
--
--   A right press clicks Blizzard's own PetActionButtonN. Its OnClick toggles
--   autocast for any button that is not the left one, so a right click does
--   what it did on Blizzard's bar and this file never names the autocast call.
--
--   A key is left where it is. BONUSACTIONBUTTON1 to 10 call
--   PetActionBar:PetActionButtonDown and Up, which cast whether that bar is on
--   the screen or not, so no override is taken and nothing is handed back.
--
-- Blizzard's bar goes into the attic by Attic.Take alone. Attic.Vanish would
-- also run ns.Strip, which writes the bar's Show field, and
-- PetActionBarMixin:OnEvent calls self:Show() and then lays out ten secure
-- buttons. A Show read out of an addon's write is a tainted call in front of
-- that work. The cage needs no field: a frame whose parent is hidden is not
-- drawn and takes no mouse, whatever it calls on itself.
--
-- The client decides when the bar is up, through a state driver, because a pet
-- dies and is summoned in a fight. It is placed with UI.Placeable like the unit
-- frames rather than by Buttons/Placing.lua, which holds one list of bars on
-- plan positions and would hand its shift watcher this bar instead of theirs.
--------------------------------------------------------------------------

-- NUM_PET_ACTION_SLOTS, the first line of Shared/PetActionBar.lua.
local SLOTS = 10

-- The action bars' rate, for their reason: a countdown under ten seconds is
-- printed in tenths and a slower pass would make it jump.
local UPDATE_INTERVAL = 0.1

-- Buttons/Slot.lua's line between a swipe and a countdown. Below it the swipe
-- has already said everything.
local GCD = 1.5

local VISIBILITY = "[pet] show; hide"

-- The autocast mark, a gold corner at the bottom left of the art, where no
-- number on a square is drawn. Full while the ability casts itself and faint
-- while it could and is switched off, which are the two states Blizzard draws
-- as a turning glow and as corner brackets.
local AUTO_SIDE = 5
local AUTO_ON, AUTO_OFF = 1, 0.35

-- The key the square size is asked under. No record is ever written for it, so
-- Buttons/Look.lua answers the size every bar ships at and the argument for
-- that number stays in one file.
local LOOK = { key = "pet" }

local bar, place
local squares = {}
local live = false     -- the clone is on and the tick should draw
local driven = false   -- the client holds the bar's visibility
local pending          -- work combat refused, retried at PLAYER_REGEN_ENABLED

--------------------------------------------------------------------------
-- One square
--------------------------------------------------------------------------

-- What is on the slot, in the client's own words. Closed on an empty slot for
-- Buttons/Square.lua's reason: a hover that opens nothing leaves the last box on
-- screen, pointing at a square with nothing in it.
local function Enter(self)
	local _, texture = GetPetActionInfo(self.slot)
	if not texture then
		ns.Tip.Close(true)
		return
	end
	ns.Tip.Open(self, { kind = "pet", slot = self.slot, place = UI.Tooltip.BESIDE })
end

local function Leave()
	ns.Tip.Close()
end

-- Picked up and put down the way Blizzard's button does both: PickupPetAction on
-- the slot, and a drop only takes a pet action. Refused in combat, where a drag
-- across the bar is a misclick rather than a decision.
local function Lift(self)
	if InCombatLockdown() then
		return
	end
	PickupPetAction(self.slot)
end

local function Drop(self)
	if InCombatLockdown() or GetCursorInfo() ~= "petaction" then
		return
	end
	PickupPetAction(self.slot)
end

local function Square(index)
	local w = Ability.New(bar, ("WarriorKitPetButton%d"):format(index),
		"SecureActionButtonTemplate", Ability.QUIET)
	w.slot = index

	-- The up edge on both switches, which is the pairing Buttons/Bars.lua
	-- argues for: the registration the mouse obeys and the attribute the
	-- secure half reads have to agree, or the square pushes and does nothing.
	w:RegisterForClicks("AnyUp")
	w:SetAttribute("useOnKeyDown", false)
	w:SetAttribute("type", "pet")
	w:SetAttribute("action", index)
	local theirs = _G["PetActionButton" .. index]
	if theirs then
		w:SetAttribute("type2", "click")
		w:SetAttribute("clickbutton2", theirs)
	end

	w:RegisterForDrag("LeftButton")
	w:SetScript("OnEnter", Enter)
	w:SetScript("OnLeave", Leave)
	w:SetScript("OnDragStart", Lift)
	w:SetScript("OnReceiveDrag", Drop)

	-- Anchored to the art, so Ability.Size moving the art moves the mark.
	w.auto = ns.Fill(w, "OVERLAY", 1, 0.82, 0.28, 1)
	w.auto:SetPoint("BOTTOMLEFT", w.icon, "BOTTOMLEFT")
	w.auto:Hide()
	w.shownAuto = 0
	return w
end

--------------------------------------------------------------------------
-- The bar
--------------------------------------------------------------------------

-- One row of ten, with the gap and the pad the action bars use, so the two read
-- as one set of bars.
local function Arrange()
	local size = ns.BarLook.Size(LOOK)
	local gap = ns.Bars.GAP
	local row = { direction = "row", gap = gap }
	for index = 1, SLOTS do
		local w = squares[index]
		Ability.Size(w, size)
		w.auto:SetSize(AUTO_SIDE, AUTO_SIDE)
		row[index] = { frame = w, width = size, height = size }
	end
	Flow.Arrange(bar, { direction = "column", gap = gap, pad = ns.Bars.PAD, row })
end

local function Moved(point)
	ns.db.petBarPoint = point
end

-- Built once, at the first apply that wants it. Ten secure buttons cannot be
-- destroyed and must never be made twice, so the off switch hides this and
-- keeps it.
local function Build()
	if bar then
		return
	end
	bar = UI.Box(UIParent, UI.Color.window, UI.Color.hairline)
	UI.Adopt(bar, 1)
	bar:Hide()
	-- The depth the action bars stand at, for Buttons/Placing.lua's reason.
	ns.BarPlace.Stand({ frame = bar })

	for index = 1, SLOTS do
		squares[index] = Square(index)
	end

	-- Refused in combat: the bar holds secure buttons, and moving their parent
	-- in a lockdown is what the client raises on.
	place = UI.Placeable(bar, { name = "pet bar", combat = false, moved = Moved })
	Arrange()
end

local function Release()
	if driven then
		pcall(UnregisterStateDriver, bar, "visibility")
		driven = false
	end
end

-- Shown first and driven second, which is the order Buttons/Bars.lua gives its
-- bars. A client with no state driver gets the pet's presence read out of
-- combat instead, on login and on UNIT_PET.
local function Drive()
	Release()
	bar:Show()
	if ns.BarLook.CanDrive()
		and pcall(RegisterStateDriver, bar, "visibility", VISIBILITY) then
		driven = true
		return
	end
	bar:SetShown(UnitExists("pet") and true or false)
end

-- Blizzard's bar in the attic, or back where it was found. True when there is
-- nothing left to do, which includes a client with no PetActionBar at all.
local function Cage(on)
	local theirs = _G.PetActionBar
	if not theirs then
		return true
	end
	if on then
		return ns.Attic.Take(theirs)
	end
	return ns.Attic.Give(theirs)
end

--------------------------------------------------------------------------
-- On and off
--------------------------------------------------------------------------

-- The keys the client's pet binding set holds, printed on the squares. Read off
-- the binding set because nothing here overrides one.
function Pet.Bind()
	if not bar then
		return
	end
	for index = 1, SLOTS do
		local key = GetBindingKey("BONUSACTIONBUTTON" .. index)
		Ability.Bind(squares[index], ns.Bars.Short(key))
	end
end

-- /wk unlock, through the buttons feature's `lock`. Refused in combat, because
-- the rim takes the mouse on a frame holding ten secure buttons.
function Pet.Lock()
	if place and not InCombatLockdown() then
		place:Lock(not ns.db.locked)
	end
end

-- Follows the action bar switch. Returns false when combat deferred the work.
function Pet.Apply()
	if not ns.db then
		return true
	end
	if InCombatLockdown() then
		pending = true
		return false
	end
	pending = nil

	if not ns.db.actionBars then
		live = false
		if bar then
			Release()
			bar:Hide()
		end
		return Cage(false)
	end

	Build()
	live = true
	place:Place(ns.db.petBarPoint)
	Drive()
	Pet.Bind()
	Pet.Lock()
	return Cage(true)
end

--------------------------------------------------------------------------
-- The tick
--
-- Every square drawn on every pass while the bar is on the screen. Ten squares
-- and three calls each is thirty calls a pass, which is what the action bars'
-- dirty bits were written to save them at sixty squares and sixteen calls. A pet
-- slot also moves without an event: range, and the pet's own mana or focus.
--------------------------------------------------------------------------

-- What a pet slot is doing, as one of Ability's statuses.
--
-- Unusable is `unknown`, the plain no: the pet is dead, stunned or short of what
-- the ability costs, and the client does not say which of those it is.
local function Paint(w)
	local slot = w.slot
	local _, texture, isToken, active, autoAllowed, autoOn, _, checksRange, inRange =
		GetPetActionInfo(slot)
	-- Attack, Follow and the three stances hand back a global's name.
	if isToken and texture then
		texture = _G[texture]
	end
	local start, duration, enable = GetPetActionCooldown(slot)

	local status = "ready"
	if not texture then
		status = "empty"
	elseif enable ~= 0 and duration and duration > GCD then
		status = "cooldown"
	elseif not GetPetActionSlotUsable(slot) then
		status = "unknown"
	elseif checksRange and not inRange then
		status = "range"
	end
	Ability.Draw(w, texture, status, start, duration, nil, active, nil)

	local auto = (autoOn and AUTO_ON) or (autoAllowed and AUTO_OFF) or 0
	if auto ~= w.shownAuto then
		w.shownAuto = auto
		w.auto:SetShown(auto > 0)
		w.auto:SetAlpha(auto)
	end
end

function Pet.Tick()
	if not live or not bar:IsVisible() then
		return
	end
	for index = 1, SLOTS do
		Paint(squares[index])
	end
end

--------------------------------------------------------------------------

function Pet.Describe()
	if not (ns.db and ns.db.actionBars) then
		return "off, Blizzard's pet bar is its own"
	end
	if not bar then
		return "not built yet"
	end
	local theirs = _G.PetActionBar
	local line = (theirs and ns.Attic.Held(theirs))
		and "ten squares, Blizzard's bar in the attic"
		or "ten squares, Blizzard's bar still up"
	if not driven then
		line = line .. "; no state driver, so it follows your pet out of combat only"
	end
	if pending then
		line = line .. "; the rest follows when combat drops"
	end
	return line
end

-- The bar and its squares, for scripts/harness.lua. Read only, like Bars.All.
function Pet.Frame()
	return bar
end

function Pet.Squares()
	return squares
end

-- A rescale moves the grid under the bar, and on a client with no
-- SetIgnoreParentScale the layout has to be run again. Refused in lockdown for
-- Buttons/Bars.lua's reason.
local function Rescaled()
	if bar and not InCombatLockdown() then
		Arrange()
	end
end
UI.OnRescale(Rescaled)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("UNIT_PET")
events:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_LOGIN" then
		Pet.Apply()
		-- On the frame that is never hidden, and armed once: UI.Ticker refuses a
		-- second tick under one name, and the harness logs in again.
		if not ns.UI.Ticking("pet") then
			ns.UI.Ticker(ns.UI.Forever, UPDATE_INTERVAL, "pet", Pet.Tick)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pending then
			Pet.Apply()
		end
	elseif event == "UPDATE_BINDINGS" then
		Pet.Bind()
	elseif unit == "player" and live and not driven and not InCombatLockdown() then
		bar:SetShown(UnitExists("pet") and true or false)
	end
end)
