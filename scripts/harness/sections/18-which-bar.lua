-- Which bar is yours
--
-- Four states and not two. The third is the one that gets lost in a refactor:
-- with nothing targeted every bar is bright, because dimming the whole screen
-- to say "none of these" is noise and it is the moment you most want to read
-- threat off a mob that is not yours yet.

local H = ...
local guids, ns, fire = H.guids, H.ns, H.fire
local check = H.check
local barMoving, barVerify = H.carry.barMoving, H.carry.barVerify

-- Everything above this point has been driving the panel and the skin, so
-- the bars are put back where this section needs them rather than assumed.
-- UnitIsUnit compares tokens in the stub, which is enough for every other
-- caller and not enough here: "nameplate1" and "target" are two tokens for
-- one mob and that is the whole question being asked.
local realIsUnit = _G.UnitIsUnit
_G.UnitIsUnit = function(x, y)
	if x == y then
		return true
	end
	return guids[x] ~= nil and guids[x] == guids[y]
end

ns.db.bars = true
ns.db.barsMode = "plates"
guids.target = nil
ns.EnemyBars.Rebuild()
for i = 1, 2 do
	fire("NAME_PLATE_UNIT_ADDED", "nameplate" .. i)
end
check(ns.EnemyBars.WidgetFor("nameplate1") ~= nil,
	"no bar attached, so the alpha states below would pass on nothing")

local function Alpha(unit)
	local bar = ns.EnemyBars.WidgetFor(unit)
	return bar and bar:GetAlpha() or -1
end
-- One full reading of every bar, which is a second of frames now rather than a
-- fifth of one: the bars are told about a mob by four unit events and read the
-- client from the top once a second behind them. Four long frames rather than
-- sixty short ones because nothing below is measuring a ramp with this.
local function Tick()
	for _ = 1, 4 do
		barMoving:Beat(0.3)
		barVerify:Beat(0.3)
	end
end

-- One frame, which is what draws whatever an event just marked.
local function Frame()
	barMoving:Beat(1 / 60)
	barVerify:Beat(1 / 60)
end

Tick()
check(Alpha("nameplate1") == 1 and Alpha("nameplate2") == 1,
	"with nothing targeted both bars should be bright")

guids.target = guids.nameplate1
Tick()
check(Alpha("nameplate1") == 1, "the targeted bar should be at full alpha")
check(Alpha("nameplate1") > Alpha("nameplate2"),
	("the targeted bar is %.2f against %.2f on the other")
		:format(Alpha("nameplate1"), Alpha("nameplate2")))

guids.target = guids.nameplate2
Tick()
check(Alpha("nameplate2") > Alpha("nameplate1"),
	"switching target should move the bright bar with it")

guids.target = nil
Tick()
check(Alpha("nameplate1") == 1 and Alpha("nameplate2") == 1,
	"dropping target should bring every bar back to full")

guids.target = guids.nameplate1
Tick()
print(("alpha  yours %.2f, theirs %.2f, and every bar %.2f with nothing targeted")
	:format(Alpha("nameplate1"), Alpha("nameplate2"), 1))

--------------------------------------------------------------------------
-- Told rather than polled
--
-- The four states above are what the bars draw. What follows is when they draw
-- it: the client says a mob's health, auras, threat or target moved and the
-- bars mark that widget, so the change is on screen on the next frame rather
-- than at the next reading. A pass that only ever ran on the tick would pass
-- every check above and put all of them up to a second late.
--------------------------------------------------------------------------

guids.target = guids.nameplate2
fire("PLAYER_TARGET_CHANGED")
Frame()
check(Alpha("nameplate2") > Alpha("nameplate1"),
	"changing target did not reach the bars until the next reading")

local hit = ns.EnemyBars.WidgetFor("nameplate1")
_G.WarriorKitHealth.nameplate1 = 1200
fire("UNIT_HEALTH", "nameplate1")
Frame()
check(hit.health:GetValue() == 1200,
	("a mob taking a hit did not reach its gauge until the next reading: %s")
		:format(tostring(hit.health:GetValue())))

-- And the other way: an event for somebody else's mob is not this one's news.
_G.WarriorKitHealth.nameplate1 = 800
fire("UNIT_HEALTH", "nameplate2")
Frame()
check(hit.health:GetValue() == 1200,
	"a bar redrew on an event that named another unit")

_G.WarriorKitHealth.nameplate1 = nil
guids.target = nil
fire("PLAYER_TARGET_CHANGED")
Tick()
print("told   a target change and a health event are on screen the next frame, and neither reaches the other bar")

