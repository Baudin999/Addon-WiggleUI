local ADDON, ns = ...

local Held = {}
ns.Held = Held

--------------------------------------------------------------------------
-- What the client is holding
--
-- The minute log in Perf/Trace.lua can say that a session got slower and not at
-- whose expense. On 2026-09-15 the frames over 12 ms climbed from 1 to 584 a
-- minute while events and this addon's own tickers stayed flat, and a /reload
-- put it right. A reload throws away every frame, texture and OnUpdate script
-- any addon made. None of those is heap the collector counts, and with the
-- profiler off none of them is Lua time the client will name.
--
-- So this counts them, and Perf/Trace.lua writes both readings into the row:
--
--   the frames   how many the client holds, how many are visible, the regions
--                on the visible ones, and how many visible ones run an OnUpdate
--   the memory   the addon whose usage rose most across the minute, and by how
--                many KB
--
-- **The walk is spread across frames.** EnumerateFrames hands out one frame per
-- call and a UI with Questie and Details loaded holds thousands. Walked in one
-- go that is a stall once a minute, written into the log it is meant to
-- explain. Twenty-five a frame is a whole pass every few seconds at 100 fps.
-- The client never destroys a frame, so the one the walk stopped on is still
-- there to resume from.
--
-- **The memory reading is not free.** UpdateAddOnMemoryUsage walks every addon,
-- and Details ships a guard against addons that call it often enough to freeze
-- the client. This reads it once a minute, times it into its own column, and
-- Perf/Trace.lua leaves the frame it lands in out of the counts.
--------------------------------------------------------------------------

-- Frames looked at per frame drawn.
local STEP = 25

local cursor                                        -- where the walk stopped, nil between passes
local frames, shown, regions, ticking = 0, 0, 0, 0  -- the pass in progress

-- The last whole pass, -1 until one has finished. Filled in place and handed
-- out, because the roll reads four numbers off it.
local pass = { frames = -1, shown = -1, regions = -1, ticking = -1 }

local lastKB = {}                  -- addon index -> KB at the previous reading
local grower, grew, readMs = "", 0, -1

-- One step of the walk, from Perf/Trace.lua's tick on every frame drawn.
-- Nothing here allocates: every call answers a frame that already exists or a
-- number.
function Held.Walk()
	local enumerate = _G.EnumerateFrames
	if type(enumerate) ~= "function" then
		return
	end
	local frame = cursor
	for _ = 1, STEP do
		-- Called with no argument rather than a nil one for the first frame, the
		-- way every installed addon that walks the list starts it.
		if frame then
			frame = enumerate(frame)
		else
			frame = enumerate()
		end
		if not frame then
			pass.frames, pass.shown, pass.regions, pass.ticking = frames, shown, regions, ticking
			frames, shown, regions, ticking = 0, 0, 0, 0
			break
		end
		frames = frames + 1
		-- A forbidden frame raises on anything but the question of whether it is.
		if not (frame.IsForbidden and frame:IsForbidden()) and frame:IsVisible() then
			shown = shown + 1
			regions = regions + frame:GetNumRegions()
			-- The client runs an OnUpdate on a visible frame and on no other.
			if frame:GetScript("OnUpdate") then
				ticking = ticking + 1
			end
		end
	end
	cursor = frame
end

function Held.Pass()
	return pass
end

-- Once a minute, from Perf/Trace.lua's roll. The first reading after a reload
-- only plants the baseline and names nobody.
function Held.Read()
	grower, grew, readMs = "", 0, -1
	local update, usage = _G.UpdateAddOnMemoryUsage, _G.GetAddOnMemoryUsage
	local count, info = ns.Cause.AddOnList()
	if type(update) ~= "function" or type(usage) ~= "function" or not count then
		return
	end

	local clock = _G.debugprofilestop
	local before = (type(clock) == "function") and clock() or nil
	if not pcall(update) then
		return
	end
	readMs = before and (clock() - before) or -1

	-- The index rather than the name while ranking, because a name is a call
	-- into the client and only the winner's is read.
	local most
	for index = 1, count() do
		local ok, kb = pcall(usage, index)
		if ok and type(kb) == "number" then
			local was = lastKB[index]
			if was and kb - was > grew then
				grew, most = kb - was, index
			end
			lastKB[index] = kb
		end
	end
	if most then
		local ok, name = pcall(info, most)
		grower = (ok and type(name) == "string") and name or ""
	end
end

-- The last reading: who grew, by how many KB, and what reading it cost in ms.
function Held.Grower()
	return grower, grew, readMs
end
