local ADDON, ns = ...

local Trace = {}
ns.Trace = Trace

--------------------------------------------------------------------------
-- Every frame, timed
--
-- The client's own Ctrl-R draws a frame rate, which is an average, and an
-- average is the one number that cannot show you a stutter: sixty frames where
-- one of them took 200 ms still reads as 55 fps. What you felt was the 200.
--
-- So this keeps the frames themselves. One tick at an interval of zero runs on
-- every frame the client draws, writes how long that frame took into a ring of
-- four seconds, and asks Perf/Cause.lua to explain the ones that went wrong.
-- The window next door draws the ring as a strip and the explanations as a log.
--
-- **Nothing here allocates.** The ring is eight arrays sized once at load and
-- written in place forever after, because a table per frame on the one tick in
-- the addon that runs every frame is exactly the fault this part exists to
-- find. The one string built is the sentence under a dip, and a dip is a frame
-- that already went wrong.
--
-- **It costs about as much as it can see.** Six client calls a frame, one of
-- which is a table read. The tick brackets itself under the "frame" slot like
-- every other tick in the addon, so the performance tab reports what watching
-- costs on the same page as everything it is watching. A measurement that will
-- not account for itself is asking to be believed rather than read.
--
-- **The recorder runs while the window is shut.** That is the whole point of
-- it. A dip you can reproduce on demand is not the dip anybody is asking about,
-- and a tool you have to have open before the thing happens is a tool for the
-- second time it happens. Perf/Feature.lua carries the switch.
--------------------------------------------------------------------------

-- Frames kept. Four seconds at 60 and rather less at 144, which is the right
-- trade: the strip is for the shape of the last few seconds, and the dip log
-- below it is what remembers further back.
local WINDOW = 240

-- Dips kept, newest first. Eight is what the window has room for, and a ninth
-- dip on screen is a list you scroll rather than a thing you read.
local DIPS = 8

-- A frame under this is not a dip whatever the setting says. Below 20 ms every
-- frame at 60 Hz that misses vsync once is a dip, the log fills with noise, and
-- the one 300 ms stall you were looking for is off the end of it.
local DIP_FLOOR = 20

-- How long after a loading screen a frame is still the loading screen. The
-- client draws one enormous frame on the way back into the world and it is not
-- a stall, so a second of them are marked rather than counted.
local AFTER_LOADING = 1.0

local ms, lua, ours, events = {}, {}, {}, {}
-- KB the heap rose across the frame, zero for a frame it fell across. The minute
-- log of 2026-09-17 put every addon together at 450 to 600 MB made a minute and
-- this addon's own tickers at under 6 of it, so the window shows the figure
-- live: a feature switched off either moves it within the second or did not
-- make it.
local made = {}
local at, filled = 0, 0
for index = 1, WINDOW do
	ms[index], lua[index], ours[index], events[index], made[index] = 0, nil, 0, 0, 0
end

local dipMs, dipAt, dipCause = {}, {}, {}
local dips = 0

-- The one record a dip is described by, filled in place and handed to
-- Perf/Cause.lua. One table for the session rather than one per dip.
local dip = {
	ms = 0, lua = nil, ours = 0, ourKey = nil,
	events = 0, event = nil, eventCount = 0,
	freed = 0, loading = false,
}

-- The last second, filled by Trace.Second and handed out rather than built.
-- One table for the session: the window asks ten times a second.
local second = {
	frames = 0, worst = 0, average = 0,
	lua = 0, ours = 0, events = 0, span = 0, made = 0,
}

local watching = false
local ticker
local lastHeap = nil
local lastLines = 0     -- combat log lines at the last frame
local sinceMark = 0     -- seconds since Perf/Cause.lua took its baseline
local loadingUntil = 0  -- the client's clock, up to which frames are a load

