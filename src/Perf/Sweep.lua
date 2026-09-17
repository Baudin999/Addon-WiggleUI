local ADDON, ns = ...

local Sweep = {}
ns.Sweep = Sweep

--------------------------------------------------------------------------
-- One feature off at a time, five minutes each
--
-- The minute log next door says the whole client makes 450 to 600 MB of Lua
-- garbage a minute, about 100 KB on every frame, and that this addon's own
-- ticker brackets account for under 1% of it. The same log says the client
-- bills this addon's heap with a 16 to 54 MB swing inside one minute. Both are
-- true and reading the source has not reconciled them. scripts/check.sh already
-- refuses a table, a closure and a built string on every path a ticker reaches,
-- so what is left is an event handler nothing marks or a client call that
-- answers with a fresh table, and neither of those shows up in the text.
--
-- So this measures it instead of reading it. The sweep switches one feature
-- off, leaves it off for a fixed number of minutes, switches it back on and
-- moves to the next. Exactly one is off at a time. Perf/Trace.lua writes the
-- name of whatever is off into the `off` column of every row, so afterwards the
-- log splits on that column and the question becomes arithmetic: the step whose
-- alloc and oursKB fall is the step that was making them.
--
-- **The steps change at the minute roll and nowhere else.** A switch halfway
-- through a minute writes a row that is half one state and half the other,
-- which is exactly the row the reading turns on. Perf/Trace.lua's Roll calls
-- Sweep.Roll, takes the label for the minute that has just ended, and the step
-- change happens after it. Every row is one state.
--
-- **A baseline at each end.** Without one there is nothing for the eight
-- feature steps to be read against. With only one at the start there is no way
-- to tell a feature that costs nothing from a session that had already got
-- worse by the time that feature's step came round, and the session getting
-- worse on its own is the thing this whole part exists to chase.
--
-- **Nothing is switched under combat lockdown.** Half the list owns secure
-- frames, and changing one of those in a fight is either refused by the client
-- or taints the button. A step that comes due mid fight is held, the minute it
-- was due in is written with what was really off in it rather than with what
-- the schedule wanted, and the switch happens at PLAYER_REGEN_ENABLED. That one
-- lands in the middle of a minute, so that minute is written as `mixed` and is
-- a row to drop.
--
-- **It always puts the feature back.** A feature the player already had off is
-- skipped rather than switched on, each step restores before the next one is
-- switched, and the stop word restores. A reload or a logout mid run would
-- otherwise leave one feature off in the saved settings with nothing to say
-- why, so the run writes itself into ns.db.perfSweep as it goes and the next
-- trip into the world finds it, puts the feature back and says which one it was.
--------------------------------------------------------------------------

-- Minutes one step lasts out of the box, and the range the slash word takes.
-- Five is three clean rows either side of the two the switch itself disturbs,
-- and ten steps of five is fifty minutes, which is past the minute 21 to 27
-- where the sessions of 2026-09-17 reached their plateau.
local MINUTES, LOW, HIGH = 5, 1, 30

-- What a row says during a baseline step, and what it says for the one minute a
-- held step change landed in the middle of. Both are distinct from "", which is
-- what a row written with no sweep running says.
local BASE, MIXED = "base", "mixed"