--------------------------------------------------------------------------
-- Arriving and leaving
--
-- The ramp is a second thing riding on the same channel, so it is checked here
-- rather than somewhere of its own: what has to hold is that the two multiply.
-- A bar halfway in that is not your target is dim and half arrived at once, and
-- a refactor that let either one overwrite the other would still pass every
-- check above.
--------------------------------------------------------------------------

guids.target = nil
local frame = 1 / 60

-- Leaving first, because nameplate1 is up. A bar on a plate goes out in the
-- frame its plate does. The ramp used to hold it on UIParent where the plate
-- had stood, and finding that place is a positional read under a plate, which
-- the client refuses. The plate is hidden the moment its mob is gone, so there
-- is nowhere else a tail could draw.
local leaving = ns.EnemyBars.WidgetFor("nameplate1")
fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
check(ns.EnemyBars.WidgetFor("nameplate1") == nil,
	"the bar is still attached to a plate that is gone")
check(not leaving:IsShown(), "a bar that left its plate is still on the screen")
check(leaving:GetParent() == _G.UIParent,
	"a bar that left its plate is still a child of it")

-- And arriving, which is the same plate coming back.
fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(Alpha("nameplate1") == 0, "a bar arrived at full alpha instead of from nothing")
for _ = 1, 4 do
	barMoving:Beat(frame)
	barVerify:Beat(frame)
end
local arriving = Alpha("nameplate1")
check(arriving > 0 and arriving < 1,
	("four frames in, a bar arriving is at %.2f and should be between the two"):format(arriving))
Tick()
check(Alpha("nameplate1") == 1, "a bar never finished arriving")

-- Off has to mean off rather than fast: a plate arriving is a bar at full
-- alpha on the frame it arrives, which is what the bars did before the ramp.
ns.db.barsFade = false
fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(Alpha("nameplate1") == 1, "with the ramp off a bar still arrived from nothing")
ns.db.barsFade = true

print(("ramp   four frames in is %.2f, out is off the plate and holding its place, off is full on the frame")
	:format(arriving))

--------------------------------------------------------------------------
-- Players
--
-- Every player but you gets a bar on a plate, on either side and whether or
-- not you may hit them. Attackable is still the whole rule for a mob. Driven
-- on nameplate2 rather than a plate of its own, because the stub's plates
-- persist and a third would be in every scene after this one.
--------------------------------------------------------------------------

local realPlayers, unitFaction, unitClass = H.realPlayers, H.unitFaction, H.unitClass
local pvpUnits, ffaUnits = H.pvpUnits, H.ffaUnits
local friendlyUnits = _G.WarriorKitFriendlyUnits
local Color = ns.Unit.Color

fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
realPlayers.nameplate2, unitFaction.nameplate2 = true, "Horde"
fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
check(ns.EnemyBars.WidgetFor("nameplate2") ~= nil,
	"an unflagged player of the other faction got no bar")
Tick()
check(not ns.EnemyBars.WidgetFor("nameplate2").pvp:IsShown(),
	"an unflagged player of the other faction carries the PvP flag")

-- Flagging in front of you is the faction event, and the flag is on the bar
-- the next frame rather than at the next reading. Every player has a bar, so
-- the flag is the one thing on the screen that says which of them may start
-- on you, and a badge that never drew would leave the two looking the same.
pvpUnits.nameplate2 = true
fire("UNIT_FACTION", "nameplate2")
Frame()
local flag = ns.EnemyBars.WidgetFor("nameplate2").pvp
check(flag:IsShown() and flag:GetTexture() == "Interface\\TargetingFrame\\UI-PVP-Horde",
	("a flagged Horde player's bar drew %s where the Horde flag belongs")
		:format(tostring(flag:IsShown() and flag:GetTexture() or "nothing")))
check(flag:GetWidth() > ns.EnemyBars.WidgetFor("nameplate2").marker:GetWidth(),
	"the flag is drawn no bigger than the raid marker, and the art it uses is mostly margin")

-- The flag dropping takes the badge and leaves the bar.
pvpUnits.nameplate2 = nil
Tick()
check(ns.EnemyBars.WidgetFor("nameplate2") ~= nil,
	"a player whose flag dropped lost the bar")
check(not ns.EnemyBars.WidgetFor("nameplate2").pvp:IsShown(),
	"a player whose flag dropped still carries it")

-- Gurubashi: no PvP flag, free-for-all instead, and the skull for it.
ffaUnits.nameplate2 = true
fire("UNIT_FACTION", "nameplate2")
Frame()
check(ns.EnemyBars.WidgetFor("nameplate2").pvp:GetTexture()
	== "Interface\\TargetingFrame\\UI-PVP-FFA",
	"a free-for-all player's bar drew the faction flag instead of the skull")
ffaUnits.nameplate2 = nil
Tick()