--------------------------------------------------------------------------
-- A minute of frames, kept past the reload
--
-- The ring above holds four seconds, the dip log holds frames over 20 ms, and a
-- reload empties both. None of that can see a session that gets slower. On a
-- 100 Hz panel with vsync on, the frames that pull the rate down are 10 to 20 ms
-- ones missing a deadline, and the question is whether minute sixty has more of
-- them than minute five. So each minute is summed into one row of
-- WiggleUIDB.perfLog, and the client writes it to disk on a reload or a
-- logout.
--
-- The row is a set of parallel columns made full length at login and written in
-- place. Roll is reached from Beat, and Beat allocates nothing. Three hours of
-- rows, the oldest overwritten.
--------------------------------------------------------------------------

local MINUTE = 60
local MINUTES = 180

-- Twelve is a frame that missed a 100 Hz deadline, twenty one that missed 60 Hz,
-- fifty a stall.
local SLOW, SLOWER, STALL = 12, 20, 50

-- at      the wall clock the minute ended, from time()
-- up      minutes since this session started watching
-- lua     milliseconds of Lua, or -1 with the profiler off
-- heap    every addon's Lua heap in KB at the end of the minute
-- freed   KB the collector gave back during it
--
-- The rest are Perf/Held.lua's, and they are what a reload throws away that
-- none of the columns above can see. The four ui columns are the last whole
-- pass of the frame walk, or -1 before one has finished. A row written before
-- these columns existed reads 0 in all of them.
--
-- uiFrames   frames the client holds
-- uiShown    how many of those are visible
-- uiRegions  textures and font strings on the visible ones
-- uiTicking  visible frames with an OnUpdate, Lua on every frame that the
--            profiler-off client names nobody for
-- grower     the addon whose memory rose most across the minute, "" for none
-- grew       by how many KB
-- readMs     what the memory reading cost, or -1 where the client refused it
--
-- And two that answer the one question the rest of the row cannot. A session
-- that gets slower with the tickers flat, the events flat and the frame count
-- flat is a session whose live set is growing, and neither heap nor grew can
-- see that: both are single samples of a number the collector swings by tens of
-- megabytes between one reading and the next.
--
-- floor      the smallest the whole client's heap got at any point in the
--            minute, in KB. Garbage is what a collection gives back, so the
--            low water mark of a minute is close to what was actually live in
--            it, and a floor that climbs minute on minute is a leak whatever
--            the peaks do. Free: Perf/Trace.lua already reads the heap on
--            every frame for the freed column.
-- oursKB     this addon's own heap at the end of the minute, from the reading
--            Perf/Held.lua already takes for grower and used to throw away.
--            Noisier than floor and the only one of the two that names us.
--
-- The plateau those two found is one frame in ten over 12 ms, 570 a minute, from
-- minute 21 of a session on 2026-09-17 with the floor at 169 MB. The columns
-- above count those frames and say nothing about them, so these describe them.
-- Each is a sum over the frames at or over 12 ms, to be read against over12.
--
-- slowMs      how long those frames took in all, so slowMs / over12 is the
--             length of a slow frame
-- slowOurs    what this addon's tickers took inside them. Near ours / frames
--             each and the cost is not in a bracket of ours
-- slowKey     the ticker that was most often the dearest in them, "" for none
-- slowEvents  events that landed in them
-- slowAlloc   KB the heap rose across them. A slow frame carrying many times
--             the allocation of an ordinary one is somebody's burst, and the
--             collector paying for it in the same frame
-- slowSweeps  how many of them saw the heap fall, which is a collection giving
--             memory back inside the frame
-- beat        how many of them came 80 to 120 ms after the one before. Near
--             over12 and it is a ten a second timer. Near a tenth of it and
--             the frames are arriving at random
--
-- And what they are read against, summed over every frame of the minute.
--
-- alloc       KB the heap rose, which with freed is the churn of the whole client
-- sweeps      frames that saw the heap fall
-- oursAlloc   KB this addon's tickers allocated inside their own brackets, from
--             Perf/Perf.lua, -1 with tick timing off
-- allocKey    the ticker that allocated most of it, "" for none
-- allocKB     and how much that one made
-- addonsKB    every addon's heap summed at the end of the minute. floor less
--             this is roughly the client's own interface code
--
-- And one column that is not a measurement at all.
--
-- off         what Perf/Sweep.lua had switched off for the whole of the minute:
--             the name of one feature, "base" for a baseline step, "" with no
--             sweep running, and "mixed" for a minute a step change had to
--             happen in the middle of because the client was in a fight. Read
--             it as the column the rest of the row is grouped by. The sweep is
--             driven from the roll below rather than from a clock of its own,
--             so every other row is entirely one state.
--
-- And three out of Questie, from Perf/Probe.lua, which says why it is asked.
--
-- qQueued     how many times anything asked QuestieCombatQueue to run something.
--             It can take 3600 a minute off out of a fight and none in one
-- qPins       minimap pins HereBeDragons held for it at the end of the minute
-- qMapPins    and world map pins. All three are -1 with no Questie to ask
--
-- And which events the count in `events` was made of, from Perf/Census.lua.
--
-- topEvent    the event the client sent most in the minute, "" for none
-- topEvents   how many of it. Near `frames` and it is arriving on every frame
-- nextEvent   the runner up, and nextEvents how many
--
-- And one column per addon holding over 2 MB, under log.addons by name rather
-- than in the list below, because which addons those are is not known until the
-- client has been asked. oursKB said the leak was not ours, and the same lower
-- envelope read off every other addon is what says whose it is.
local COLUMNS = { "at", "up", "frames", "avg", "worst", "over12", "over20",
	"over50", "lua", "ours", "events", "heap", "freed",
	"uiFrames", "uiShown", "uiRegions", "uiTicking", "grower", "grew", "readMs",
	"floor", "oursKB",
	"slowMs", "slowOurs", "slowKey", "slowEvents", "slowAlloc", "slowSweeps", "beat",
	"alloc", "sweeps", "oursAlloc", "allocKey", "allocKB", "addonsKB",
	"qQueued", "qPins", "qMapPins",
	"topEvent", "topEvents", "nextEvent", "nextEvents",
	"off" }

