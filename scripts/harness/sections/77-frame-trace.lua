-- Why a frame took that long
--
-- The recorder and the four answers it can give. Nothing here reads the source
-- and takes its word for it: each of the four is arranged in the stub and the
-- sentence the dip log wrote is compared against.
--
--   an event storm    two hundred and fifty events fired between two frames
--   Lua               the profiler on and the counter moved 90 ms
--   the client        the profiler on, the counter still, the collector stopped
--   unknown           the profiler off, which is how the addon ships
--
-- And the three things that are not answers. An ordinary frame is not written
-- into the log. A frame on the far side of a loading screen is not either,
-- because the client draws one enormous one on the way back into the world and
-- it is not a stall. And the recorder allocates nothing: it runs on every frame
-- the client draws, so a table per frame would be the fault the whole part
-- exists to find.
--
-- The census is driven at its own door rather than through fire(). This stub
-- has no RegisterAllEvents, so an event fired here reaches the frames that
-- named it and nothing else, and Perf/Census.lua names none of them: that is
-- the whole of what it is. What is worth asserting is what it does with a name
-- it is handed, which is what ns.Census.Count is, and the client's own delivery
-- is the half no stub can answer for anyway.

local H = ...
local ns, check, fire = H.ns, H.check, H.fire

local Trace, Cause, Census = ns.Trace, ns.Cause, ns.Census

----------------------------------------------------------------------
-- Armed at login, because the setting says to watch all session
----------------------------------------------------------------------

check(Trace.Watching(), "the frame trace did not start at login")
check(Census.Watching(), "the census did not start with the trace")
check(ns.UI.Ticking("frame") ~= nil, "the recorder armed no ticker")

local frame = H.tick("frame")
Trace.Forget()

----------------------------------------------------------------------
-- Sixty ordinary frames
----------------------------------------------------------------------

for _ = 1, 60 do
	frame:Beat(0.016)
end

local last = Trace.Second()
check(last.frames == 60,
	("a second of 16 ms frames counted %d of them"):format(last.frames))
check(last.worst > 15 and last.worst < 17,
	("the worst of sixty 16 ms frames read as %.1f ms"):format(last.worst))
check(Trace.Dips() == 0, "an ordinary frame was written into the dip log")
check(Trace.Column(1) ~= nil, "the strip has no column for the first frame")
check(Trace.Head() == 60, ("the ring head is at %d after sixty frames"):format(Trace.Head()))

----------------------------------------------------------------------
-- Off the shelf, which is the profiler off
--
-- Arranged the way 2.5.6 actually behaves rather than the way it is convenient
-- to stub. The client always has GetScriptCPUUsage. With scriptProfile off the
-- call is still there, still callable, and answers a constant 0, so "off" is
-- not the absence of the call and a stub that leaves it nil is testing a client
-- that does not exist. It left Perf/Cause.lua free to read that 0 as a
-- measurement: the dip said unknown for the right answer by accident, and the
-- minute log wrote 0.00 ms of Lua under a profiled flag it had latched on a
-- zero, for every row of a three hour session.
----------------------------------------------------------------------

_G.GetScriptCPUUsage = function() return 0 end
check(not Cause.Profiling(), "scriptProfile is off and Cause reads the profiler as on")
check(Cause.LuaSince() == nil,
	("the profiler is off and a frame claims %s ms of Lua"):format(tostring(Cause.LuaSince())))

frame:Beat(0.120)
check(Trace.Dips() == 1, ("one long frame wrote %d dips"):format(Trace.Dips()))

local _, took, why = Trace.Dip(1)
check(took > 119 and took < 121, ("a 120 ms frame was logged as %.0f ms"):format(took))
check(why:match("^unknown"),
	("with no profiler the dip reads %q, and nothing can honestly say more"):format(why))

----------------------------------------------------------------------
-- An event storm
--
-- Counted under a name nothing in the addon listens for, so what is being
-- measured is the census and not two hundred and fifty unit frame passes.
----------------------------------------------------------------------

