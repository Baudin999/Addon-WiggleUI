local ADDON, ns = ...

local ThreatMeter = {}
ns.MeterThreat = ThreatMeter

--------------------------------------------------------------------------
-- Threat on what you are looking at
--
-- The client already does the hard half. UnitDetailedThreatSituation's third
-- return is threat scaled against the amount needed to take the mob off
-- whoever is holding it: 100 means this player pulls, and the client has
-- already folded in the melee and ranged thresholds, the tank's own total and
-- every talent that moves either. Nothing here recomputes any of that. It
-- samples that one number per member and per pet, and does two things the
-- client will not.
--
-- It sorts, so the pane is a list rather than five separate questions.
--
-- And it differentiates. A percentage tells you where someone is; the rate of
-- change tells you where they are going, and where they are going is the whole
-- point of watching threat at all. 82% and falling is a rogue who stopped;
-- 82% and climbing four points a second is a rogue who takes the mob in four
-- and a half seconds, and you would like to know that now rather than then.
--
-- The rate is not taken off the percentage. The percentage is a ratio with the
-- tank's total underneath it, and that total steps up every swing, so a member
-- gaining steadily read as falling for half a second after each of the tank's
-- blows. The projection was only drawn while the rate was positive, and it
-- flickered off for most of a fight. The client also hands out the raw value,
-- and the threshold a member has to reach is that value over the percentage.
-- Both of those only climb, so each is measured across the last three seconds
-- on its own and the closing speed is the difference between them.
--
-- What it is about is the mob the player is aiming at, which is not the same
-- question as "what is targeted". With action targeting on, the client picks
-- the enemy in front of the camera and answers for it under `softenemy`, and
-- unless SoftTargetForce is honoured nothing is selected at all. Asking for
-- "target" is how this pane spent whole fights saying "no target" to a warrior
-- who was swinging the entire time. It asks Unit.Aimed now, which is the one
-- place in the addon that knows about both.
--
-- On a client with no threat API this whole file answers nothing and the pane
-- says so. Vanilla computes no threat at all, which is why every Classic
-- threat meter is a combat log simulation with a table of every spell's
-- coefficient in it. That is a different addon, and a wrong number here is
-- worse than an honest blank.
--------------------------------------------------------------------------

-- How often a mark is laid and how many are kept. Half a second is two ticks
-- of the window's own clock, which is long enough for a swing to land. Six of
-- them is three seconds, which is long enough for the tank's blows to average
-- out and short enough to see a taunt.
local SAMPLE = 0.5
local MARKS = 6

-- How far the threshold may fall before it counts as a new fight. The client
-- may round the percentage the threshold is read back through, which wobbles
-- it by a point either way. Stepping into melee range drops it by an eighth,
-- and a new tank by far more.
local SETTLE = 0.95

-- Past this, a projection is noise. Sixty seconds of "they overtake you
-- eventually" is not information, and every fight that lasts that long has had
-- a dozen things happen to threat in the meantime.
local HORIZON = 60

local slots = {}   -- guid -> slot, kept for as long as the client runs
local ranked = {}  -- the slots with threat on this target, sorted

local target        -- the GUID the samples below are about
local tanking       -- the slot holding the mob, or nil

--------------------------------------------------------------------------

local function Slot(guid)
	local slot = slots[guid]
	if not slot then
		slot = { guid = guid, pct = 0, eta = nil, tanking = false, live = false,
			count = 0, values = {}, limits = {}, times = {} }
		slots[guid] = slot
	end
	return slot
end

-- Everything sampled so far is about a different mob. Not cleared to zero and
-- kept: a rate carried across a target switch is a rate measured between two
-- unrelated numbers, and it would draw a projection out of nothing.
local function Forget()
	for _, slot in pairs(slots) do
		slot.pct, slot.eta, slot.count = 0, nil, 0
		slot.tanking, slot.live = false, false
	end
	tanking = nil
end

function ThreatMeter.Ready()
	return ns.HasThreat()
end

-- The mob there is something to measure against, or nil. A friendly target, a
-- corpse and nothing at all are the same answer, and the pane draws the reason
-- rather than an empty list.
function ThreatMeter.Watching()
	return ns.Unit.Aimed()
end

-- The mob the samples are about, and everything behind forgotten when it
-- changes.
--
-- Called on the tick as well as off the target changing, because the camera's
-- soft target moves with no event of its own: the tick is the only thing that
-- sees a player swing round onto the next mob without selecting it. The event
-- is kept because it is the half that is instant, and it goes through the same
-- comparison so that losing a held target to a soft one that is the same mob
-- does not throw the window away mid fight.
local function Aim()
	local unit = ThreatMeter.Watching()
	local guid = unit and UnitGUID(unit)
	if guid ~= target then
		target = guid
		Forget()
	end
	return unit