-- Not you. With nameplateShowSelf on the client puts a plate up for you too,
-- and the skinned player frame already says everything a bar would. The
-- section's UnitIsUnit compares GUIDs, so the plate is you by carrying yours.
local plateWas, playerWas = guids.nameplate2, guids.player
fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
guids.player = playerWas or "Player-0-SELF"
guids.nameplate2 = guids.player
fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
check(ns.EnemyBars.WidgetFor("nameplate2") == nil, "your own plate got a bar")
fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
guids.nameplate2, guids.player = plateWas, playerWas
fire("NAME_PLATE_UNIT_ADDED", "nameplate2")

-- Your own side, who you cannot attack outside a duel. The bar is there
-- anyway, and it wears the class: a player has no threat table, so a gauge
-- coloured by threat would be the idle grey on every player in a city. Ten
-- levels is below the green line against the stub's 62, which is the name a
-- mob would grey out as worthless and a friend must not.
unitFaction.nameplate2, friendlyUnits.nameplate2 = "Alliance", true
unitClass.nameplate2 = "PRIEST"
_G.WarriorKitLevels.nameplate2 = 10
fire("UNIT_FACTION", "nameplate2")
Tick()
local mate = ns.EnemyBars.WidgetFor("nameplate2")
check(mate ~= nil, "a player of your own faction you cannot attack got no bar")
check(not mate.pvp:IsShown(), "an unflagged player of your own faction carries the PvP flag")
check(mate.threatColor == Color.Class("PRIEST"),
	"a priest's gauge wore threat rather than the class colour")
check(ns.Unit.Level.WorthAt("nameplate2", 10) == Color.xp.none,
	"ten levels down is not below the green line here, so the grey check below proves nothing")
check(mate.nameColor ~= Color.xp.none,
	"a friendly player far below you had the worthless grey name")

-- Flagged, which your own side can be too, and the flag is your faction's.
-- Left up on purpose: the widget goes back to the pool carrying it.
pvpUnits.nameplate2 = true
fire("UNIT_FACTION", "nameplate2")
Frame()
check(mate.pvp:IsShown() and mate.pvp:GetTexture() == "Interface\\TargetingFrame\\UI-PVP-Alliance",
	"a flagged player of your own faction drew no Alliance flag")

print("players every player but you gets a bar on either side, in the class colour; the flag says who may start on you and a mob carries none")

-- Back to a mob, so every section after this one sees the plate it always has.
fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
realPlayers.nameplate2, unitFaction.nameplate2 = nil, nil
friendlyUnits.nameplate2, unitClass.nameplate2 = nil, nil
pvpUnits.nameplate2, _G.WarriorKitLevels.nameplate2 = nil, nil
fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
check(ns.EnemyBars.WidgetFor("nameplate2") ~= nil, "nameplate2 did not come back as a mob")
Tick()
Tick()
-- The widget that sat on the flagged player is the one the pool handed back
-- for the mob, so this is the badge coming off rather than a fresh widget
-- never having drawn it.
check(ns.EnemyBars.WidgetFor("nameplate2") == mate,
	"the pool handed the mob a different widget, so the check below proves nothing")
check(not ns.EnemyBars.WidgetFor("nameplate2").pvp:IsShown(),
	"a pooled widget came back onto a mob still carrying the last player's flag")

--------------------------------------------------------------------------
-- The list, and the plate the client puts up
--
-- The list is the enemy panel and keeps the narrow rule, so the player next
-- to you at the bank is not a row. The friendly player plate is a CVar the
-- bars borrow while they are on plates and hand back when they are not.
--------------------------------------------------------------------------

check(_G.GetCVar("nameplateShowFriendlyPlayers") == "1",
	"the bars are on plates and the client is not putting up friendly player plates")

realPlayers.nameplate2, friendlyUnits.nameplate2 = true, true
ns.db.barsMode = "list"
ns.EnemyBars.Rebuild()
Tick()
check(_G.GetCVar("nameplateShowFriendlyPlayers") == "0",
	"the list left friendly player plates up with no bar to put on them")
local friendRows = ns.EnemyBars.Count()
realPlayers.nameplate2, friendlyUnits.nameplate2 = nil, nil
Tick()
check(ns.EnemyBars.Count() == friendRows + 1,
	("the list drew %d rows with a friendly player on nameplate2 and %d with a mob there")
		:format(friendRows, ns.EnemyBars.Count()))

ns.db.barsMode = "plates"
ns.EnemyBars.Rebuild()
Tick()
check(ns.EnemyBars.WidgetFor("nameplate1") ~= nil and ns.EnemyBars.WidgetFor("nameplate2") ~= nil,
	"the plates did not get their bars back after the list")

print("list   a friendly player is no row, and the friendly plate CVar is up on plates and handed back in the list")

_G.UnitIsUnit = realIsUnit
guids.target = nil
