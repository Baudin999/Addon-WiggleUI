local ADDON, ns = ...

local Swing = {}
ns.Swing = Swing

--------------------------------------------------------------------------
-- When the next swing lands
--
-- The client will tell you how long a swing takes and will not tell you where
-- in one you are standing. There is no event for a swing starting, no timer to
-- read and nothing on the player that moves with it. What there is is the
-- combat log: every landed swing and every missed one arrives as an event with
-- you as the source, and a swing landing is the same instant the next one
-- starts. So the log is the clock and UnitAttackSpeed is the length of a tick.
--
-- Everything below is about the weapon in your hand, and there are four things
-- to get right about it.
--
-- The timer is blind until you have swung once. A fight opens with the bar
-- empty and fills from the first white hit, which is correct rather than a
-- gap: before that swing there is no swing in progress to draw.
--
-- A swing that is dodged, parried, missed or blocked still lands as far as
-- the timer is concerned, because SWING_MISSED is the server saying the swing
-- happened and did nothing. A timer that only listened for damage would stop
-- dead against a mob you cannot hit.
--
-- Which hand swung is a flag on the event and not a separate subevent. It is
-- the last value of SWING_DAMAGE and the second value of SWING_MISSED, which
-- are different positions for the same fact, so both are read by index and
-- neither is guessed. Reading the wrong slot gives an off hand timer that
-- never runs and a main hand timer that runs twice as fast, which looks like a
-- haste bug rather than like a parser bug.
--
-- Haste moves the length of the tick under a tick already in flight. The
-- server scales what is left of the swing by the ratio of the two speeds
-- rather than restarting it, so Flurry landing at the halfway mark leaves you
-- halfway through a shorter swing, and Retime does the same arithmetic. A
-- timer that ignored this is wrong for a warrior in every fight, because
-- Flurry is up for most of them.
--
-- Two things restart a swing without a white hit in the log, and both of them
-- are common enough that a timer missing either is a bar that lies most of the
-- fight. An on next swing ability eats the white hit and logs as SPELL_DAMAGE
-- under its own name; see Eats below. And swapping the weapon starts a fresh
-- swing of the new weapon's length; see Reweapon.
--------------------------------------------------------------------------

-- Probed rather than named in .luacheckrc, the same way Meter/Spec.lua reaches
-- the talent API. Nothing installed on this machine calls either of these
-- unguarded, so neither is proven the way the README asks a read_globals entry
-- to be proven, and a swing timer that raises twenty times a second is worse
-- than a swing timer that says it cannot read the client.
local UnitAttackSpeed = _G.UnitAttackSpeed
local OffhandHasWeapon = _G.OffhandHasWeapon

Swing.MAIN = "main"
Swing.OFF = "off"

-- Two records, made once at load and written in place forever after. The tick
-- reads them on every frame and a swing timer that built a table per swing
-- would be the shape check.sh's allocation gate exists to refuse.
--
--   at        when this swing started, on the client's own clock
--   duration  how long it is, which is the speed it started at
--   speed     what UnitAttackSpeed says now, which is not always the above
--   running   whether a swing has ever been seen for this hand this fight
--   slot      the inventory slot this hand's weapon sits in
--   weapon    the link that was in that slot last time, so Rearm can tell a
--             weapon swap from a trinket swap
local hands = {
	main = { at = 0, duration = 0, speed = 0, running = false, slot = ns.Gear.MAINHAND },
	off  = { at = 0, duration = 0, speed = 0, running = false, slot = ns.Gear.OFFHAND },
}

--------------------------------------------------------------------------
-- What the client says
--------------------------------------------------------------------------

function Swing.Ready()
	return type(UnitAttackSpeed) == "function"
end

-- The second return is nil on a client with nothing in the off hand and is
-- also nil with a shield there, which is the answer this wants: a shield does
-- not swing. OffhandHasWeapon is asked first where it exists, because it
-- answers the question directly rather than by implication.
function Swing.HasOffhand()
	if type(OffhandHasWeapon) == "function" then
		return OffhandHasWeapon() and true or false
	end
	if not Swing.Ready() then
		return false
	end
	local _, off = UnitAttackSpeed("player")
	return type(off) == "number" and off > 0
end

-- Whether there is anything in the main hand at all.
--
-- This is the gate on drawing the bars, and it is deliberately a weapon rather
-- than a class. A swing timer is worth the same to a rogue and to a hunter who
-- is standing in melee. Unarmed is a real 2.0 second swing and the client
-- reports a speed for it, so asking the speed would draw a bar for a hunter
-- shooting from thirty yards, which is a bar about nothing.
function Swing.HasMainhand()
	return GetInventoryItemLink("player", ns.Gear.MAINHAND) ~= nil
end