-- The columns that hold a name rather than a number.
local TEXT = { grower = true, slowKey = true, allocKey = true, topEvent = true, nextEvent = true, off = true }

-- An addon under this many KB gets no column of its own. Forty addons at 180
-- rows each is a saved file nobody opens, and a leak worth a column is over
-- this within minutes of starting.
local BIG = 2048

-- A slow frame this long after the last one, in ms, is on a ten a second beat.
local BEAT_LOW, BEAT_HIGH = 80, 120

local minute = {
	span = 0, frames = 0, total = 0, worst = 0, slow = 0, slower = 0, stall = 0,
	lua = 0, profiled = false, ours = 0, events = 0, freed = 0, floor = 0,
	slowMs = 0, slowOurs = 0, slowEvents = 0, slowAlloc = 0, slowSweeps = 0,
	beat = 0, alloc = 0, sweeps = 0,
}

-- Ticker key -> how many slow frames of this minute it was the dearest in. Set
-- back to zero at the roll rather than wiped, so a key seen once is a slot that
-- is never made again.
local slowKeys = {}
local sinceSlow = 0     -- ms of frames since the last slow one, that one included
local saved             -- WiggleUIDB.perfLog once Ready has made it whole
local startedAt = 0     -- the client's clock when watching began
local reading = false   -- the roll just read addon memory, and the next frame pays for it

local function Empty()
	minute.span, minute.frames, minute.total, minute.worst = 0, 0, 0, 0
	minute.slow, minute.slower, minute.stall = 0, 0, 0
	minute.lua, minute.profiled, minute.ours, minute.events, minute.freed = 0, false, 0, 0, 0
	-- Zero is "nothing seen yet" rather than a reading: the first frame of the
	-- minute takes it, and every frame after only lowers it.
	minute.floor = 0
	minute.slowMs, minute.slowOurs, minute.slowEvents = 0, 0, 0
	minute.slowAlloc, minute.slowSweeps, minute.beat = 0, 0, 0
	minute.alloc, minute.sweeps = 0, 0
	for key in pairs(slowKeys) do
		slowKeys[key] = 0
	end
