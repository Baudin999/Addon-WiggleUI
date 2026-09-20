-- The swing timer
--
-- Six questions, and only the last of them is about drawing.
--
-- Does the log start the right hand. The off hand flag is the twenty-first
-- value of SWING_DAMAGE and the second of SWING_MISSED, and reading the wrong
-- slot gives an off hand bar that never runs and a main hand bar that runs at
-- twice the speed. That looks like a haste bug and is a parser bug, which is
-- why it is asserted from both subevents and from a stranger's swing as well
-- as from the player's.
--
-- Does the swing come off the weapon. UnitAttackSpeed is the only source and
-- a swap has to move it, so the speed is changed under a running timer and the
-- bar is measured again.
--
-- Does haste scale what is left rather than restart it. Flurry landing halfway
-- through a swing leaves you halfway through a shorter swing, and a timer that
-- kept the elapsed instead would jump backwards every time it landed. This is
-- the single thing a warrior's swing timer has to get right and it is one line
-- of arithmetic, which is exactly the kind of line that gets rewritten wrong.
--
-- Does an ability that eats the white hit restart the swing. Heroic Strike and
-- Cleave replace it and a finished Slam resets it, and none of the three
-- arrives as SWING_DAMAGE. A timer reading white hits alone freezes for a
-- whole swing on most of a warrior's presses, which is the defect that made
-- the bar useless in game.
--
-- Does a weapon swap restart the swing rather than scale it. Haste scales what
-- is left; equipping a weapon throws it away. Both arrive on
-- UNIT_INVENTORY_CHANGED, so this swaps the link under an unchanged speed: a
-- timer that told the two apart by the speed would call that one no change.
--
-- And does the tick stay free. This is the only thing in the addon that draws
-- on every frame, so what it allocates per tick is gated below and the fill's
-- unguarded write is measured rather than argued about.

local H = ...
local PLAYER_CLASS, CHURN = H.PLAYER_CLASS, H.CHURN
local guids, advance = H.guids, H.advance
local itemLink, swing, logArgs = H.itemLink, H.swing, H.logArgs
local ns, fire, check = H.ns, H.fire, H.check
local window = H.carry.window

-- The running swing tick, or nothing. It goes with the switch: armed when the
-- part is turned on and stopped when it is turned off, so this answers both
-- halves. Every permanent tick hangs off ns.UI.Forever, so the frame says
-- nothing and the slot name is what to ask for.
local function ticker()
	return ns.UI.Ticking("swing")
end

local ME = "Player-0-0000000f"
local SOMEBODY = "Player-0-0000001f"

-- Rank one of each of the three a warrior's file names, a later rank of one of
-- them, and one that is not on the list at all.
--
-- 11564 is a later rank of Heroic Strike on Wowhead's TBC database. It is here
-- because the class file names rank 1 and nothing else, and the game hands a
-- level 70 warrior rank 9: a match on the id would miss every press a real
-- character makes. Rend lands beside the swing rather than instead of it, so
-- it is what proves the match is a list and not "any spell of yours".
local HEROIC_STRIKE, CLEAVE, SLAM = 78, 845, 1464
local LATER_RANK, REND = 11564, 772

-- Nothing at all with the part off, which is how it ships. It was built at
-- login whatever the switch said and its ticker was armed at interval zero, so
-- a feature nobody had turned on ran a function on every frame the client drew
-- for the whole session.
check(ns.SwingGauges.Bar(ns.Swing.MAIN) == nil,
	"the swing bars were built with the part off")
check(ticker() == nil, "the swing ticker was armed with the part off")

-- The scene is stated rather than inherited. The part ships off, and it ships
-- at 2x for a bar read out of the corner of the eye; there is nothing at all
-- to measure with the setting off, and the grid assertion below is a whole
-- pixel by definition only at the design size. Section 27 puts both back.
ns.db.swing, ns.db.swingZoom = true, 1

