local ADDON, ns = ...

local Plates = {}
ns.Plates = Plates

--------------------------------------------------------------------------
-- Where the client puts a nameplate, how far out, and what takes the click
--
-- Bars piling on top of each other when two mobs stand together is not a
-- drawing bug and no amount of care in the widget fixes it. The client decides
-- where a plate goes, and it decides using three things this addon can reach
-- and one it cannot.
--
-- The one it cannot is the world. Plates follow mobs, and mobs stand where they
-- stand.
--
-- The three it can:
--
--   nameplateMotion   0 lets plates overlap freely, 1 makes the driver push
--                     them apart. On 0 there is no avoidance to tune and
--                     nameplateOverlapV below changes nothing, which is why
--                     this is the first thing the part takes.
--   the plate's size  the driver spaces plates by how big it thinks a plate is,
--                     and it thinks a plate is Blizzard's nameplate. Ours is
--                     twice the height of that, and taller again while a mob
--                     is casting, so two plates the driver has cleanly
--                     separated are two bars that are not. The figure sent is
--                     the casting height: spacing for the taller of two
--                     states is right in both and for the shorter, neither.
--   nameplateMaxDistance
--                     how many yards out the client bothers to put a plate up.
--                     Nothing this addon draws can appear before that does: a
--                     bar is a child of a plate, so the range the bars work at
--                     is this CVar's and nothing else's.
--
-- SetNamePlateSize tells it the real figure. Where that call is missing,
-- nameplateOverlapV multiplies the height the driver uses instead, which gets
-- the spacing right and leaves the click target where it was.
--
-- The plate's size is applied whenever the bars are drawn on plates, and not
-- only when `bars stack` is on, because the driver spaces plates by it whether
-- or not motion is on. The figure sent is the one UnitFrames/EnemyBars.lua
-- measures: the smallest box centred where the plate is that holds the whole
-- bar. `bars stack` keeps the two CVars.
--
-- The size is not the click. The client hit-tests a plate against its hit
-- test points, which Blizzard_NamePlateUnitFrame.lua's ApplyFrameOptions
-- anchors to the plate's health bar and name on every SetUnit. Replace hides
-- both, so the click had nothing under it; see Plates.Aim.
--
-- All four are the player's, borrowed, and so is the friendly player plate the
-- bars need to reach your own side. Turning a setting off puts back what
-- was there, the same way Targeting/Aim.lua hands its own CVars back.
--------------------------------------------------------------------------

local STACKING = "1"
local FLAT = "0"

-- What `bars distance` may ask for. The floor is the client's own default on
-- these two clients and the top is past what either accepts, deliberately: the
-- real ceiling is asked of the client rather than guessed here, by Ceiling
-- below, and DISTANCE_HIGH is only the figure the probe asks with.
--
-- Asking matters because on the Anniversary client the ceiling is 41 and 41 is
-- also the default, so a setting that let the player walk up to 60 was a
-- setting that did nothing from its shipped value onwards: SetCVar clamps in
-- silence, the number in the panel climbed, and the bars stayed where they
-- were. A setting that cannot move must not offer to.
local DISTANCE_LOW, DISTANCE_HIGH = 20, 60

local footprintWidth, footprintHeight -- what a bar actually occupies, in UIParent units
local naturalWidth, naturalHeight     -- what a plate measured before we touched it
local sizeApplied, overlapApplied, distanceApplied
local ceiling -- the highest range this client will hold, asked of it once
local pending
local warned

local function Read(cvar)
	if type(GetCVar) ~= "function" then
		return nil
	end
	local ok, value = pcall(GetCVar, cvar)
	return ok and value or nil
end

-- pcalled for the reason SoftTarget pcalls: a CVar the client marks protected
-- refuses in combat, and a refusal is a deferral rather than an error on screen.
local function Write(cvar, value)
	if type(SetCVar) ~= "function" then
		return false
	end
	return (pcall(SetCVar, cvar, value))
end

