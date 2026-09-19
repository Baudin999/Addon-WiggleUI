local ADDON, ns = ...

local Paint = {}
ns.FramePaint = Paint

--------------------------------------------------------------------------
-- The tick
--
-- One pass over one block: the colours off the unit, the two bars, the four
-- numbers, the incoming heal, the portrait and the badges.
--
-- Run when UnitFrames/Skin.lua says the unit moved, and once a second behind
-- that whatever the client has said. The names of the events that carry health
-- and power are checked against Blizzard's own frames and the note over
-- Skin.lua's WATCHED is what they came back as.
--
-- Everything here takes a unit token and nil guards, because anything a ticker
-- does has to be incapable of raising. Every write is guarded on the value
-- already on the frame, because a SetText or a SetColorTexture costs a measure
-- and a relayout whether or not the value changed, and a player at full health
-- is the common case.
--
-- Nothing here decides a rectangle. UnitFrames/Block.lua worked all of those
-- out at layout time and left the answers on the entry, which is why this file
-- reads entry.railPixels and entry.pixel rather than measuring anything.
--
-- Nothing here is written back either. The file used to spend a third of
-- itself re-applying a flat texture to Blizzard's bars and a crop to Blizzard's
-- portrait, because the client's own code put both back whenever it swapped
-- the art underneath. The bars and the portrait are ours now and nothing else
-- writes on them, so a value written once stays written.
--
-- All of the colour is ns.Unit.Color's.
--------------------------------------------------------------------------

local Unit = ns.Unit
local Color = Unit.Color
local Level = Unit.Level
local Gauge = ns.UI.Gauge
local IDLE = Color.reaction.idle

-- The modern bar look's edge: the palette's chrome, the dark its windows are
-- framed in, one colour round every unit rather than the flat look's dimmed
-- copy of the fill. The accent was tried first and drew a bright line round
-- every unit that fought each fill. UI.Color's own table, which the palette is
-- painted into in place, so this reference follows the palette.
local RIM = ns.UI.Color.chrome

-- What the level tag reads as on something that is not a kill. The XP scale is
-- an answer to "what is this worth", and your own frame and a friendly target
-- are not asking it: painting them even yellow would be a number claiming to
-- be a reward.
local PLAIN_LEVEL = Color.text.value

local UnitCanAttack = UnitCanAttack

-- The five client calls the badges are read with, taken at load. Every one
-- answers on both clients this addon runs on, and a client that turns out
-- not to carry one draws no badge of that kind rather than raising on a tick.
local SetPortraitTexture = _G.SetPortraitTexture
local SetRaidTargetIconTexture = _G.SetRaidTargetIconTexture
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local GetPetHappiness = _G.GetPetHappiness
local HasPetUI = _G.HasPetUI

-- The two cells of Interface\CharacterFrame\UI-StateIcon: resting on the left
-- and fighting on the right, each the top half of its column. Blizzard crops
-- them a few texels short of the half; the whole half is a square and lands on
-- a texel boundary, which is what keeps the sampler off the seam.
local STATE = {
	rest = { 0, 0.5, 0, 0.5 },
	combat = { 0.5, 1, 0, 0.5 },
}

-- The three cells of Interface\\PetPaperDollFrame\\UI-PetHappiness, keyed by what
-- GetPetHappiness answers: 1 unhappy, 2 content, 3 happy. The sheet is 128 by
-- 64 and a cell is 24 by 23, so these are PetFrame.lua's own crops written as
-- the texels they land on.
local MOOD_BOTTOM = 23 / 64
local MOOD = {
	{ 48 / 128, 72 / 128 },
	{ 24 / 128, 48 / 128 },
	{ 0, 24 / 128 },
}

-- The PvP flag per faction, built once rather than concatenated on the tick.
-- Keyed by what UnitFactionGroup answers, plus the free for all flag, which is
-- not a faction and is asked about first the way PlayerFrame.lua asks.
local PVP = {
	Alliance = "Interface\\TargetingFrame\\UI-PVP-Alliance",
	Horde = "Interface\\TargetingFrame\\UI-PVP-Horde",
	FFA = "Interface\\TargetingFrame\\UI-PVP-FFA",
}