end

-- A column at full length, which is the one allocation the log makes and it
-- makes it once per column.
local function Fill(column, blank)
	for row = #column + 1, MINUTES do
		column[row] = blank
	end
	return column
end

-- A column for every addon Perf/Held.lua has read at over BIG. Run at login,
-- where there is usually no reading yet, and again at every roll, where the
-- reading is a second old. An addon is met once, so all but a handful of rolls
-- find every column already there.
local function AddonColumns(log)
	for index = 1, ns.Held.Listed() do
		local name, kb = ns.Held.Addon(index)
		if name and kb >= BIG and not log.addons[name] then
			log.addons[name] = Fill({}, 0)
		end
	end
end

-- The saved log with every column at full length. A missing log, or one written
-- at another size, is started again rather than resized.
local function Ready()
	local log = ns.db.perfLog
	if type(log) ~= "table" or log.size ~= MINUTES then
		log = { size = MINUTES, head = 0, filled = 0 }
		ns.db.perfLog = log
	end
	for index = 1, #COLUMNS do
		local name = COLUMNS[index]
		if type(log[name]) ~= "table" then
			log[name] = {}
		end
		Fill(log[name], TEXT[name] and "" or 0)
	end
	if type(log.addons) ~= "table" then
		log.addons = {}
	end
	for _, column in pairs(log.addons) do
		Fill(column, 0)
	end
	AddonColumns(log)
	ns.Probe.Hang()
	saved = log
	return log
end

local function Hundredths(value)
	return math.floor(value * 100 + 0.5) / 100
end

-- The ticker that was the dearest in most of the minute's slow frames.
local function SlowKey()
	local most, mostKey = 0, ""
	for key, count in pairs(slowKeys) do
		if count > most then
			most, mostKey = count, key
		end
	end
	return mostKey
end

-- The half of a row that describes the slow frames and the allocation.
local function RollSlow(log, row)
	log.slowMs[row] = Hundredths(minute.slowMs)
	log.slowOurs[row] = Hundredths(minute.slowOurs)
	log.slowKey[row] = SlowKey()
	log.slowEvents[row] = minute.slowEvents
	log.slowAlloc[row] = math.floor(minute.slowAlloc + 0.5)
	log.slowSweeps[row] = minute.slowSweeps
	log.beat[row] = minute.beat
	log.alloc[row] = math.floor(minute.alloc + 0.5)
	log.sweeps[row] = minute.sweeps

	local total, key, most = ns.Perf.Allocated()
	local timed = ns.db.perf and true or false
	log.oursAlloc[row] = timed and math.floor(total + 0.5) or -1
	log.allocKey[row] = key or ""
	log.allocKB[row] = math.floor(most + 0.5)
end

-- The half that is one figure per addon. Every column is zeroed at this row
-- first, because the row being written over may belong to a session in which an
-- addon that is small now was not.
local function RollAddons(log, row)
	AddonColumns(log)
	for _, column in pairs(log.addons) do
		column[row] = 0
	end
	for index = 1, ns.Held.Listed() do
		local name, kb = ns.Held.Addon(index)
		local column = name and log.addons[name]
		if column then
			column[row] = math.floor(kb + 0.5)
		end
	end
	log.addonsKB[row] = math.floor(ns.Held.All() + 0.5)
end