-- The experiment's design, which is this table rather than the code under it.
-- Each entry is one feature on an expected hot path, the slash word that
-- switches it and the setting that word writes, and the comment above it is why
-- that feature is on the list. The list was read off the ticker roots
-- scripts/hot.lua derives, ORDER in Perf/Perf.lua, and which parts register for
-- the combat log, for UNIT_AURA and for the nameplate events.
--
-- A feature is here only if the addon can switch it off while it is running.
-- Core/BlizzHide.lua's frames, the quest column and the bag, mail and merchant
-- windows are all switchable and none of them is on this list: an event that
-- arrives when a window is opened is not what makes 100 KB on a frame nobody
-- opened anything on.
local STEPS = {
	-- Nothing off. What the eight below are read against.
	{ label = BASE, word = "", key = "" },

	-- The heaviest part of the addon by every measure the log has. A widget per
	-- nameplate, a tick on every frame filling cast bars and running arrival
	-- ramps, and UNIT_AURA, UNIT_HEALTH and UNIT_POWER_UPDATE registered once
	-- per plate on top of NAME_PLATE_UNIT_ADDED and REMOVED.
	{ label = "bars", said = "the enemy nameplate bars", word = "bars",
	  key = "bars", off = "off", on = "on" },

	-- The player, target and target of target frames. The same three unit
	-- events again, once per frame skinned, and two polls: a fast one over what
	-- the client said moved and a full reading of everything once a second.
	{ label = "skin", said = "the unit frame skin", word = "skin",
	  key = "skin", off = "off", on = "on" },

	-- Your own cast bar. A sweep on every frame and ten UNIT_SPELLCAST_ events,
	-- and the sweep is armed whether or not anything is casting.
	{ label = "cast", said = "your own cast bar", word = "cast",
	  key = "playerCast", off = "off", on = "on" },

	-- allocKey named `action` in nearly every minute of the 14:25 session on
	-- 2026-09-17, at 0.8 to 4 MB, which is a ticker allocating on a path
	-- scripts/check.sh says allocates nothing. It is also the one step here
	-- that owns secure buttons, so it is the one the combat hold is for.
	{ label = "action", said = "our own action bars", word = "actionbars",
	  key = "actionBars", off = "off", on = "on" },

	-- Drawn on every frame rather than at a rate, and fed by the combat log and
	-- by UNIT_AURA on the player at the same time. Three hot shapes in one part.
	{ label = "swing", said = "the swing timer", word = "swing",
	  key = "swing", off = "off", on = "on" },

	-- Ten times a second, plus a UNIT_AURA handler that Buffs/Upkeep.lua marks
	-- as outrunning its own tick in a fight. The player's auras move constantly
	-- and this reads them every time they do.
	{ label = "buffs", said = "the missing-buff row", word = "buffs",
	  key = "buffs", off = "off", on = "on" },

	-- A combat log subscriber that turns lines into frames. If the megabytes
	-- arrive during a pull, this is the shape that would make them.
	{ label = "hits", said = "the floating combat numbers", word = "hits",
	  key = "hits", off = "off", on = "on" },

	-- The other combat log subscriber, with a window redrawing five times a
	-- second off what it has accumulated.
	{ label = "meter", said = "the meters", word = "meter",
	  key = "meter", off = "off", on = "on" },

	-- Nothing off again, so drift across the run is visible rather than
	-- attributed to whichever feature drew the last step.
	{ label = BASE, word = "", key = "" },
}

-- The run in progress. One table for the session, written in place, because
-- Sweep.Roll is reached from Perf/Trace.lua's tick on every frame.
--
-- `label` is what the minute now ending saw and `after` is what every minute
-- after it will see. The two differ for exactly one minute, the one a held step
-- change landed in the middle of, and that is the whole reason there are two.
local state = {
	running = false,
	index = 0,       -- which step of STEPS, 0 before the first
	left = 0,        -- minutes left in it
	label = "",      -- what was off during the minute now ending
	after = "",      -- and during every minute after that
	held = false,    -- a step change came due under lockdown and is waiting
	minutes = MINUTES,
}

--------------------------------------------------------------------------

-- The slash word handler a step switches its feature by, found in the registry
-- rather than by naming the part. Nothing under Perf/ may name a feature
-- directly: Perf is in the base set scripts/trees.lua closes, so ns.EnemyBars
-- from here is refused and no allow-list entry can excuse it. The registry is
-- Core's, every part writes its own words into it, and calling one is the same
-- door the player's own typing goes through.
local function Handler(word)
	for index = 1, #ns.features do
		local words = ns.features[index].words
		local found = words and words[word]
		if found then
			return found
		end
	end
	return nil
end

-- One step's feature switched. Through the slash word and not through ns.db,
-- because the word writes the setting and then calls that part's own apply,
-- which is what takes its tickers, its events and its hooks down with it.
-- Writing the flag alone would leave all three running and the step would
-- measure nothing.
--
-- Answers whether there was a word to call at all. A feature renamed since this
-- list was written would otherwise leave a step reporting itself as off having
-- changed nothing, which is the one failure that reads as a result.
local function Set(step, on)
	if step.word == "" then
		return true
	end
	local handler = Handler(step.word)
	if not handler then
		return false
	end
	-- Called under pcall because this is reached from the minute roll. A part
	-- that raises while switching would otherwise take the roll down with it
	-- before the minute is emptied, and a minute that is never emptied rolls
	-- again on the next frame and every frame after. The client shows no Lua
	-- errors on this install, so nothing would say so.
	return (pcall(handler, on and step.on or step.off))