guids.player = ME
swing.mainhand = itemLink("Arcanite Reaper")
swing.main, swing.off = 3.4, nil
fire("PLAYER_ENTERING_WORLD")
ns.SwingGauges.Apply()

local swingTicker = ticker()
check(swingTicker ~= nil, "turning the swing timer on armed no ticker")

local frame = _G.WiggleUISwing
check(frame ~= nil, "no swing frame came up")
local mainBar = ns.SwingGauges.Bar(ns.Swing.MAIN)
local offBar = ns.SwingGauges.Bar(ns.Swing.OFF)
check(mainBar ~= nil and offBar ~= nil, "the swing timer built fewer than two bars")

----------------------------------------------------------------------
-- The shape
----------------------------------------------------------------------

check(math.abs(ns.UI.Pixel(frame) - 1) < 1e-9,
	("the swing bars are not on the grid: one pixel is %.4f units"):format(ns.UI.Pixel(frame)))
check(mainBar:GetWidth() == ns.db.swingWidth,
	("the main hand bar is %.1f px, the setting says %d")
		:format(mainBar:GetWidth(), ns.db.swingWidth))
check(mainBar:GetHeight() == ns.db.swingHeight,
	("the main hand bar is %.1f px tall, the setting says %d")
		:format(mainBar:GetHeight(), ns.db.swingHeight))
check(not offBar:IsShown(), "the off hand bar is drawn with nothing in the off hand")
check(frame:GetHeight() == ns.db.swingHeight,
	("one bar and the frame is %.1f px tall, the bar is %d")
		:format(frame:GetHeight(), ns.db.swingHeight))

-- The scale is the bar's own width, which is what makes a fill a whole
-- number of pixels rather than a fraction of one.
local low, high = mainBar:GetMinMaxValues()
check(low == 0 and high == ns.db.swingWidth,
	("the bar counts %s to %s, and it should count pixels")
		:format(tostring(low), tostring(high)))

----------------------------------------------------------------------
-- The log
--
-- Twenty-one values, and the off hand flag is in a different slot on each
-- of the two subevents that carry one.
----------------------------------------------------------------------

local function white(subevent, source, offhand)
	for index = 1, 21 do
		logArgs[index] = nil
	end
	logArgs[1] = GetTime()
	logArgs[2] = subevent
	logArgs[4] = source
	if subevent == "SWING_MISSED" then
		logArgs[12] = "DODGE"
		logArgs[13] = offhand
	else
		logArgs[12] = 300
		logArgs[13] = -1
		logArgs[21] = offhand
	end
	fire("COMBAT_LOG_EVENT_UNFILTERED")
end

check(not ns.Swing.Armed(ns.Swing.MAIN),
	"a swing was running before anything had swung")

white("SWING_DAMAGE", SOMEBODY)
check(not ns.Swing.Armed(ns.Swing.MAIN),
	"somebody else's swing started your timer")

white("SWING_DAMAGE", ME)
check(ns.Swing.Armed(ns.Swing.MAIN), "your own swing did not start the timer")
check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - 3.4) < 1e-6,
	("a 3.4s weapon left %.3fs to run"):format(ns.Swing.Remaining(ns.Swing.MAIN)))

-- A dodge is the server saying the swing happened and did nothing, so it
-- restarts the timer exactly as a landed hit does. A timer that only heard
-- damage would stop dead against a mob you cannot hit.
advance(1.0)
white("SWING_MISSED", ME)
check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - 3.4) < 1e-6,
	("a dodged swing left %.3fs to run, and it restarts the timer")
		:format(ns.Swing.Remaining(ns.Swing.MAIN)))

-- The off hand, from both directions. With nothing in that hand there is no
-- speed to run and the flag does nothing at all.
white("SWING_DAMAGE", ME, true)
check(not ns.Swing.Armed(ns.Swing.OFF),
	"an off hand swing ran a timer for a hand holding nothing")