-- One row written over the oldest, then the minute started again.
local function Roll(log)
	local row = log.head % MINUTES + 1
	log.head = row
	if log.filled < MINUTES then
		log.filled = log.filled + 1
	end
	local now = GetTime and GetTime() or 0
	log.at[row] = time and time() or 0
	log.up[row] = math.floor((now - startedAt) / MINUTE + 0.5)
	log.frames[row] = minute.frames
	log.avg[row] = Hundredths(minute.frames > 0 and minute.total / minute.frames or 0)
	log.worst[row] = Hundredths(minute.worst)
	log.over12[row] = minute.slow
	log.over20[row] = minute.slower
	log.over50[row] = minute.stall
	log.lua[row] = minute.profiled and Hundredths(minute.lua) or -1
	log.ours[row] = Hundredths(minute.ours)
	log.events[row] = minute.events
	log.heap[row] = math.floor((lastHeap or 0) + 0.5)
	log.freed[row] = math.floor(minute.freed + 0.5)

	local pass = ns.Held.Pass()
	log.uiFrames[row], log.uiShown[row] = pass.frames, pass.shown
	log.uiRegions[row], log.uiTicking[row] = pass.regions, pass.ticking
	ns.Held.Read()
	local grower, grew, readMs = ns.Held.Grower()
	log.grower[row] = grower
	log.grew[row] = math.floor(grew + 0.5)
	log.readMs[row] = (readMs >= 0) and Hundredths(readMs) or -1
	log.floor[row] = math.floor(minute.floor + 0.5)
	log.oursKB[row] = math.floor(ns.Held.Ours() + 0.5)
	-- What the sweep had switched off for the whole of this minute, and the step
	-- change that the end of a minute is the moment for. Asked here rather than
	-- on a clock of its own so that no row is half one state and half another.
	log.off[row] = ns.Sweep.Roll()
	RollSlow(log, row)
	RollAddons(log, row)
	log.qQueued[row], log.qPins[row], log.qMapPins[row] = ns.Probe.Roll()
	log.topEvent[row], log.topEvents[row], log.nextEvent[row], log.nextEvents[row] = ns.Census.Top()
	reading = true
	Empty()
end

--------------------------------------------------------------------------

-- What counts as a dip on this machine, in milliseconds. The setting, floored
-- at a number below which every reading is noise.
local function Threshold()
	local want = ns.db and ns.db.perfDip or 50
	return (want > DIP_FLOOR) and want or DIP_FLOOR
end

-- cold: Record writes one dip down, on the frames that already went wrong,
-- which is not the tick that reached it. Everything under it, the ranking of
-- addons and the sentence built out of it, belongs to that frame and not to the
-- sixty a second either side.
local function Record(took, ourMs, ourKey, count, event, most, freed)
	dip.ms = took
	-- The column Beat has just written, which is this frame. Read back rather
	-- than passed, because a dip is described by eight numbers and a function
	-- taking eight arguments is a function whose call site nobody can read.
	dip.lua = lua[at]
	dip.ours = ourMs
	dip.ourKey = ourKey
	dip.events = count
	dip.event = event
	dip.eventCount = most
	dip.freed = freed
	dip.loading = false

	for index = DIPS, 2, -1 do
		dipMs[index], dipAt[index], dipCause[index] =
			dipMs[index - 1], dipAt[index - 1], dipCause[index - 1]
	end
	dipMs[1] = took
	dipAt[1] = GetTime and GetTime() or 0
	dipCause[1] = ns.Cause.Explain(dip)
	if dips < DIPS then
		dips = dips + 1
	end
end

-- A slow frame, summed into the columns that describe one. Read off the ring
-- at the column Beat has just written, for the reason Record reads it there.
local function TallySlow(took, rose, ourKey)
	minute.slow = minute.slow + 1
	minute.slowMs = minute.slowMs + took
	minute.slowOurs = minute.slowOurs + ours[at]
	minute.slowEvents = minute.slowEvents + events[at]
	if rose > 0 then
		minute.slowAlloc = minute.slowAlloc + rose
	elseif rose < 0 then
		minute.slowSweeps = minute.slowSweeps + 1
	end
	if sinceSlow >= BEAT_LOW and sinceSlow <= BEAT_HIGH then
		minute.beat = minute.beat + 1
	end
	sinceSlow = 0
	if ourKey then
		slowKeys[ourKey] = (slowKeys[ourKey] or 0) + 1
	end
	if took >= SLOWER then
		minute.slower = minute.slower + 1
		if took >= STALL then
			minute.stall = minute.stall + 1
		end
	end