-- The slice of the gauge an incoming heal is about to fill, from where the
-- fill stops to where it is headed. Block pinned it to the fill's inner edge
-- once; what moves here is its width, in whole pixels of the rail, guarded on
-- the span last drawn. This runs five times a second on three frames, and on
-- all three the common case is that nobody is healing anybody, which should
-- cost a comparison and nothing else.
local function HealSlice(entry, span)
	if entry.healSpan == span then
		return
	end
	entry.healSpan = span
	local slice = entry.healSlice
	if span > 0 then
		slice:SetWidth(span * entry.pixel)
		slice:Show()
	else
		slice:Hide()
	end
end

-- One bar's range and value, written only when either moved. A unit with no
-- power at all gets an empty bar over its track, which is what the idle colour
-- on the track is for. The two field names arrive as constants rather than
-- being built from a prefix, because this runs on the tick and a string built
-- there is garbage on the tick.
local function Fill(bar, entry, drawnValue, drawnMax, value, max)
	if entry[drawnMax] ~= max then
		entry[drawnMax] = max
		bar:SetMinMaxValues(0, max > 0 and max or 1)
	end
	if entry[drawnValue] ~= value then
		entry[drawnValue] = value
		bar:SetValue(value)
	end
end

-- The level tag, and what the kill is worth.
--
-- Guarded on the string, which ns.Unit.Level hands over already built rather
-- than building one per tick to compare, and on the colour table's identity the
-- way every other colour on this frame is.
--
-- Grey here is the plate's grey: the kill pays nothing, because the mob is too
-- far below you or because somebody else tagged it. Only on something you can
-- attack. Your own frame and a friendly target are not asking what a kill is
-- worth, and an even yellow on those two is a reward being claimed where there
-- is none.
local function PaintLevel(entry, unit)
	local tag, xp = Level.Of(unit)
	if not UnitCanAttack("player", unit) then
		xp = PLAIN_LEVEL
	end
	if entry.levelTag ~= tag then
		entry.levelTag = tag
		entry.levelText:SetText(tag)
	end
	if entry.levelColor ~= xp then
		entry.levelColor = xp
		entry.levelText:SetTextColor(xp[1], xp[2], xp[3])
	end
end

-- The portrait, asked for again when the unit behind the token is a different
-- creature or when the client said the render moved. UNIT_PORTRAIT_UPDATE is
-- one of the events Skin.lua marks a block on, and it sets the dirty bit here
-- because a new render for the same GUID is not a change this comparison can
-- see. One GUID read per pass otherwise, which is the cost of being told.
local function PaintPortrait(entry, unit)
	local guid = UnitGUID(unit)
	if entry.portraitGuid == guid and not entry.portraitDirty then
		return
	end
	entry.portraitGuid, entry.portraitDirty = guid, false
	if SetPortraitTexture then
		SetPortraitTexture(entry.portrait, unit)
	end
end

-- The raid marker on the square's corner, on the frames that carry one.
-- Guarded on the index, and nil is a value here: a marker taken off is a
-- change from a number to nothing.
local function PaintMarker(entry, unit)
	local texture = entry.badges.marker
	if not texture or not GetRaidTargetIndex then
		return
	end
	local index = GetRaidTargetIndex(unit)
	if entry.marker == index then
		return
	end
	entry.marker = index
	if index and SetRaidTargetIconTexture then
		SetRaidTargetIconTexture(texture, index)
		texture:Show()
	else
		texture:Hide()
	end
end