for _ = 1, 250 do
	Census.Count("WARRIORKIT_HARNESS_EVENT")
end
frame:Beat(0.150)
_, _, why = Trace.Dip(1)
check(why:match("^250 events"),
	("a frame with 250 events in it reads %q"):format(why))
check(Trace.Dips() == 2, "the storm did not land on top of the log")

-- Newest first, and the older one is still underneath it.
local older
_, older = Trace.Dip(2)
check(older > 119 and older < 121,
	("the second row of the log holds %.0f ms and should hold the 120"):format(older))

----------------------------------------------------------------------
-- The combat log, counted at the one door
--
-- Perf/Census.lua deliberately does not register for it. Core/CombatLog.lua
-- counts its own lines and the recorder folds the difference in, so a pull is
-- named as the combat log rather than going missing.
----------------------------------------------------------------------

local before = ns.CombatLog.Lines()
for _ = 1, 300 do
	fire("COMBAT_LOG_EVENT_UNFILTERED")
	-- Handed to the census as well, the way the client would on a build where
	-- RegisterAllEvents covers it. It has to come out of the count once and not
	-- twice, which is what the skip in Census.Count is for.
	Census.Count("COMBAT_LOG_EVENT_UNFILTERED")
end
check(ns.CombatLog.Lines() - before == 300,
	("300 combat log lines were counted as %d"):format(ns.CombatLog.Lines() - before))

frame:Beat(0.150)
_, _, why = Trace.Dip(1)
check(why:match("^300 events"),
	("300 lines counted twice would read as 600, and this reads %q"):format(why))
check(why:match("COMBAT_LOG_EVENT_UNFILTERED"),
	("a frame filled with combat log lines reads %q"):format(why))

----------------------------------------------------------------------
-- What the client holds, counted into the same minute
--
-- Thirty frames and three addons. The first two frames are hidden, the third
-- is forbidden and would answer visible if asked, and the last runs an
-- OnUpdate with four regions on it. The walk and the memory reading both run
-- inside the minute below, so the allocation check covers them. The first
-- reading is taken here, because it only plants the baseline.
----------------------------------------------------------------------

local Fake = {}
Fake.__index = Fake
function Fake:IsForbidden() return self.forbidden end
function Fake:IsVisible() return self.visible end
function Fake:GetNumRegions() return self.regions end
function Fake:GetScript(name) return (name == "OnUpdate") and self.onUpdate or nil end

local fakes, fakeAt = {}, {}
for index = 1, 30 do
	local fake = setmetatable({ visible = index >= 3, forbidden = index == 3, regions = 2 }, Fake)
	fakes[index], fakeAt[fake] = fake, index
end
fakes[30].regions, fakes[30].onUpdate = 4, function() end
_G.EnumerateFrames = function(after)
	if after == nil then
		return fakes[1]
	end
	return fakes[fakeAt[after] + 1]
end

local memoryNames, memoryKB = { "Details", "Questie", "WarriorKit" }, { 1000, 3000, 300 }
local clientUsage, clientUpdate = _G.GetAddOnMemoryUsage, _G.UpdateAddOnMemoryUsage
_G.UpdateAddOnMemoryUsage = function() end
_G.GetAddOnMemoryUsage = function(index) return memoryKB[index] or 0 end
_G.GetNumAddOns = function() return #memoryNames end
_G.GetAddOnInfo = function(index) return memoryNames[index] end
ns.Held.Read()
check(ns.Held.Grower() == "", "the first memory reading named an addon with nothing to compare against")
memoryKB[1], memoryKB[2] = memoryKB[1] + 100, memoryKB[2] + 900

-- Watching started again, which is a login with a reading already taken. An
-- addon over 2 MB gets a column of its own and the column is 180 slots, so it
-- is made where the log is made and not inside the minute measured below.
--
-- The same moment is where Perf/Probe.lua puts its count over Questie's combat
-- queue, so the queue is given to the stub loader first. It runs nothing: what
-- is counted is the asking.
local combatQueue = _G.QuestieLoader:ImportModule("QuestieCombatQueue")
local ran = 0
combatQueue.Queue = function() ran = ran + 1 end
Trace.Watch(false)
Trace.Watch(true)
check(type(ns.db.perfLog.addons) == "table" and ns.db.perfLog.addons.Questie ~= nil,
	"Questie holds 3000 KB at login and the log made no column for it")