local function Speeds()
	if not Swing.Ready() then
		return nil, nil
	end
	local main, off = UnitAttackSpeed("player")
	if type(main) ~= "number" or main <= 0 then
		main = nil
	end
	if type(off) ~= "number" or off <= 0 or not Swing.HasOffhand() then
		off = nil
	end
	return main, off
end

--------------------------------------------------------------------------
-- Reading a hand back
--------------------------------------------------------------------------

function Swing.Speed(which)
	local hand = hands[which]
	return hand and hand.speed or 0
end

function Swing.Armed(which)
	local hand = hands[which]
	return hand ~= nil and hand.running and hand.duration > 0
end

-- Seconds until the swing lands, floored at zero. A swing whose time is up and
-- whose landing has not reached the log yet reads as zero rather than as a
-- negative number, because the bar behind this is drawn full at zero and would
-- be drawn past its own end at anything less.
function Swing.Remaining(which)
	if not Swing.Armed(which) then
		return 0
	end
	local hand = hands[which]
	local left = hand.at + hand.duration - GetTime()
	return left > 0 and left or 0
end

-- How much of the swing is spent, from 0 to 1, which is what the gauge draws.
function Swing.Fraction(which)
	if not Swing.Armed(which) then
		return 0
	end
	local hand = hands[which]
	local spent = (GetTime() - hand.at) / hand.duration
	if spent < 0 then
		return 0
	end
	return spent < 1 and spent or 1
end

--------------------------------------------------------------------------
-- Moving a hand
--------------------------------------------------------------------------

-- A swing landed, so the next one starts now. Public because scripts/harness.lua
-- drives the timer without a combat log to drive it with.
function Swing.Start(which)
	local hand = hands[which]
	if not hand then
		return false
	end
	if hand.speed <= 0 then
		Swing.Retime()
	end
	if hand.speed <= 0 then
		return false
	end
	hand.at, hand.duration, hand.running = GetTime(), hand.speed, true
	return true
end

-- The fight is over, or the hand is empty. The bar goes quiet rather than
-- running on: a swing timer still counting down after the mob is dead is a bar
-- telling you about a swing that is not coming.
function Swing.Stop(which)
	local hand = hands[which]
	if hand then
		hand.running = false
	end
end

-- Haste moved. What is kept is the time left, scaled. A swing half spent at
-- 3.4 seconds that becomes a 2.4 second swing has 1.2 seconds left rather than
-- 1.7, and a timer that kept the elapsed instead would jump backwards every
-- time Flurry landed. Where the speed did not actually move, nothing is
-- written at all, so an aura event for somebody else's buff costs a comparison.
local function Rescale(hand, speed)
	if not speed then
		hand.speed, hand.duration, hand.running = 0, 0, false
		return
	end
	local was = hand.duration
	hand.speed = speed
	if not hand.running or was <= 0 then
		hand.duration = speed
		return
	end
	if was == speed then
		return
	end
	local now = GetTime()
	local left = (hand.at + was - now) * speed / was
	if left <= 0 then
		hand.running, hand.duration = false, speed
		return
	end
	hand.at, hand.duration = now + left - speed, speed
end

-- A weapon moved, which is a different thing from haste moving even though the
-- client sends the same events for both.
--
-- Haste scales what is left of the swing. Equipping a weapon throws it away and
-- starts a fresh one of the new weapon's length, so a swap at the top of a 3.4
-- second swing costs the whole of it. Rescaled instead, the bar would show most
-- of a swing still in flight on a weapon that has not swung once.
--
-- The link in the slot is what says a weapon moved, and not the speed: two
-- swords of one speed are a swap the speed cannot see. Only a hand whose link
-- changed is restarted, and only while it was already swinging, because
-- UNIT_INVENTORY_CHANGED is every trinket, bag and bit of armour as well and a
-- swap out of combat has no swing to throw away. This addon equips weapons
-- itself out of the charge macro, which is where it shows.
local function Reweapon(hand)
	local link = GetInventoryItemLink("player", hand.slot)
	if link == hand.weapon then
		return
	end
	hand.weapon = link
	if hand.running and hand.speed > 0 then
		hand.at, hand.duration = GetTime(), hand.speed
	end
end

-- Everything the client says about the hands comes through here, because the
-- three events that carry it do not divide cleanly: a weapon swap sends the
-- attack speed event as well as the inventory one, and whichever arrives first
-- should be the one that acts. The speed is settled first and the weapon after
-- it, so a restarted swing is the length of the weapon that is in the hand now.
--
-- hot: run from UNIT_AURA, UNIT_ATTACK_SPEED and UNIT_INVENTORY_CHANGED on the
-- player, which in combat arrive faster than the swing bar ticks, and the OnEvent
-- closure that calls it is not a root the walk can name.
function Swing.Retime()
	local main, off = Speeds()
	Rescale(hands.main, main)
	Rescale(hands.off, off)
	Reweapon(hands.main)
	Reweapon(hands.off)
end

