local ADDON, ns = ...

local C = ns.UI.Color
local Unit = ns.Unit
local Color = Unit.Color

--------------------------------------------------------------------------
-- Health and power, on every hover of a unit
--
-- Blizzard's tooltip draws a unit's health as a status bar under its text and
-- never draws power at all. UI/Scan.lua reads the text back and nothing else,
-- so the bar never reached the addon's box: a player, a mob or a party member
-- hovered anywhere said who it was and not how alive it was. These two sources
-- put both back in the body band, which is where the facts about the thing go,
-- above the threat and the quest drops the rest of the addon adds.
--
-- Registered against UI/Tip.lua's unit kind, so the world hover and the
-- skinned unit frames get the same two lines from one place. Meter/Standing.lua
-- is the same shape one band down, and it is why this file knows nothing about
-- hovering.
--
-- **A health max of exactly 100 is a percentage.** A client that will not hand
-- over a unit's real health answers a percentage out of 100 instead, and
-- "46 / 100" would read as a mob with a hundred hit points. That case prints
-- the percent alone.
--
-- **Power is whatever pool the unit has.** A mage has mana, a warrior rage, a
-- rogue energy. A unit with no pool, which is most beasts, gets no line rather
-- than an empty one. Happiness is a hunter pet's mood and not a pool, so it
-- has no label here and draws nothing.
--
-- **Each line sits on a gauge in the unit frame's colours.** Health fills in
-- the class colour for a player and the reaction colour for anything else,
-- which is Color.OfUnit and the same answer the unit frames give; the pool
-- fills in its power colour. The text stays plain and goes on top, because
-- those colours are fills shaped under a ceiling so text reads over them, and
-- the same numbers used as text on a dark box are the unreadable half of that
-- trade.
--------------------------------------------------------------------------

-- What the client answers as a max when the figure is a percentage.
local PERCENT = 100

-- Keyed by the number UnitPowerType returns, for the reason Unit/Color.lua's
-- power table is: the number has never been renamed between clients.
local POOL = {
	[0] = "Mana",
	[1] = "Rage",
	[2] = "Focus",
	[3] = "Energy",
}

-- The figure and the max in one stamp. UI/Fresh.lua reads one value per stamp
-- on a tick, and a string built to carry two would allocate on that tick. No
-- unit on these clients has a max near 2^26, and the product stays inside the
-- 53 bits a double holds exactly.
local WIDE = 2 ^ 26

local function Existing(subject)
	local unit = subject.unit
	if type(unit) ~= "string" or not UnitExists(unit) then
		return nil
	end
	return unit
end

local function Health(subject)
	local unit = Existing(subject)
	if not unit then
		return nil
	end
	local fill = Color.OfUnit(unit)
	if UnitIsDeadOrGhost(unit) then
		return { "Health", "dead", tone = C.quiet, bar = 0, fill = fill }
	end
	local health, max, percent = Unit.Health(unit)
	if max <= 0 then
		return nil
	end
	if max == PERCENT then
		return { "Health", ("%d%%"):format(health), bar = health / max, fill = fill }
	end
	return { "Health", ("%d / %d (%d%%)"):format(health, max, percent), bar = health / max, fill = fill }
end

local function Power(subject)
	local unit = Existing(subject)
	if not unit or UnitIsDeadOrGhost(unit) then
		return nil
	end
	local power, max, pool = Unit.Power(unit)
	local label = POOL[pool]
	if max <= 0 or not label then
		return nil
	end
	return { label, ("%d / %d"):format(power, max), bar = power / max, fill = Color.power[pool] }
end

ns.Tip.Source({
	name = "health",
	kind = "unit",
	band = "body",
	order = 10,
	fill = Health,
	-- Death is in here without a term of its own: a unit that dies drops to
	-- nought, and that is a different stamp from any figure it had alive.
	stamp = function(subject)
		local unit = Existing(subject)
		if not unit then
			return nil
		end
		local health, max = Unit.Health(unit)
		return health * WIDE + max
	end,
})

ns.Tip.Source({
	name = "power",
	kind = "unit",
	band = "body",
	order = 20,
	fill = Power,
	-- The pool is in the stamp as well, because a druid shifting into bear
	-- trades mana for rage and the max alone can land on the same number.
	stamp = function(subject)
		local unit = Existing(subject)
		if not unit then
			return nil
		end
		local power, max, pool = Unit.Power(unit)
		return (power * WIDE + max) * 8 + pool
	end,
})