-- Taken the first time the addon touches a CVar and never again, so turning the
-- setting off puts back what was actually there rather than a guess. Empty is
-- the sentinel for "not remembered yet"; these CVars only ever answer a number
-- as a string. Account scoped, both of them, so the memory is too.
local function Remember(key, cvar)
	if not ns.db or ns.db[key] ~= "" then
		return
	end
	ns.db[key] = Read(cvar) or ""
end

--------------------------------------------------------------------------

-- Measured off the first plate the client puts up, before anything here has
-- written to it. Not saved: a resolution change or another addon moves it, and
-- a remembered figure from last session would be spacing this one.
function Plates.Measure(plate)
	if naturalHeight or not plate then
		return
	end
	local width = ns.Measure(plate, "GetWidth")
	local height = ns.Measure(plate, "GetHeight")
	if width and height and width > 0 and height > 0 then
		naturalWidth, naturalHeight = width, height
		Plates.Apply()
	end
end

-- What one bar occupies, in UIParent's units, handed over by whoever draws it.
-- Comes in as pixels off the grid, so the caller converts; this file does no
-- scale arithmetic of its own.
function Plates.SetFootprint(width, height)
	if footprintWidth == width and footprintHeight == height then
		return false
	end
	footprintWidth, footprintHeight = width, height
	Plates.Apply()
	return true
end

-- The call that tells the client how big a plate is. Both clients this addon
-- ships for name it SetNamePlateSize, and it is the one Blizzard's own driver
-- makes in UpdateNamePlateSize. This file used to ask only for
-- SetNamePlateEnemySize, the retail name, which neither client has, so the
-- size was never sent. The retail name stays as the fallback.
local function SizeCall()
	if not C_NamePlate then
		return nil
	end
	return C_NamePlate.SetNamePlateSize or C_NamePlate.SetNamePlateEnemySize
end

-- Returns whether there is nothing left owing, not whether it wrote. A client
-- with no such call and a plate nobody has measured yet are both settled: the
-- first will never be able to, and the second is retried by Measure and
-- SetFootprint rather than by the combat flush. Reporting either as unfinished
-- leaves pending set for the session and re-runs the whole apply on every
-- combat drop for nothing.

local function ApplySize()
	local call = SizeCall()
	if not call then
		return true
	end
	local width = footprintWidth or naturalWidth
	local height = footprintHeight or naturalHeight
	if not width or not height then
		return true
	end
	local ok = pcall(call, width, height)
	if ok then
		sizeApplied = true
	end
	return ok
end

local function RestoreSize()
	local call = SizeCall()
	if not sizeApplied or not call then
		return true
	end
	if not naturalWidth or not naturalHeight then
		return true
	end
	local ok = pcall(call, naturalWidth, naturalHeight)
	if ok then
		sizeApplied = false
	end
	return ok
end

-- The driver sends its own size on every display change and on every
-- nameplate option CVar, and the last write wins. Without this a resized
-- window put Blizzard's small box back under every bar until the next reload.
--
-- A post hook rather than the driver's SetBaseNamePlateSize, because that one
-- runs the driver's whole options pass from addon code and taints every plate
-- it touches. Only while a size of ours is in force: with the bars off the
-- driver's figure is the right one.
--
-- Named rather than written into the hook, because Plates.Apply is on a tick
-- path and a closure built there is an allocation check.sh refuses, early
-- return or not.

--------------------------------------------------------------------------
-- Where a click on a plate lands
--
-- A plate takes no mouse. The client tests a click against the plate's hit
-- test points, and Blizzard's ApplyFrameOptions sets them on every SetUnit: on
-- the health bar, or from the name down to the health bar. `replace` hides
-- both, and a click over a hidden region targeted nothing. The plate's mouse
-- and SetNamePlateSize were each blamed for it and neither moved the click.
--
-- So the points go on the bar. FrameAPINamePlateDocumentation.lua blocks the
-- write for addon code in combat "except on the tick a unit is first
-- assigned". EnemyBars' Attach runs on NAME_PLATE_UNIT_ADDED after the
-- driver's own handler has set the unit, which is that tick, in a pull or out
-- of one. What Blizzard set is kept and put back when the bar leaves.
--
-- The driver writes its own points on every plate again in
-- UpdateNamePlateOptions, so that is hooked. A write refused there is owed and
-- Plates.Flush pays it when combat drops.
--------------------------------------------------------------------------