end

-- The next step from `from` onward whose feature is actually on. One the player
-- already had switched off says nothing about what it costs while it is off,
-- and switching it on so the sweep can switch it off again would change the
-- session underneath them, so it is skipped.
local function Next(from)
	for index = from, #STEPS do
		local step = STEPS[index]
		if step.key == "" or ns.db[step.key] then
			return index
		end
	end
	return nil
end

-- The one line a step start is worth. Both sentences are built inside a branch
-- because this is reached from the roll, and a step starts once every few
-- minutes rather than once a frame.
local function Say(step, minutes)
	if step.word == "" then
		ns.Print(("sweep: baseline, nothing switched off, for %d minute%s.")
			:format(minutes, minutes == 1 and "" or "s"))
	else
		ns.Print(("sweep: %s off for %d minute%s, and nothing else with it.")
			:format(step.said, minutes, minutes == 1 and "" or "s"))
	end
end

-- The end of the run, from the last step or from the stop word. Whatever is off
-- goes back on first, and the saved record goes with it so the next login has
-- nothing to put right.
local function Finish(said)
	local step = STEPS[state.index]
	if step then
		Set(step, true)
	end
	state.running, state.held = false, false
	state.index, state.left = 0, 0
	state.label, state.after = "", ""
	ns.db.perfSweep = nil
	if said then
		ns.Print(said)
	end
end

-- One step change: the current step restored, the next one switched off. The
-- caller has already decided that this is a moment the client will allow it.
local function Step()
	local step = STEPS[state.index]
	if step then
		Set(step, true)
	end
	local index = Next(state.index + 1)
	if not index then
		Finish("sweep: done. Read the log with scripts/perflog.lua and split the rows on the off column.")
		return
	end
	local coming = STEPS[index]
	state.index = index
	if not Set(coming, false) then
		Finish("sweep: stopped. A step's slash word is missing from this build or raised when it was called.")
		return
	end
	state.left = state.minutes
	state.label, state.after = coming.label, coming.label
	local saved = ns.db.perfSweep
	if saved then
		saved.step = index
	end
	Say(coming, state.minutes)
end

-- A step boundary, held back if the client is in a fight. Held, the minute that
-- follows is another minute of the step that is already running, and the label
-- is left alone so the row says what was really off in it.
local function Advance()
	if InCombatLockdown and InCombatLockdown() then
		-- Said once, on the minute the hold begins. A step that is late with
		-- nothing on screen reads as a sweep that has stopped.
		if not state.held then
			ns.Print("sweep: the next step is due and you are in a fight. It switches when the fight ends.")
		end
		state.held = true
		state.left = 1
		return
	end
	Step()
end

-- The end of a fight, which is when a step change that came due under lockdown
-- is finally allowed. It lands in the middle of a minute, so that minute saw
-- both states and is written as neither of them. The new step gets its full
-- count of clean minutes after it.
local function Regen()
	if not state.running then
		Sweep.Resume()
		return
	end
	if not state.held then
		return
	end
	state.held = false
	Step()
	if state.running then
		state.label = MIXED
		state.left = state.left + 1
	end
end

--------------------------------------------------------------------------

-- What was off during the minute that has just ended, and the step change that
-- the end of a minute is the moment for.
--
-- Perf/Trace.lua's Roll writes what this answers straight into the row, and
-- Roll is reached from the tick on every frame the client draws. So everything
-- is behind the first branch: with no sweep running this is one table read and
-- a string that was made at load.
function Sweep.Roll()
	if not state.running then
		return ""
	end
	local label = state.label
	state.label = state.after
	state.left = state.left - 1
	if state.left <= 0 then
		Advance()
	end
	return label
end

-- Where the run is, as the line the status word and the settings page read.
function Sweep.Describe()
	if not state.running then
		return "not running"
	end
	local step = STEPS[state.index]
	return ("step %d of %d, %s, %d minute%s left%s")
		:format(state.index, #STEPS,
			(step and step.said) or "nothing switched off",
			state.left, state.left == 1 and "" or "s",
			state.held and ", and the next step is waiting for the fight to end" or "")