--------------------------------------------------------------------------
-- The abilities that eat a swing
--
-- Heroic Strike and Cleave replace the white hit rather than landing beside
-- it, and a completed Slam restarts the swing outright. None of the three
-- appears in the log as SWING_DAMAGE: what arrives is SPELL_DAMAGE under the
-- ability's own name, so a timer reading only white hits freezes for a whole
-- swing every time you press one. On a warrior that is most presses.
--
-- Matched by name rather than by id, because Heroic Strike has ten ranks with
-- ten ids and one name. Class\<yours>.lua names rank one of each and this
-- resolves the names through the client once, the way the upkeep row does.
--
-- A class that named none gets an empty set and every SPELL_DAMAGE line costs
-- one table lookup.
--------------------------------------------------------------------------

local eats

-- How many abilities this character has that eat a swing, which is the count
-- the registry handed over. For scripts/harness.lua, which asserts that one
-- class fact gates exactly one part, the same way it counts the stance list.
function Swing.EatCount()
	local ids = ns.Class.Of("swing")
	return ids and #ids or 0
end

local function Eats(spell)
	if not eats then
		eats = {}
		local ids = ns.Class.Of("swing")
		if ids then
			for index = 1, #ids do
				local name = ns.SpellNameHeld(ids[index])
				if name then
					eats[name] = true
				end
			end
		end
	end
	return eats[spell] == true
end

--------------------------------------------------------------------------
-- The log
--
-- Twenty-one values, because the off hand flag is the last of them on a
-- landed swing, and your own GUID after them, which is what ns.CombatLog adds
-- to the client's own list. The thirteenth value is read as two different
-- things on purpose: it is the off hand flag on SWING_MISSED and the spell's
-- name on SPELL_DAMAGE and SPELL_MISSED, which is the client's own layout and
-- not a shortcut taken here.
--------------------------------------------------------------------------

-- hot: handed to ns.CombatLog.Subscribe when the swing timer arms and called
-- back out of the reader list on every combat log line, which is an edge
-- scripts/hot.lua cannot see.
local function OnLog(_, subevent, _, sourceGUID, _, _, _, _, _, _, _,
	_, a13, _, _, _, _, _, _, _, a21, me)
	if sourceGUID ~= me then
		return
	end

	if subevent == "SWING_DAMAGE" then
		Swing.Start(a21 and Swing.OFF or Swing.MAIN)
	elseif subevent == "SWING_MISSED" then
		Swing.Start(a13 and Swing.OFF or Swing.MAIN)
	elseif subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED" then
		-- A missed one counts as much as a landed one. The server took the
		-- swing either way, which is the same reason SWING_MISSED is read.
		if Eats(a13) then
			Swing.Start(Swing.MAIN)
		end
	end
end

--------------------------------------------------------------------------

-- On the log while the switch is on and off it entirely while it is not.
--
-- The swing bars ship off, and this file registered the event at load anyway,
-- so a player who never turned them on paid an unpack of every combat log line
-- in the zone to time a bar that was never drawn.
function Swing.Apply()
	if ns.db and ns.db.swing then
		ns.CombatLog.Subscribe(OnLog)
	else
		ns.CombatLog.Unsubscribe(OnLog)
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
-- The names are dropped rather than rebuilt, because the class is not reliably
-- known while the files load and an empty set latched at login would cost a
-- warrior every Heroic Strike of the session.
events:RegisterEvent("SPELLS_CHANGED")
-- The three ways a swing changes length. The first is the client saying so and
-- is the one that ought to be enough. It is not: Flurry is an aura and the
-- attack speed event does not reliably follow one on these clients, which is
-- the single most common thing a warrior's swing timer gets wrong. So the
-- player's own aura changes are read too, and every one of them ends in a
-- comparison against the speed already held. The third is a weapon swap, which
-- Reweapon above answers by restarting the swing rather than scaling it.
--
-- Filtered to the player where the client can filter, which is ns.RegisterUnitEvent
-- in Core. Unfiltered, UNIT_AURA is every aura on every unit in range, which in
-- a raid is thousands of events a fight reaching a handler that answers "not
-- you" to all but a handful.
ns.RegisterUnitEvent(events, "UNIT_ATTACK_SPEED", "player")
ns.RegisterUnitEvent(events, "UNIT_AURA", "player")
ns.RegisterUnitEvent(events, "UNIT_INVENTORY_CHANGED", "player")
events:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_REGEN_ENABLED" then
		Swing.Stop(Swing.MAIN)
		Swing.Stop(Swing.OFF)
		return
	end

	if event == "SPELLS_CHANGED" then
		eats = nil
		return
	end

	if event == "UNIT_ATTACK_SPEED" or event == "UNIT_AURA"
		or event == "UNIT_INVENTORY_CHANGED" then
		if unit == "player" then
			Swing.Retime()
		end
		return
	end

	eats = nil
	Swing.Apply()
	Swing.Retime()
end)