local aimTop, aimBottom = {}, {} -- plate -> the regions its click runs corner to corner
local prior = {}                 -- plate -> Blizzard's anchors, as GetHitTestPoints gave them
local owed = {}                  -- plate -> true while a refused write is outstanding

-- Reused, because Attach is on the path every plate arrives on. The client
-- copies what it is handed, so relativeTo is cleared after to hold no bar.
local TOP = { point = "TOPLEFT", relativePoint = "TOPLEFT", offsetX = 0, offsetY = 0 }
local BOTTOM = { point = "BOTTOMRIGHT", relativePoint = "BOTTOMRIGHT", offsetX = 0, offsetY = 0 }
local ANCHORS = { TOP, BOTTOM }

local function WriteAim(plate)
	if not plate:CanChangeHitTestPoints() then
		owed[plate] = true
		return
	end
	TOP.relativeTo, BOTTOM.relativeTo = aimTop[plate], aimBottom[plate]
	plate:SetHitTestPoints(ANCHORS)
	TOP.relativeTo, BOTTOM.relativeTo = nil, nil
	owed[plate] = nil
end

-- The click on a plate, from the top left of one region to the bottom right of
-- another. A client with no hit test points has nothing to aim.
function Plates.Aim(plate, top, bottom)
	if type(plate.SetHitTestPoints) ~= "function" then
		return
	end
	if not aimTop[plate] then
		prior[plate] = plate:GetHitTestPoints()
	end
	aimTop[plate], aimBottom[plate] = top, bottom
	WriteAim(plate)
end

-- Blizzard's points back. Refused in combat, the plate keeps ours until its
-- next SetUnit writes Blizzard's again. Nothing is owed for it, because a
-- restore paid later could land on a plate the client has since handed to
-- another unit, anchored to a UnitFrame that plate no longer has.
function Plates.Unaim(plate)
	if not aimTop[plate] then
		return
	end
	if prior[plate] and plate:CanChangeHitTestPoints() then
		plate:SetHitTestPoints(prior[plate])
	end
	aimTop[plate], aimBottom[plate], prior[plate], owed[plate] = nil, nil, nil, nil
end

-- Post hook on the driver's options pass, which has just written Blizzard's
-- points on every plate. Those are the ones to hand back later.
local function Reaim()
	for plate in pairs(aimTop) do
		prior[plate] = plate:GetHitTestPoints()
		WriteAim(plate)
	end
end

local hooked
local function Resized()
	if sizeApplied and not ApplySize() then
		pending = true -- refused in combat, and PLAYER_REGEN_ENABLED flushes it
	end
end

local function HookDriver()
	if hooked or type(hooksecurefunc) ~= "function" then
		return
	end
	local driver = _G.NamePlateDriverFrame
	if type(driver) ~= "table" or type(driver.UpdateNamePlateSize) ~= "function" then
		return
	end
	hooked = true
	hooksecurefunc(driver, "UpdateNamePlateSize", Resized)
	if type(driver.UpdateNamePlateOptions) == "function" then
		hooksecurefunc(driver, "UpdateNamePlateOptions", Reaim)
	end
end

-- Only on the fallback path. Where the size call took, the driver already knows
-- how tall a plate is and multiplying that again would space plates by twice
-- the bar; where it did not, this is the whole of the fix.
--
-- cold: ApplyOverlap writes the plate overlap CVar, on a settings change and on the login that finds the size call did not take
local function ApplyOverlap()
	if sizeApplied or not naturalHeight or not footprintHeight then
		return true
	end
	local wanted = footprintHeight / naturalHeight
	if wanted <= 1 then
		return true
	end
	Remember("platesOverlapPrior", "nameplateOverlapV")
	overlapApplied = true
	return Write("nameplateOverlapV", ("%.2f"):format(wanted))
end