-- Resting or fighting, on your own frame. One or the other, never both, which
-- is Blizzard's own rule for the same corner, and resting wins because you
-- cannot be resting in a fight.
local function PaintState(entry)
	local texture = entry.badges.state
	if not texture then
		return
	end
	local state = nil
	if IsResting() then
		state = "rest"
	elseif UnitAffectingCombat("player") then
		state = "combat"
	end
	if entry.state == state then
		return
	end
	entry.state = state
	if state then
		local crop = STATE[state]
		texture:SetTexCoord(crop[1], crop[2], crop[3], crop[4])
		texture:Show()
	else
		texture:Hide()
	end
end

-- The PvP flag, asked the way PlayerFrame.lua asks: free for all first, then
-- the faction's own flag while the unit is flagged, and nothing otherwise.
-- Guarded on the path, which is a constant per faction, so a unit that stays
-- flagged costs two client calls and a comparison.
local function PaintPvp(entry, unit)
	local texture = entry.badges.pvp
	if not texture then
		return
	end
	local art = nil
	if UnitIsPVPFreeForAll(unit) then
		art = PVP.FFA
	elseif UnitIsPVP(unit) then
		art = PVP[UnitFactionGroup(unit) or ""]
	end
	if entry.pvp == art then
		return
	end
	entry.pvp = art
	if art then
		texture:SetTexture(art)
		texture:Show()
	else
		texture:Hide()
	end
end

-- A hunter pet's face, on the block that carries one. Asked the way
-- PetFrame.lua asks: GetPetHappiness answers nil for a pet that has no
-- happiness, HasPetUI's second answer is whether the pet is a hunter's, and
-- either one saying no is no face. A warlock's demon draws none. All three
-- faces are drawn, the happy one included, because a face that only turns up
-- when something is wrong cannot be told from a badge that failed to draw.
local function PaintMood(entry)
	local texture = entry.badges.mood
	if not texture or not GetPetHappiness or not HasPetUI then
		return
	end
	local mood = GetPetHappiness()
	local _, hunters = HasPetUI()
	-- False rather than nil for no face, so the first pass after Paint.Forget
	-- hides a face the last pet left up instead of finding nil where it left nil.
	local crop = hunters and MOOD[mood or 0] or false
	if entry.mood == crop then
		return
	end
	entry.mood = crop
	if crop then
		texture:SetTexCoord(crop[1], crop[2], 0, MOOD_BOTTOM)
		texture:Show()
	else
		texture:Hide()
	end
end

-- The shots left in your ranged slot, on the block that carries the pill.
--
-- ns.Ammo answers nil for a slot that never runs out, and that is no pill
-- rather than a pill saying nothing. Compared as the number drawn, with -1 for
-- none, so a pass that finds the count where it was costs the client calls and
-- one comparison.
--
-- Under AMMO_LOW the number turns red, and zero is under it: a bow with an
-- empty ammo slot is the reading the pill is for. A hundred arrows is about
-- four minutes of auto shot.
local AMMO_LOW = 100
local AMMO_SHORT, AMMO_PLENTY = Color.text.short, Color.text.value

local function PaintAmmo(entry)
	local pill = entry.ammo
	if not pill then
		return
	end
	local count, icon = ns.Ammo()
	count = count or -1
	-- Guarded apart from the count, because a quiver swapped for another kind
	-- of arrow can leave the number where it was and change only the art.
	if entry.ammoIcon ~= icon then
		entry.ammoIcon = icon
		pill.icon:SetTexture(icon)
	end
	if entry.shownAmmo == count then
		return
	end
	entry.shownAmmo = count
	if count >= 0 then
		pill.text:SetText(tostring(count))
		local tint = count < AMMO_LOW and AMMO_SHORT or AMMO_PLENTY
		if entry.ammoTint ~= tint then
			entry.ammoTint = tint
			pill.text:SetTextColor(tint[1], tint[2], tint[3])
		end
		pill:Show()
	else
		pill:Hide()
	end
end