swing.off = 1.8
swing.offhand = itemLink("Bloodspiller")
fire("UNIT_INVENTORY_CHANGED", "player")
check(offBar:IsShown(), "a weapon went into the off hand and no bar came up")
check(frame:GetHeight() == ns.db.swingHeight * 2 + 2,
	("two bars and a two pixel gap is %d px, the frame is %.1f")
		:format(ns.db.swingHeight * 2 + 2, frame:GetHeight()))

white("SWING_DAMAGE", ME, true)
check(math.abs(ns.Swing.Remaining(ns.Swing.OFF) - 1.8) < 1e-6,
	("the off hand flag on SWING_DAMAGE left %.3fs, and the off hand is 1.8s")
		:format(ns.Swing.Remaining(ns.Swing.OFF)))
white("SWING_MISSED", ME, true)
check(math.abs(ns.Swing.Remaining(ns.Swing.OFF) - 1.8) < 1e-6,
	("the off hand flag on SWING_MISSED left %.3fs, and the off hand is 1.8s")
		:format(ns.Swing.Remaining(ns.Swing.OFF)))

-- And the main hand is untouched by either, which is the half that fails
-- when the two flags are read out of one slot.
advance(0.4)
local before = ns.Swing.Remaining(ns.Swing.MAIN)
white("SWING_DAMAGE", ME, true)
check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - before) < 1e-6,
	"an off hand swing restarted the main hand timer")

----------------------------------------------------------------------
-- Haste, which is the line that has to be right
----------------------------------------------------------------------

white("SWING_DAMAGE", ME)
advance(1.7)
check(math.abs(ns.Swing.Fraction(ns.Swing.MAIN) - 0.5) < 1e-6,
	("halfway through a 3.4s swing reads as %.3f"):format(ns.Swing.Fraction(ns.Swing.MAIN)))

-- Flurry, as an aura rather than as an attack speed event, because the
-- attack speed event does not reliably follow one on these clients and
-- that is the whole reason UNIT_AURA is registered.
swing.main = 2.4
fire("UNIT_AURA", "player")
check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - 1.7 * 2.4 / 3.4) < 1e-6,
	("1.7s left of a 3.4s swing hasted to 2.4s should leave %.3fs and left %.3fs")
		:format(1.7 * 2.4 / 3.4, ns.Swing.Remaining(ns.Swing.MAIN)))
check(math.abs(ns.Swing.Fraction(ns.Swing.MAIN) - 0.5) < 1e-6,
	("haste moved the fill to %.3f, and scaling what is left keeps it at half")
		:format(ns.Swing.Fraction(ns.Swing.MAIN)))

-- An aura for somebody else's buff, which is most of them, costs a
-- comparison and writes nothing.
local held = ns.Swing.Remaining(ns.Swing.MAIN)
fire("UNIT_AURA", "player")
check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - held) < 1e-6,
	"an aura event that moved no speed still moved the swing")

-- A weapon swap is the same arithmetic arriving by another door, and it is
-- the one this addon causes itself out of the charge macro.
swing.main = 3.4
fire("UNIT_ATTACK_SPEED", "player")
check(math.abs(ns.Swing.Speed(ns.Swing.MAIN) - 3.4) < 1e-6,
	("the weapon went back to 3.4s and the timer says %.3f")
		:format(ns.Swing.Speed(ns.Swing.MAIN)))

----------------------------------------------------------------------
-- The abilities that eat a swing
--
-- Heroic Strike and Cleave replace the white hit and a finished Slam resets
-- the swing. None of the three reaches the log as SWING_DAMAGE: what arrives
-- is SPELL_DAMAGE, or SPELL_MISSED where the server took the swing and the
-- ability did nothing, under the ability's own name.
--
-- Which abilities those are is the registry's answer and not a warrior's, so a
-- class whose file named none is given none and every SPELL_DAMAGE line it
-- sends leaves the swing alone.
----------------------------------------------------------------------