local function RestoreDistance()
	if not distanceApplied then
		return true
	end
	local prior = ns.db and ns.db.platesDistancePrior
	if prior == nil or prior == "" then
		distanceApplied = false
		return true
	end
	if Write("nameplateMaxDistance", prior) then
		distanceApplied = false
		return true
	end
	return false
end

-- The highest figure the client will hold, found by asking it for more than it
-- has and reading back what stuck. The CVar is put back the way it was found,
-- so this is safe to call from anywhere and costs two writes once a session.
--
-- Asked rather than written down here because the two clients this addon runs
-- on do not answer the same: the Anniversary client stops at 41 and a client
-- that stops somewhere else gets its own answer without this file learning
-- which client it is on. A refused write teaches nothing, so nothing is cached
-- and the next caller asks again.
local function Ceiling()
	if ceiling then
		return ceiling
	end
	local held = Read("nameplateMaxDistance")
	if held == nil or not Write("nameplateMaxDistance", tostring(DISTANCE_HIGH)) then
		return nil
	end
	ceiling = tonumber(Read("nameplateMaxDistance")) or DISTANCE_HIGH
	Write("nameplateMaxDistance", held)
	return ceiling
end

-- How far out the client puts a plate up, which is how far out a bar can be
-- seen. Written as a whole number of yards; the client stores it as a string.
-- A setting above the ceiling is pulled down to it and saved there, so the
-- panel shows the figure the client is actually holding rather than a number
-- the player raised against a wall.
local function ApplyDistance()
	local wanted = ns.db.barsDistance or 0
	if wanted <= 0 then
		return RestoreDistance()
	end
	Remember("platesDistancePrior", "nameplateMaxDistance")
	local cap = Ceiling()
	if cap and wanted > cap then
		wanted = cap
		ns.db.barsDistance = cap
	end
	distanceApplied = true
	return Write("nameplateMaxDistance", tostring(wanted))
end

-- What the client actually holds, as a number, or nil where it will not say.
-- The setting is what was asked for; this is what was given.
function Plates.Distance()
	return tonumber(Read("nameplateMaxDistance"))
end

-- What the stepper and the command may offer. The top is the client's own where
-- it has said, so the "+" stops at the last figure that changes anything.
function Plates.DistanceRange()
	return DISTANCE_LOW, Ceiling() or DISTANCE_HIGH
end

-- The friendly player plate, which is a CVar of its own on this client and off
-- until somebody turns it on. A bar is a child of a plate, so a player of your
-- own side had no bar because the client had put nothing up to hang one on.
-- Borrowed while the bars are on plates, the way the range is, and handed back
-- when they go off or go to the list: a list has no plate to put a bar on, and
-- leaving the CVar up would put Blizzard's friendly plates on a screen that
-- never had them.
--
-- Only the players. Friendly npcs are nameplateShowFriendlyNpcs, a vendor or a
-- guard gets no bar, and a plate with no bar over it is Blizzard's art.
local FRIENDS = "nameplateShowFriendlyPlayers"
local friendsApplied

-- A client that does not know the CVar answers nil and has nothing to borrow.
-- Settled rather than refused, for the reason ApplySize is: an answer of
-- "not done" would re-run the whole apply on every combat drop for nothing.
local function ApplyFriends()
	if Read(FRIENDS) == nil then
		return true
	end
	Remember("platesFriendsPrior", FRIENDS)
	friendsApplied = true
	return Write(FRIENDS, "1")
end

local function RestoreFriends()
	if not friendsApplied then
		return true
	end
	local prior = ns.db and ns.db.platesFriendsPrior
	if prior == nil or prior == "" then
		friendsApplied = false
		return true
	end
	if Write(FRIENDS, prior) then
		friendsApplied = false
		return true
	end
	return false
end

local function RestoreMotion()
	local prior = ns.db and ns.db.platesMotionPrior
	if prior == nil or prior == "" then
		return true
	end
	return Write("nameplateMotion", prior)
end

local function RestoreOverlap()
	if not overlapApplied then
		return true
	end
	local prior = ns.db.platesOverlapPrior
	if prior == nil or prior == "" then
		overlapApplied = false
		return true
	end
	if Write("nameplateOverlapV", prior) then
		overlapApplied = false
		return true
	end
	return false