----------------------------------------------------------------------
-- A minute of frames, written where a reload keeps it
--
-- A session that gets slower is 12 to 20 ms frames arriving more often by the
-- hour, and none of them is a dip. So the recorder sums each minute into a row
-- of the saved log. Driven here with a hundred 25 ms frames and 9 ms ones, a
-- frame that makes a 100 Hz deadline, to fill the minute. Each 25 ms frame is
-- followed by eight of 9, so the slow ones land 97 ms apart, which is the ten a
-- second beat the plateau of 2026-09-17 arrived on. The collector is stopped,
-- because the roll is reached from the tick and has to allocate nothing either.
----------------------------------------------------------------------

local log = ns.db.perfLog
check(type(log) == "table" and log.size == 180, "the saved minute log was not made at login")
Trace.Forget()
local head, rows = log.head, log.filled

ns.Probe.Roll()
for _ = 1, 3 do
	combatQueue:Queue(print)
end

-- Five of one event and two of another inside the minute. Both names are met
-- and the ranking asked once before it, so the roll finds nothing new to keep.
Census.Count("WARRIORKIT_HARNESS_EVENT")
Census.Count("WARRIORKIT_HARNESS_OTHER")
Census.Top()
for _ = 1, 5 do
	Census.Count("WARRIORKIT_HARNESS_EVENT")
end
for _ = 1, 2 do
	Census.Count("WARRIORKIT_HARNESS_OTHER")
end

collectgarbage("collect")
collectgarbage("stop")
local heldKB = collectgarbage("count")
local spent = 0
for _ = 1, 100 do
	frame:Beat(0.025)
	spent = spent + 0.025
	for _ = 1, 8 do
		frame:Beat(0.009)
		spent = spent + 0.009
	end
end
while spent < 60 do
	frame:Beat(0.009)
	spent = spent + 0.009
end
local rolledKB = collectgarbage("count") - heldKB
collectgarbage("restart")

check(rolledKB < 0.05, ("a minute of frames and its roll allocated %.2f KB"):format(rolledKB))
local row = log.head
check(row == head % 180 + 1, ("a minute of frames moved the log head from %d to %d"):format(head, row))
check(log.filled == math.min(rows + 1, 180), ("the log holds %d rows after one more minute"):format(log.filled))
check(log.over12[row] == 100 and log.over20[row] == 100,
	("100 frames of 25 ms were counted as %d over 12 and %d over 20"):format(log.over12[row], log.over20[row]))
check(log.over50[row] == 0, ("a minute with no stall counted %d"):format(log.over50[row]))
check(log.worst[row] == 25, ("the worst frame of the minute reads %s ms"):format(tostring(log.worst[row])))
check(log.avg[row] > 9 and log.avg[row] < 10,
	("a minute of mostly 9 ms frames averages %s ms"):format(tostring(log.avg[row])))
check(log.lua[row] == -1, ("with the profiler off the minute claims %s ms of Lua"):format(tostring(log.lua[row])))

check(log.uiFrames[row] == 30 and log.uiShown[row] == 27,
	("thirty frames with two hidden and one forbidden read as %s held and %s visible")
		:format(tostring(log.uiFrames[row]), tostring(log.uiShown[row])))
check(log.uiRegions[row] == 56 and log.uiTicking[row] == 1,
	("26 visible frames of 2 regions and one of 4 read as %s regions and %s ticking")
		:format(tostring(log.uiRegions[row]), tostring(log.uiTicking[row])))
check(log.grower[row] == "Questie" and log.grew[row] == 900,
	("Questie grew 900 KB and Details 100, and the row names %q at %s KB")
		:format(tostring(log.grower[row]), tostring(log.grew[row])))