end

-- One counted frame into the minute. `freed` is how far the heap fell across
-- the frame, so a negative one is how far it rose.
local function Tally(freed, ourKey)
	local took, luaMs = ms[at], lua[at]
	minute.frames = minute.frames + 1
	minute.total = minute.total + took
	if took > minute.worst then
		minute.worst = took
	end
	sinceSlow = sinceSlow + took
	if took >= SLOW then
		TallySlow(took, -freed, ourKey)
	end
	if luaMs then
		minute.lua = minute.lua + luaMs
		minute.profiled = true
	end
	minute.ours = minute.ours + ours[at]
	minute.events = minute.events + events[at]
	if minute.floor == 0 or lastHeap < minute.floor then
		minute.floor = lastHeap
	end
	if freed > 0 then
		minute.freed = minute.freed + freed
		minute.sweeps = minute.sweeps + 1
	elseif freed < 0 then
		minute.alloc = minute.alloc - freed
	end
end

-- One frame. Everything above is what this function is allowed to cost.
local function Beat(since)
	local took = since * 1000
	local afterRead = reading
	reading = false
	ns.Held.Walk()
	local ourMs, _, ourKey = ns.Perf.FrameCost()
	local luaMs = ns.Cause.LuaSince()
	local count, event, most = ns.Census.Take()

	-- The combat log, folded in from the one place this addon reads it. See the
	-- header of Perf/Census.lua for why it is not counted with the rest.
	local lines = ns.CombatLog.Lines()
	local said = lines - lastLines
	lastLines = lines
	count = count + said
	if said > most then
		most = said
		event = "COMBAT_LOG_EVENT_UNFILTERED"
	end

	local heap = collectgarbage("count")
	local freed = lastHeap and (lastHeap - heap) or 0
	lastHeap = heap

	at = at % WINDOW + 1
	ms[at], lua[at], ours[at], events[at] = took, luaMs, ourMs, count
	made[at] = (freed < 0) and -freed or 0
	if filled < WINDOW then
		filled = filled + 1
	end

	-- The baseline every per addon figure is measured against, moved on once a
	-- second. It walks every addon the client has loaded, which is why it is not
	-- on the frame.
	sinceMark = sinceMark + since
	if sinceMark >= 1 then
		sinceMark = 0
		-- Ranked before the baseline moves, so the ranking is the second that
		-- has just gone rather than the one starting now.
		ns.Cause.Rank()
		ns.Cause.Mark()
	end

	-- The frame after a memory reading is that reading, and it is the recorder's
	-- own cost rather than a stall, so it is kept out the way a load is.
	local loading = afterRead or (GetTime and GetTime() or 0) < loadingUntil
	if took >= Threshold() and not loading then
		Record(took, ourMs, ourKey, count, event, most, freed)
	end

	-- The minute. A loading frame moves the clock on and is not counted, for the
	-- reason it is not a dip.
	if not loading then
		Tally(freed, ourKey)
	end
	minute.span = minute.span + since
	if minute.span >= MINUTE and saved then
		Roll(saved)
	end
end

--------------------------------------------------------------------------
-- Reading it back
--------------------------------------------------------------------------

function Trace.Window()
	return WINDOW
end

-- Where the newest frame was written. The strip is drawn as a ring rather than
-- scrolled, so one column changes per frame instead of two hundred and forty.
function Trace.Head()
	return at
end

-- One column: how long that frame took, and how much of it was Lua. Nothing at
-- all for a column nothing has been written to yet.
function Trace.Column(index)
	if index > filled then
		return nil
	end
	return ms[index], lua[index], ours[index], events[index]
end