-- The same twenty-one values, with the spell in slot 12 and its name in 13.
-- Slot 13 is the off hand flag on SWING_MISSED, which is the client's own
-- layout and the reason Swing.lua reads that slot as two different things.
local function ability(subevent, source, spell, name)
	for index = 1, 21 do
		logArgs[index] = nil
	end
	logArgs[1] = GetTime()
	logArgs[2] = subevent
	logArgs[4] = source
	logArgs[12] = spell
	logArgs[13] = name or ns.SpellName(spell)
	logArgs[15] = (subevent == "SPELL_MISSED") and "DODGE" or 300
	fire("COMBAT_LOG_EVENT_UNFILTERED")
end

local eats = ns.Class.Of("swing") ~= nil

white("SWING_DAMAGE", ME)
advance(2.0)
ability("SPELL_DAMAGE", ME, HEROIC_STRIKE)
if eats then
	check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - 3.4) < 1e-6,
		("a Heroic Strike left %.3fs of swing, and it eats the white hit")
			:format(ns.Swing.Remaining(ns.Swing.MAIN)))

	-- A dodged one counts as much as a landed one, for the reason SWING_MISSED
	-- does: the server took the swing either way. And the other two abilities
	-- on the list, because a match on one id is not a match on a list.
	for _, spell in ipairs({ CLEAVE, SLAM }) do
		white("SWING_DAMAGE", ME)
		advance(2.0)
		ability("SPELL_MISSED", ME, spell)
		check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - 3.4) < 1e-6,
			("a dodged %s left %.3fs of swing, and it eats the white hit")
				:format(ns.SpellName(spell), ns.Swing.Remaining(ns.Swing.MAIN)))
	end

	-- And a rank the class file never named, under the name every rank shares.
	-- The id is one the addon has never seen; matched on the id rather than on
	-- the name, this is the press a level 70 warrior actually makes and the bar
	-- would freeze for the whole swing.
	white("SWING_DAMAGE", ME)
	advance(2.0)
	ability("SPELL_DAMAGE", ME, LATER_RANK, ns.SpellName(HEROIC_STRIKE))
	check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - 3.4) < 1e-6,
		("a later rank of Heroic Strike left %.3fs of swing, and every rank is one name")
			:format(ns.Swing.Remaining(ns.Swing.MAIN)))
else
	check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - 1.4) < 1e-6,
		("a %s was given an ability that eats a swing"):format(PLAYER_CLASS))
end

-- Somebody else's, and one of yours that lands beside the swing rather than
-- instead of it.
white("SWING_DAMAGE", ME)
advance(1.0)
local untouched = ns.Swing.Remaining(ns.Swing.MAIN)
ability("SPELL_DAMAGE", SOMEBODY, HEROIC_STRIKE)
ability("SPELL_DAMAGE", ME, REND)
check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - untouched) < 1e-6,
	"a spell that does not eat the swing restarted it")

----------------------------------------------------------------------
-- A weapon swap restarts the swing
--
-- Haste scales what is left of a swing already in flight. Equipping a weapon
-- throws it away and starts one of the new weapon's length, which is what
-- makes a swap mid fight cost a swing.
--
-- Both arrive on UNIT_INVENTORY_CHANGED and the speed is left at 3.4 across
-- the swap on purpose: a timer that told a swap from a proc by comparing
-- speeds would rescale this by one and call it no change at all.
----------------------------------------------------------------------

white("SWING_DAMAGE", ME)
advance(2.0)
swing.mainhand = itemLink("Bloodspiller")
fire("UNIT_INVENTORY_CHANGED", "player")
check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - 3.4) < 1e-6,
	("a weapon swap left %.3fs of the old swing, and it starts a whole new one")
		:format(ns.Swing.Remaining(ns.Swing.MAIN)))

-- And a trinket is not a weapon. The same event, nothing moved in either hand,
-- so the swing runs on rather than restarting under every bag change in a
-- fight.
advance(1.0)
local held = ns.Swing.Remaining(ns.Swing.MAIN)
fire("UNIT_INVENTORY_CHANGED", "player")
check(math.abs(ns.Swing.Remaining(ns.Swing.MAIN) - held) < 1e-6,
	"an inventory change that moved no weapon restarted the swing")