-- The two the ranking above cannot answer. grower is a difference between two
-- samples of a number the collector swings, so it says who moved most in a
-- minute and never what is actually being held. These two say that.
check(log.oursKB[row] == 300,
	("this addon is holding 300 KB and its own column says %s")
		:format(tostring(log.oursKB[row])))
-- The collector is stopped for this minute, so the heap only ever rises and the
-- low water mark is the first frame of it. A floor above the heap would mean it
-- was taking the last reading rather than the smallest.
check(log.floor[row] > 0 and log.floor[row] <= log.heap[row],
	("a minute that only allocated has a floor of %s KB under a heap of %s")
		:format(tostring(log.floor[row]), tostring(log.heap[row])))

-- What the slow frames were, which is what the counts above cannot say.
check(log.slowMs[row] > 2499 and log.slowMs[row] < 2501,
	("100 frames of 25 ms took %s ms between them"):format(tostring(log.slowMs[row])))
check(log.beat[row] == 99,
	("100 slow frames 97 ms apart read as %s on the beat, and the first has none before it")
		:format(tostring(log.beat[row])))
check(log.slowKey[row] == "frame",
	("the recorder is the only ticker beaten here and the slow frames name %q")
		:format(tostring(log.slowKey[row])))
check(log.slowOurs[row] >= 0 and log.slowOurs[row] <= log.ours[row],
	("the slow frames hold %s ms of ours out of %s in the minute")
		:format(tostring(log.slowOurs[row]), tostring(log.ours[row])))
-- The collector is stopped, so nothing was given back in any frame.
check(log.sweeps[row] == 0 and log.slowSweeps[row] == 0,
	("a minute with the collector stopped counted %s sweeps, %s of them slow")
		:format(tostring(log.sweeps[row]), tostring(log.slowSweeps[row])))
check(log.slowAlloc[row] <= log.alloc[row],
	("the slow frames allocated %s KB of the minute's %s")
		:format(tostring(log.slowAlloc[row]), tostring(log.alloc[row])))
check(log.oursAlloc[row] >= 0,
	("tick timing is on and the brackets report %s KB"):format(tostring(log.oursAlloc[row])))

-- One column per addon over 2 MB, and the sum of all of them.
check(log.addons.Questie[row] == 3900,
	("Questie holds 3900 KB and its column says %s"):format(tostring(log.addons.Questie[row])))
check(log.addons.Details == nil and log.addons.WarriorKit == nil,
	"an addon under 2 MB was given a column of its own")
check(log.addonsKB[row] == 5300,
	("1100, 3900 and 300 KB sum to %s"):format(tostring(log.addonsKB[row])))
-- Questie's combat queue, counted. The wrapper went on when watching started
-- above, and three askings inside the minute are three in the row.
check(log.topEvent[row] == "WARRIORKIT_HARNESS_EVENT" and log.topEvents[row] == 5,
	("five of one event in the minute and the row names %q at %s")
		:format(tostring(log.topEvent[row]), tostring(log.topEvents[row])))
check(log.nextEvent[row] == "WARRIORKIT_HARNESS_OTHER" and log.nextEvents[row] == 2,
	("two of another and the runner up reads %q at %s")
		:format(tostring(log.nextEvent[row]), tostring(log.nextEvents[row])))
check(ran == 3, ("the count over Questie's queue called through %d times out of 3"):format(ran))
check(log.qQueued[row] == 3,
	("three things were queued with Questie in the minute and the row says %s")
		:format(tostring(log.qQueued[row])))
check(log.readMs[row] >= 0, ("the memory reading was timed at %s ms"):format(tostring(log.readMs[row])))

-- The frame after the roll is the memory reading, and it is not a stall.
local dipsAtRoll = Trace.Dips()
frame:Beat(0.120)
check(Trace.Dips() == dipsAtRoll, "the frame the memory reading landed in was logged as a dip")
frame:Beat(0.120)
check(Trace.Dips() == dipsAtRoll + 1, "a slow frame after the one that paid for the reading was not logged")