function Paint.Refresh(entry)
	local unit = entry.spec.unit
	if not entry.styled or not UnitExists(unit) then
		return
	end

	local tint = Color.OfUnit(unit)
	if entry.tint ~= tint then
		entry.tint = tint
		Gauge.Paint(entry.healthBar, nil, tint)
		Gauge.Paint(nil, entry.healthTrack, Color.spent)
		local edge = ns.Theme.Modern() and RIM or Color.Dim(tint, Color.edgeDim)
		ns.Recolor(entry.edges, edge)
		entry.divider:SetColorTexture(edge[1], edge[2], edge[3], 1)
	end

	local shownPower, maxPower, powerType = Unit.Power(unit)
	local power = (maxPower > 0 and Color.power[powerType]) or IDLE
	if entry.power ~= power then
		entry.power = power
		Gauge.Paint(entry.powerBar, entry.powerTrack, power)
	end

	local health, maxHealth, percent = Unit.Health(unit)
	Fill(entry.healthBar, entry, "healthValue", "healthMax", health, maxHealth)
	Fill(entry.powerBar, entry, "powerValue", "powerMax", shownPower, maxPower)

	-- Compared as the integers that get drawn, the same way the enemy bars do
	-- it. A SetText costs a string measure and a relayout whether or not the
	-- text changed, and a player at full health is the common case.
	if entry.shownPercent ~= percent then
		entry.shownPercent = percent
		entry.healthText:SetText(percent >= 0 and (percent .. "%") or "")
	end

	-- Incoming heals, in whole pixels of the rail, measured from where the
	-- fill stops. Clamped to what is missing: a 2,000 heal landing on a warrior
	-- who is down 300 would otherwise run off the end of the gauge, and a slice
	-- that overshoots the bar is saying something untrue about both numbers.
	-- Nil out of ns.IncomingHeals is a client with no prediction at all, and it
	-- takes the same road as a quiet moment, which is to draw nothing.
	local span = 0
	if ns.db.skinHeals and maxHealth > 0 and health > 0 then
		local incoming = ns.IncomingHeals(unit) or 0
		if incoming > 0 then
			local missing = maxHealth - health
			if incoming > missing then
				incoming = missing
			end
			span = math.floor(incoming / maxHealth * entry.railPixels + 0.5)
		end
	end
	HealSlice(entry, span)

	-- -1 rather than 0 for a unit with no power bar at all, so "empty" and
	-- "has none" guard apart. Most of what you fight has none.
	local drawnPower = maxPower > 0 and shownPower or -1
	if entry.shownPower ~= drawnPower then
		entry.shownPower = drawnPower
		entry.powerText:SetText(drawnPower >= 0 and tostring(drawnPower) or "")
	end

	local name = UnitName(unit) or ""
	if entry.shownName ~= name then
		entry.shownName = name
		entry.nameText:SetText(name)
	end

	PaintLevel(entry, unit)
	PaintPortrait(entry, unit)
	PaintMarker(entry, unit)
	PaintState(entry)
	PaintPvp(entry, unit)
	PaintMood(entry)
	PaintAmmo(entry)

	-- The aura rows, which come along on the same pass. UNIT_AURA is one of the
	-- events that mark this block, so a target gaining a debuff is a row
	-- redrawn a fifth of a second later and a target standing still is a row
	-- nothing reads. Everything it does is guarded in there.
	ns.FrameAuras.Update(entry)
end

-- Every cache a pass compares against, forgotten. Called when a block goes up,
-- so the first pass after it writes everything rather than trusting what the
-- widgets carried from before the block came down.
function Paint.Forget(entry)
	entry.tint, entry.power, entry.levelTag, entry.levelColor = nil, nil, nil, nil
	entry.shownPercent, entry.shownPower, entry.shownName = nil, nil, nil
	entry.healthValue, entry.healthMax, entry.powerValue, entry.powerMax = nil, nil, nil, nil
	entry.portraitGuid, entry.portraitDirty = nil, true
	entry.marker, entry.state, entry.pvp, entry.mood = nil, nil, nil, nil
	entry.healSpan = nil
	entry.shownAmmo, entry.ammoTint, entry.ammoIcon = nil, nil, nil
end