end

-- An interrupted run, found on the way into the world. The setting lives in the
-- saved variables, so a reload or a logout in the middle of a step leaves that
-- feature off with nothing on screen to say why. Nothing resumes: a run that
-- lost half its rows to a reload is not a run, and the rows it did write are
-- still in the log.
--
-- The run in progress is what the first test is about. This is reached on every
-- zone change as well as at login, because a step switched off ten seconds ago
-- and a step switched off last session look the same in the saved settings and
-- only the state table tells them apart.
function Sweep.Resume()
	local saved = ns.db.perfSweep
	if state.running or type(saved) ~= "table" then
		return
	end
	-- A reload in the middle of a fight comes back in the middle of it. The
	-- record is left where it is and the end of the fight asks again.
	if InCombatLockdown and InCombatLockdown() then
		return
	end
	ns.db.perfSweep = nil
	local step = STEPS[saved.step or 0]
	if not step or step.key == "" then
		ns.Print("sweep: a run was cut short by a reload. Nothing of yours was switched off at the time.")
		return
	end
	if ns.db[step.key] then
		ns.Print(("sweep: a run was cut short by a reload. %s was already back on."):format(step.said))
		return
	end
	Set(step, true)
	ns.Print(("sweep: a run was cut short by a reload with %s off. It is back on, and nothing is running now.")
		:format(step.said))
end

local function Start(minutes)
	if not ns.Trace.Watching() then
		ns.Print("sweep: the frame trace is not watching, so there would be no rows to write this into. /wk perf watch on first.")
		return
	end
	state.minutes = minutes
	state.running, state.held = true, false
	state.index, state.left = 0, 0
	state.label, state.after = "", ""
	ns.db.perfSweep = { step = 0, minutes = minutes }
	Step()
	if state.running then
		ns.Print(("sweep: %d steps of %d minute%s, one feature off at a time. Play normally and leave it running.")
			:format(#STEPS, minutes, minutes == 1 and "" or "s"))
	end
end

-- `/wk perf sweep`, and the three words that can follow it. Parsed the way
-- Perf/Feature.lua parses the rest of its own: a word and the remainder.
function Sweep.Word(rest)
	local word = rest:match("^(%S*)")

	if word == "stop" then
		-- Stopping puts a feature back, and the one that is off may own secure
		-- buttons, so the stop word is held to the rule the steps are.
		if state.running and InCombatLockdown and InCombatLockdown() then
			ns.Print("sweep: not in a fight. Stop it when the fight is over.")
		elseif state.running then
			Finish("sweep: stopped, and whatever was off is back on.")
		else
			ns.Print("sweep: nothing is running.")
		end
		return
	end

	if word == "status" then
		ns.Print("sweep: " .. Sweep.Describe() .. ".")
		return
	end

	if state.running then
		ns.Print("sweep: already running. " .. Sweep.Describe()
			.. ". /wk perf sweep stop ends it and puts everything back.")
		return
	end

	local minutes = MINUTES
	if word ~= "" then
		minutes = tonumber(word)
		if not minutes or minutes < LOW or minutes > HIGH then
			ns.Print(("sweep: the minutes per step are a whole number from %d to %d."):format(LOW, HIGH))
			return
		end
		minutes = math.floor(minutes)
	end
	Start(minutes)
end

--------------------------------------------------------------------------

-- Two events. The way into the world is where an interrupted run is put right,
-- and the end of a fight is where a step change that was held finally happens.
--
-- PLAYER_ENTERING_WORLD rather than PLAYER_LOGIN, and the difference matters.
-- Perf loads before nearly every part of the addon, so its login handler runs
-- before theirs, and putting a feature back on through a slash word at that
-- point would reach a part that has not built anything yet. Every part has had
-- its login pass by the time the world arrives.
local watch = CreateFrame("Frame")
watch:RegisterEvent("PLAYER_ENTERING_WORLD")
watch:RegisterEvent("PLAYER_REGEN_ENABLED")
watch:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_ENABLED" then
		Regen()
		return
	end
	Sweep.Resume()
end)