----------------------------------------------------------------------
-- The profiler on, which is the only way an addon gets named
----------------------------------------------------------------------

local script = 0
local cpu = { 0, 0, 0 }
local names = { "Details", "Questie", "WarriorKit" }
_G.GetScriptCPUUsage = function() return script end
_G.UpdateAddOnCPUUsage = function() end
_G.GetAddOnCPUUsage = function(index) return cpu[index] or 0 end
_G.GetNumAddOns = function() return #names end
_G.GetAddOnInfo = function(index) return names[index] end
_G.SetCVar("scriptProfile", "1")

check(Cause.Profiling(), "the stub turned the profiler on and Cause cannot see it")
check(Cause.Mark(), "the baseline could not be taken with the profiler on")

-- One frame to prime the counter, then a frame with 90 ms of Lua in it and one
-- addon holding most of it.
frame:Beat(0.016)
script = script + 90
cpu[1] = cpu[1] + 71
cpu[2] = cpu[2] + 12
frame:Beat(0.120)

_, _, why = Trace.Dip(1)
check(why:match("^Lua, 90 ms"), ("90 ms of Lua in a 120 ms frame reads %q"):format(why))
check(why:match("Details 71 ms"), ("the addon that spent it is not named: %q"):format(why))

----------------------------------------------------------------------
-- The client itself, which is the answer nobody wants and often the true one
----------------------------------------------------------------------

collectgarbage("collect")
collectgarbage("stop")
frame:Beat(0.016)
frame:Beat(0.180)
collectgarbage("restart")

_, _, why = Trace.Dip(1)
check(why:match("^not Lua"),
	("a long frame with no Lua in it reads %q, and the client is what is left"):format(why))

----------------------------------------------------------------------
-- A loading screen is not a stall
----------------------------------------------------------------------

local kept = Trace.Dips()
fire("PLAYER_ENTERING_WORLD")
frame:Beat(1.400)
check(Trace.Dips() == kept,
	"the frame the client drew coming out of a loading screen was logged as a stall")

----------------------------------------------------------------------
-- The sweep, one feature off at a time
--
-- Perf/Sweep.lua switches one feature off for a fixed number of minutes,
-- switches it back on and moves to the next, so the minute log can be split on
-- the `off` column afterwards. What is worth asserting is the four things that
-- would ruin the reading rather than the list of steps, which is a design
-- decision and not a fact: that a row names what was actually off during it,
-- that the next step restores before it switches, that a step due in a fight
-- waits and the rows still tell the truth about the minutes it waited through,
-- and that the feature always comes back.
--
-- Driven a minute at a time in whole seconds. The sweep changes step at the
-- roll and nowhere else, so what matters here is how many rolls happen and not
-- how many frames are in each one.
----------------------------------------------------------------------