swing.mainhand = itemLink("Arcanite Reaper")
fire("UNIT_INVENTORY_CHANGED", "player")

----------------------------------------------------------------------
-- What that draws
----------------------------------------------------------------------

white("SWING_DAMAGE", ME)
advance(1.7)
swingTicker:Beat(0.05)

-- Read off the widget rather than off the bookkeeping field beside it, so a
-- tick that worked out the right number and never wrote it fails here.
local width = ns.db.swingWidth
check(math.abs(mainBar:GetValue() - 0.5 * width) < 1e-9,
	("half of a %d pixel bar is %.1f and the fill drew %s")
		:format(width, 0.5 * width, tostring(mainBar:GetValue())))

check(mainBar:IsShown(),
	("a %s holding a weapon was not drawn a swing bar"):format(PLAYER_CLASS))

----------------------------------------------------------------------
-- The page, which is where the check box lives
----------------------------------------------------------------------

local tabs = 0
for _, group in ipairs(window.groups) do
	for _, section in ipairs(group.sections) do
		if section.feature and section.feature.name == "swing" then
			tabs = tabs + 1
		end
	end
end
check(tabs == 1,
	("the swing part opened %d tabs on a %s"):format(tabs, PLAYER_CLASS))

-- On and off, from the setting the check box writes.
ns.db.swing = false
ns.SwingGauges.Apply()
check(not frame:IsShown(), "the swing bars stayed up with the setting off")
ns.db.swing = true
ns.SwingGauges.Apply()
check(frame:IsShown(), "the swing bars did not come back with the setting on")

-- Nothing in the main hand is nothing to time, whatever the setting says.
swing.mainhand = nil
ns.SwingGauges.Apply()
check(not frame:IsShown(), "the swing bars were drawn for an empty main hand")
swing.mainhand = itemLink("Arcanite Reaper")
ns.SwingGauges.Apply()

----------------------------------------------------------------------
-- Allocation
----------------------------------------------------------------------

local function swingChurn(n)
	collectgarbage("collect")
	collectgarbage("stop")
	local before = collectgarbage("count")
	for _ = 1, n do
		advance(0.05)
		swingTicker:Beat(0.05)
		-- Restarted through ns.Swing rather than through the log, because a
		-- log event wakes the meters too and what would be measured is
		-- their segment rather than this tick.
		if not ns.Swing.Armed(ns.Swing.MAIN) or ns.Swing.Remaining(ns.Swing.MAIN) <= 0 then
			ns.Swing.Start(ns.Swing.MAIN)
			ns.Swing.Start(ns.Swing.OFF)
		end
	end
	local after = collectgarbage("count")
	collectgarbage("restart")
	return (after - before) / (n / 50)
end

swingChurn(200)
local swingKb = swingChurn(200)
check(swingKb <= CHURN.swing,
	("the swing timer allocates %.2f KB per 50 ticks, the gate is %.2f")
		:format(swingKb, CHURN.swing))

print(("swing  %d x %d px per hand, main %.2fs off %.2fs, %s, %.2f KB per 50 ticks, gate is %.2f")
	:format(ns.db.swingWidth, ns.db.swingHeight, ns.Swing.Speed(ns.Swing.MAIN),
		ns.Swing.Speed(ns.Swing.OFF),
		eats and "three abilities eat a swing" or "no ability eats a swing",
		swingKb, CHURN.swing))

----------------------------------------------------------------------
-- Put the client back the way the sections after this one expect it.
----------------------------------------------------------------------

guids.player = nil
swing.mainhand, swing.offhand, swing.off = nil, nil, nil
swing.main = 3.4
fire("UNIT_INVENTORY_CHANGED", "player")
ns.Swing.Stop(ns.Swing.MAIN)
ns.Swing.Stop(ns.Swing.OFF)
ns.SwingGauges.Apply()