end

--------------------------------------------------------------------------
-- Public
--------------------------------------------------------------------------

-- Put the client where the setting says it should be. Every write is allowed to
-- refuse, and a refusal sets pending rather than saying anything: combat is the
-- normal reason and PLAYER_REGEN_ENABLED runs the whole thing again.
function Plates.Apply()
	if not ns.db then
		return
	end

	local done = true

	-- The range and the plate size, which belong to the bars being drawn at
	-- all rather than to whether motion is on.
	if ns.db.bars then
		HookDriver()
		done = ApplyDistance() and done
		done = ApplySize() and done
	else
		done = RestoreDistance() and done
		done = RestoreSize() and done
	end

	-- The friendly player plate, which belongs to the bars being on plates
	-- rather than to the bars being on at all. See FRIENDS.
	if ns.db.bars and ns.EnemyBars.Mode() == "plates" then
		done = ApplyFriends() and done
	else
		done = RestoreFriends() and done
	end

	-- The spacing, which is what `bars stack` is.
	if ns.db.barsStack and ns.db.bars then
		Remember("platesMotionPrior", "nameplateMotion")
		done = Write("nameplateMotion", STACKING) and done
		done = ApplyOverlap() and done
	else
		done = RestoreOverlap() and done
		done = RestoreMotion() and done
	end

	pending = not done
end

-- Hand all four back. Called when the bars go off, and at logout by nothing at
-- all: these are the player's CVars and a client that crashes leaves them where
-- we put them, which is why the prior is saved rather than held in a local.
function Plates.Restore()
	local done = RestoreOverlap()
	done = RestoreSize() and done
	done = RestoreDistance() and done
	done = RestoreMotion() and done
	done = RestoreFriends() and done
	return done
end

function Plates.Flush()
	for plate in pairs(owed) do
		WriteAim(plate)
	end
	if pending then
		Plates.Apply()
	end
end

-- Whether the client is actually stacking, which is not the same question as
-- whether the setting is on: the CVar can refuse, and it can be turned off in
-- Blizzard's own interface options behind our back.
function Plates.Stacking()
	return Read("nameplateMotion") == STACKING
end

-- What the client is holding for the range, said as a range and not as the
-- setting: SetCVar clamps in silence, so a player who asked for 60 on a client
-- that stops at 41 has to be told 41 rather than shown their own number back.
function Plates.DescribeDistance()
	local held = Plates.Distance()
	if not held then
		return "this client will not say how far out it puts a nameplate"
	end
	local wanted = ns.db.barsDistance or 0
	if wanted <= 0 then
		return ("plates at %d yards, the client's own"):format(held)
	end
	if math.abs(held - wanted) < 0.5 then
		if ceiling and math.abs(held - ceiling) < 0.5 then
			return ("plates out to %d yards, as far as this client goes"):format(held)
		end
		return ("plates out to %d yards"):format(held)
	end
	return ("asked for %d yards and the client stopped at %d, which is its ceiling")
		:format(wanted, held)
end

function Plates.Describe()
	if not ns.db.barsStack then
		return "stacking is the client's own, untouched"
	end
	if not Plates.Stacking() then
		return "asked the client to stack plates and it is still on " .. FLAT
			.. ", so bars can still overlap"
	end
	if sizeApplied then
		return ("stacking, plates sized to the bar at %d by %d"):format(
			footprintWidth or 0, footprintHeight or 0)
	end
	if overlapApplied then
		return "stacking, spaced by nameplateOverlapV because this client has no SetNamePlateSize"
	end
	return "stacking, and nothing has measured a plate yet"
end

-- Said once, because a player who has stacking off in Blizzard's options and
-- this setting on should be told which one is winning rather than left to
-- wonder why the bars still pile up.
function Plates.Warn()
	if warned or not ns.db.barsStack or not ns.db.bars or Plates.Stacking() then
		return
	end
	warned = true
	ns.Print("this client refused to stack nameplates, so bars will still overlap"
		.. " when mobs stand together. Nameplate motion is a Blizzard interface setting too.")
end