-- In a block of its own, so its ten names stay out of the chunk.
do
	local function sweepMinute()
		for _ = 1, 60 do
			frame:Beat(1.0)
		end
		return log.head
	end

	check(ns.Sweep.Describe() == "not running",
		("nothing has started a sweep and it reads %q"):format(ns.Sweep.Describe()))

	local wasBars, wasSkin, wasCast = ns.db.bars, ns.db.skin, ns.db.playerCast
	check(wasBars and wasSkin and wasCast,
		"the first three steps of the sweep need their features on to switch them off")

	-- One minute a step, which is what the number after the word sets.
	ns.Sweep.Word("1")
	check(ns.db.bars == wasBars,
		"the first step is the baseline and it switched a feature off")

	-- The baseline minute, and then the first feature step.
	local first = sweepMinute()
	check(log.off[first] == "base",
		("the baseline minute is written as %q"):format(tostring(log.off[first])))
	check(ns.db.bars == false,
		"the minute rolled onto the enemy bars step and the bars are still on")

	local second = sweepMinute()
	check(log.off[second] == "bars",
		("the minute with the enemy bars off is written as %q"):format(tostring(log.off[second])))
	check(ns.db.bars == true and ns.db.skin == false,
		("the next step put the bars back at %s and took the skin at %s")
			:format(tostring(ns.db.bars), tostring(ns.db.skin)))

	-- A zone change is the same event the interrupted run is found on, and a step
	-- switched off ten seconds ago looks exactly like one switched off last session
	-- in the saved settings. The run in progress is what tells them apart.
	fire("PLAYER_ENTERING_WORLD")
	check(ns.db.skin == false and ns.db.perfSweep ~= nil,
		"zoning in the middle of a sweep read the run as an interrupted one and undid its step")

	----------------------------------------------------------------------
	-- A step that comes due in a fight
	--
	-- Half of the list owns secure frames, so a step change under lockdown is
	-- either refused by the client or taints the button. It waits, and the minutes
	-- it waits through are more minutes of the step that is already running, which
	-- is what they have to be written as.
	----------------------------------------------------------------------

	local realLockdown = _G.InCombatLockdown
	_G.InCombatLockdown = function() return true end

	local third = sweepMinute()
	check(log.off[third] == "skin",
		("the unit frame skin's own minute is written as %q"):format(tostring(log.off[third])))
	local fourth = sweepMinute()
	check(log.off[fourth] == "skin",
		("a step held by a fight left the next minute reading %q, and the skin was off in it")
			:format(tostring(log.off[fourth])))
	check(ns.db.skin == false and ns.db.playerCast == true,
		"a step change happened under combat lockdown")

	_G.InCombatLockdown = realLockdown
	fire("PLAYER_REGEN_ENABLED")
	check(ns.db.skin == true and ns.db.playerCast == false,
		("the fight ended and the held step did not run: skin %s, cast %s")
			:format(tostring(ns.db.skin), tostring(ns.db.playerCast)))

	-- That switch landed in the middle of a minute, so the minute saw both states
	-- and is written as neither.
	local fifth = sweepMinute()
	check(log.off[fifth] == "mixed",
		("the minute a held step change landed in is written as %q"):format(tostring(log.off[fifth])))

	----------------------------------------------------------------------
	-- Stopping, and a run cut short by a reload
	----------------------------------------------------------------------

	ns.Sweep.Word("stop")
	check(ns.db.playerCast == wasCast and ns.db.bars == wasBars and ns.db.skin == wasSkin,
		"stopping the sweep left a feature switched off")
	check(ns.Sweep.Describe() == "not running", "the sweep did not stop")
	check(ns.db.perfSweep == nil, "a stopped sweep left its record in the saved settings")

	local after = sweepMinute()
	check(log.off[after] == "",
		("a minute with no sweep running is written as %q"):format(tostring(log.off[after])))

	-- A logout in the middle of the enemy bars step: the record is in the saved
	-- settings and so is the feature, still off. The way into the world is where
	-- that is put right, because every part has had its login pass by then.
	ns.db.perfSweep = { step = 2, minutes = 5 }
	ns.db.bars = false
	fire("PLAYER_ENTERING_WORLD")
	check(ns.db.bars == true,
		"a sweep cut short by a reload left the enemy bars off at the next login")
	check(ns.db.perfSweep == nil,
		"the interrupted run was put right and its record was left behind")

	print(("sweep  five minutes of it read %s, %s, %s, %s, %s; the fourth is a step waiting for a fight"
		.. " to end, the fifth is the minute it landed in, and every feature was back on after")
		:format(log.off[first], log.off[second], log.off[third], log.off[fourth], log.off[fifth]))
end

----------------------------------------------------------------------
-- What the recorder costs
--
-- It runs on every frame, so this is the measurement that matters more than
-- any number it reports. The gate is the one every ticker in this addon is
-- held to.
----------------------------------------------------------------------

local function churn(ticks)
	collectgarbage("collect")
	collectgarbage("stop")
	local held = collectgarbage("count")
	for _ = 1, ticks do
		frame:Beat(0.016)
	end
	local grew = collectgarbage("count") - held
	collectgarbage("restart")
	return grew
end