-- The last second, as one record: how many frames, the longest one, the
-- average, the milliseconds of Lua in them, what this addon's own tickers took,
-- how many events landed, how many KB of Lua memory every addon made between
-- them, and how much wall clock the lot covers.
--
-- Walked backwards from the newest frame until a second is accounted for, so
-- the answer is a second of wall clock rather than a fixed number of frames.
-- The last frame counted takes the total past the second rather than stopping
-- short of it, because a stop-short on a machine drawing one frame a second
-- answers with nothing at all, which is the reading that matters most.
--
-- Filled in place and handed back, because the window asks for it ten times a
-- second and seven return values at that call site is a line nobody can read.
function Trace.Second()
	local total, worst, count = 0, 0, 0
	second.lua, second.ours, second.events, second.made = 0, 0, 0, 0

	local index = at
	for _ = 1, filled do
		local took = ms[index]
		total = total + took
		count = count + 1
		if took > worst then
			worst = took
		end
		second.lua = second.lua + (lua[index] or 0)
		second.ours = second.ours + ours[index]
		second.events = second.events + events[index]
		second.made = second.made + made[index]
		index = (index == 1) and WINDOW or (index - 1)
		if total >= 1000 then
			break
		end
	end

	second.frames = count
	second.worst = worst
	second.span = total
	second.average = (count > 0) and (total / count) or 0
	return second
end

-- Every addon's Lua heap in kilobytes, as the last frame read it. The client's
-- own number rather than a walk over the addon list: the collector does not
-- care whose objects they are, and this is what it is going to walk.
function Trace.Heap()
	return lastHeap or 0
end

function Trace.Dips()
	return dips
end

-- One dip, newest first: how long ago, how long it was, and why.
function Trace.Dip(index)
	if index > dips then
		return nil
	end
	local now = GetTime and GetTime() or 0
	return now - (dipAt[index] or now), dipMs[index], dipCause[index]
end

function Trace.Forget()
	for index = 1, WINDOW do
		ms[index], lua[index], ours[index], events[index], made[index] = 0, nil, 0, 0, 0
	end
	at, filled, dips = 0, 0, 0
	lastHeap = nil
	sinceSlow = 0
	-- The minute in progress, and not the saved rows: those are the log of
	-- sessions gone, and clearing counters is about this one.
	Empty()
	ns.Cause.Forget()
	ns.Census.Forget()
end

--------------------------------------------------------------------------

-- Two events and one frame.
--
-- The frames the client draws on the way back into the world are not stalls,
-- and the first of them can be several seconds long. Marked rather than
-- counted, so the log holds what went wrong while you were playing.
--
-- Login is where the recorder starts, if the setting says it should. It is the
-- one part of this feature that costs anything with nothing on screen, so it is
-- the one part that asks.
local loads = CreateFrame("Frame")
loads:RegisterEvent("PLAYER_ENTERING_WORLD")
loads:RegisterEvent("PLAYER_LOGIN")
loads:SetScript("OnEvent", function(_, event)
	loadingUntil = (GetTime and GetTime() or 0) + AFTER_LOADING
	if event == "PLAYER_LOGIN" and ns.db.perfWatch then
		Trace.Watch(true)
	end
end)

function Trace.Watch(on)
	if watching == on then
		return watching
	end
	watching = on

	if on then
		lastHeap = nil
		lastLines = ns.CombatLog.Lines()
		sinceMark = 0
		Ready()
		Empty()
		startedAt = GetTime and GetTime() or 0
		ns.Cause.Forget()
		ns.Cause.Mark()
		ns.Census.Watch(true)
		if ticker then
			ticker:Start()
		else
			ticker = ns.UI.Ticker(ns.UI.Forever, 0, "frame", Beat)
		end
	else
		ns.Census.Watch(false)
		if ticker then
			ticker:Stop()
		end
	end
	return watching
end

function Trace.Watching()
	return watching
end

-- What the recorder is doing, as the line the page reads.
function Trace.Describe()
	if not watching then
		return "not watching"
	end
	local last = Trace.Second()
	if last.frames == 0 then
		return "watching, nothing timed yet"
	end
	return ("watching, %d frames in the last second, worst %.0f ms, %d dip%s kept")
		:format(last.frames, last.worst, dips, dips == 1 and "" or "s")
end
