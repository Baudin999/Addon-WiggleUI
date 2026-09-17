local ADDON, ns = ...

local Probe = {}
ns.Probe = Probe

--------------------------------------------------------------------------
-- Two counts out of Questie, for one question
--
-- The session of 2026-09-17 from 14:49 ran 39 minutes with the new columns on.
-- By minute 36 there were 582 frames over 12 ms and 576 of them came 80 to 120 ms
-- after the one before, so the slow frames are a ten a second timer. They held
-- 0.11 ms of this addon's tickers each, 100 KB of allocation each, which is what
-- an ordinary frame makes, and 13 of the 582 saw the collector give anything
-- back. So it is not ours, not a burst of garbage and not the collector. A slow
-- frame was 12.6 ms at minute 18 and 21.4 ms at minute 36, so the timer's work
-- grows with the session, and across the same minutes Questie's own heap went
-- from 53 MB to 108 MB while every other addon's stayed flat.
--
-- Questie runs two timers at that rate whatever you are doing, and each walks
-- something that can grow:
--
--   QuestieCombatQueue   takes up to six entries off the front of a list with
--                        tremove(list, 1), which moves every entry left behind.
--                        Fed faster than six a tick, the list is the leak and
--                        the shifting is the cost, and both grow in a line.
--   QuestieMap           resumes a walk over HereBeDragons' active minimap
--                        pins, fifty a tick.
--
-- Neither list can be reached from outside, so this counts what feeds them. How
-- many times a minute anything asks the combat queue to run something, read
-- against the 3600 a minute it can take off out of a fight. And how many pins
-- the two pin tables hold at the end of the minute.
--
-- The count is a wrapper over QuestieCombatQueue.Queue, the way Quests/Party.lua
-- wraps ScheduleUpdate: Questie's callers reach it as a method on the module
-- table, so they find the wrapper at the call. It adds one and calls through.
--------------------------------------------------------------------------

local PINS = "HereBeDragonsQuestie-Pins-2.0"

local hung = false
local queued = 0
local original          -- Questie's own Queue, once the wrapper is over it

-- File scope rather than a closure made in Hang, so there is one of it and the
-- roll that reaches this file makes nothing.
local function Counted(...)
	queued = queued + 1
	return original(...)
end

-- Put on once, where Perf/Trace.lua makes its log ready, which is login or the
-- window opening. Questie sorts before this addon and has loaded by then. Not
-- from the roll: asking Questie's loader for a module is a call into another
-- addon, and once a minute for a session is sixty askings too many.
function Probe.Hang()
	if hung then
		return
	end
	local queue = ns.Questie("QuestieCombatQueue", "Queue")
	if queue then
		original = queue.Queue
		queue.Queue = Counted
		hung = true
	end
end

local function Count(held)
	if type(held) ~= "table" then
		return -1
	end
	local count = 0
	for _ in pairs(held) do
		count = count + 1
	end
	return count
end

-- The minute's three figures, from Perf/Trace.lua's roll, and the count started
-- again. -1 for a figure Questie is not there to give.
function Probe.Roll()
	local asked = hung and queued or -1
	queued = 0
	local lib = _G.LibStub and _G.LibStub(PINS, true)
	if type(lib) ~= "table" then
		return asked, -1, -1
	end
	return asked, Count(lib.activeMinimapPins), Count(lib.worldmapPins)
end