-- A bracket weighs the heap either side of its tick, and only a rise counts.
do
	ns.Perf.Allocated()
	collectgarbage("collect")
	collectgarbage("stop")
	ns.Perf.Start("bags")
	local made = {}
	for index = 1, 200 do
		made[index] = {}
	end
	ns.Perf.Stop("bags")
	collectgarbage("restart")
	local bracketed, bracketKey, bracketKB = ns.Perf.Allocated()
	check(bracketKey == "bags" and bracketKB > 5 and bracketed >= bracketKB,
		("200 tables made inside the bags bracket read as %s at %s KB of %s")
			:format(tostring(bracketKey), tostring(bracketKB), tostring(bracketed)))
	check(ns.Perf.Allocated() == 0, "reading what the brackets allocated did not clear it")

	-- And the recorder weighs it across a frame, whoever made it, which is the row
	-- the window shows live.
	collectgarbage("collect")
	collectgarbage("stop")
	frame:Beat(0.016)
	local junk = {}
	for index = 1, 200 do
		junk[index] = {}
	end
	frame:Beat(0.016)
	collectgarbage("restart")
	check(Trace.Second().made > 5,
		("200 tables made between two frames read as %.2f KB made in the second")
			:format(Trace.Second().made))
end

churn(200)
local churned = churn(200)
check(churned < 0.05, ("200 recorded frames allocated %.2f KB"):format(churned))

----------------------------------------------------------------------
-- The window
----------------------------------------------------------------------

local Hud = ns.PerfHud
check(not Hud.IsShown(), "the performance window was open before anything asked for it")
Hud.Open()
check(Hud.IsShown(), "the window did not open")

-- On the window's own frame rather than on ns.UI.Forever, which is what makes
-- the repaint stop when the window is shut, so it is asked for by that frame.
local hud = ns.UI.Ticking("hud", Hud.Frame())
check(hud ~= nil, "the window armed no repaint")
hud:Beat(0.2)

local drawn = 0
for index = 1, Trace.Window() do
	if Trace.Column(index) then
		drawn = drawn + 1
	end
end
check(drawn > 200, ("the strip has %d columns of frames and the ring holds 240"):format(drawn))

Hud.Close()
check(not Hud.IsShown(), "the window did not close")
check(Trace.Watching(), "closing the window stopped a trace the setting asked to keep running")

-- And the way out nothing in this file calls. Escape hides the frame through
-- UISpecialFrames without going near Hud.Close, so the hook on OnHide is the
-- only thing that stops the repaint and puts the trace back where the setting
-- wants it. Driven by hiding the frame, which is all Escape does.
ns.db.perfWatch = false
Hud.Open()
check(Trace.Watching(), "the window did not start the trace it needs to draw anything")
Hud.Frame():Hide()
check(not Trace.Watching(),
	"a window closed with Escape left the trace running with the setting off")
ns.db.perfWatch = true

----------------------------------------------------------------------
-- The key
----------------------------------------------------------------------

check(ns.db.perfKey == "CTRL-R", ("the window opens on %s"):format(tostring(ns.db.perfKey)))
check(ns.PerfKey.Describe():match("^CTRL%-R"),
	("the key reads %q"):format(ns.PerfKey.Describe()))

----------------------------------------------------------------------
-- Put the client back the way it was found
----------------------------------------------------------------------

_G.GetScriptCPUUsage, _G.GetNumAddOns, _G.GetAddOnInfo = nil, nil, nil
_G.GetAddOnCPUUsage, _G.UpdateAddOnCPUUsage = nil, nil
_G.EnumerateFrames = nil
_G.GetAddOnMemoryUsage, _G.UpdateAddOnMemoryUsage = clientUsage, clientUpdate
_G.SetCVar("scriptProfile", "0")
Cause.Forget()
Trace.Forget()

print(("trace  %d frames a ring, %d dips kept, %.2f KB per 200 frames, four answers: %s")
	:format(Trace.Window(), kept, churned, "Lua, the collector, an event storm, the client"))