end

--------------------------------------------------------------------------

-- One member, one sample. Split out of Update so the loop below is a loop and
-- so check.sh has a name to hold the arithmetic to.
-- Lay a mark, dropping the oldest once the window is full. Shifted rather than
-- kept as a ring: fifteen numbers moved twice a second per member is nothing,
-- and the oldest mark is then always the first.
local function Mark(slot, value, limit, now)
	local values, limits, times = slot.values, slot.limits, slot.times
	local count = slot.count
	if count == MARKS then
		for index = 1, MARKS - 1 do
			values[index], limits[index], times[index] =
				values[index + 1], limits[index + 1], times[index + 1]
		end
	else
		count = count + 1
		slot.count = count
	end
	values[count], limits[count], times[count] = value, limit, now
end

local function Sample(unit, mob, now)
	local guid = UnitGUID(unit)
	if not guid then
		return
	end

	local isTanking, status, pct, _, value = ns.Threat(unit, mob)
	local slot = Slot(guid)

	if status == nil or pct == nil then
		slot.live, slot.eta, slot.count = false, nil, 0
		return
	end

	slot.live = true
	slot.tanking = isTanking and true or false
	slot.pct = pct

	if slot.tanking then
		tanking = slot
	end

	-- What this member has to reach. The client scales against it and hands out
	-- both ends of the division, so it is read back rather than rebuilt from the
	-- melee and ranged multipliers. A member on zero has no threshold to read
	-- and nothing to project.
	local limit = (value and pct > 0) and (value * 100 / pct) or nil
	if not limit then
		slot.eta, slot.count = nil, 0
		return
	end

	-- A drop is a fade, a threat wipe, a new tank or a step into melee range,
	-- and each of those makes the marks behind it about a different fight.
	local count = slot.count
	if count > 0 and (value < slot.values[count] or limit < slot.limits[count] * SETTLE) then
		count = 0
		slot.count = 0
	end
	if count == 0 or now - slot.times[count] >= SAMPLE then
		Mark(slot, value, limit, now)
	end

	-- Whoever is holding the mob is not on their way to taking it off
	-- themselves, and a first mark has nothing behind it to measure against.
	local span = now - slot.times[1]
	if slot.tanking or value >= limit or span < SAMPLE then
		slot.eta = nil
		return
	end
	local closing = ((value - slot.values[1]) - (limit - slot.limits[1])) / span
	if closing <= 0 then
		slot.eta = nil
		return
	end
	local seconds = (limit - value) / closing
	slot.eta = (seconds <= HORIZON) and seconds or nil
end

function ThreatMeter.Update()
	if not ThreatMeter.Ready() then
		return
	end

	local mob = Aim()
	if not mob then
		return
	end

	local now = GetTime()
	tanking = nil
	local units = ns.Unit.Roster.Fighters()
	for index = 1, #units do
		Sample(units[index], mob, now)
	end
end

--------------------------------------------------------------------------
-- Reading it back
--------------------------------------------------------------------------

local function Higher(a, b)
	if a.pct == b.pct then
		return a.guid < b.guid
	end
	return a.pct > b.pct
end

-- The members with threat on this mob, highest first. Same contract as
-- Meter.Rank: an array this file already owns, filled and sorted in place.
function ThreatMeter.Rank()
	local count = 0
	local units = ns.Unit.Roster.Fighters()
	for index = 1, #units do
		local slot = slots[UnitGUID(units[index]) or ""]
		if slot and slot.live then
			count = count + 1
			ranked[count] = slot
		end
	end
	for index = #ranked, count + 1, -1 do
		ranked[index] = nil
	end
	table.sort(ranked, Higher)
	return ranked
end

function ThreatMeter.Tanking()
	return tanking
end

-- Whoever takes the mob next and how long that is, or nil where nobody is
-- converging. This is the line the pane header carries, because it is the one
-- thing on the pane you would want shouted at you.
function ThreatMeter.Soonest()
	local soonest, when = nil, nil
	local rows = ThreatMeter.Rank()
	for index = 1, #rows do
		local slot = rows[index]
		if slot.eta and (when == nil or slot.eta < when) then
			soonest, when = slot, slot.eta
		end
	end
	return soonest, when
end

--------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", Aim)
