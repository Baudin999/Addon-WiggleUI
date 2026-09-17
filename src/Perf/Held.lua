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

-- Our own row in the client's addon list, and what we were holding at the last
-- reading. -1 before one has happened or where the client refused it.
--
-- The ranking beside this answers which addon rose most in a minute, which is a
-- difference between two samples and so is mostly collector phase: the same
-- session names us at +30 MB one minute and +2 MB the next. Our own figure is
-- written out raw instead, once a minute for the length of a session, because
-- fifty samples have a floor and the floor is the part a collection cannot give
-- back. That floor is what a leak moves and what /reload puts back.
local ourIndex
local ourKB = -1

-- Every addon's reading kept by name, for the columns Perf/Trace.lua writes per
-- addon. oursKB answered that the session's leak is not ours, on 2026-09-17,
-- and the same lower envelope read off every other addon is what names whose it
-- is. A name is a call into the client, so each is asked for once and kept.
local names = {}                   -- addon index -> name, filled on first sight
local listed = 0                   -- how many addons the last reading walked
local allKB = -1                   -- every addon summed at the last reading

-- Found once and kept. A name is a call into the client, which is why the
-- ranking below works in indices, so the whole list is read here exactly once
-- per session rather than on every pass.
local function OurIndex(count, info)
	if ourIndex then
		return ourIndex
	end
	for index = 1, count() do
		local ok, name = pcall(info, index)
		if ok and name == ADDON then
			ourIndex = index
			return ourIndex
		end
	end
	return nil
end

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
	local mine = OurIndex(count, info)
	local most
	ourKB, allKB = -1, 0
	listed = count()
	for index = 1, listed do
		local ok, kb = pcall(usage, index)
		if ok and type(kb) == "number" then
			allKB = allKB + kb
			local was = lastKB[index]
			if was and kb - was > grew then
				grew, most = kb - was, index
			end
			lastKB[index] = kb
			if index == mine then
				ourKB = kb
			end
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

-- What this addon was holding at the last reading, in KB, or -1 before one.
function Held.Ours()
	return ourKB
end

-- Every addon summed at the last reading, in KB, or -1 before one. What is left
-- of the client's heap after this is the client's own interface code, which no
-- addon row will ever carry.
function Held.All()
	return allKB
end

-- How many addons the last reading walked, for the loop in Perf/Trace.lua.
function Held.Listed()
	return listed
end

-- One addon at the last reading: its name and its KB, or nil where the client
-- gave no name or no figure for it.
function Held.Addon(index)
	local kb = lastKB[index]
	if not kb then
		return nil
	end
	local name = names[index]
	if name == nil then
		local _, info = ns.Cause.AddOnList()
		local ok, answer = pcall(info, index)
		name = (ok and type(answer) == "string") and answer or false
		names[index] = name
	end
	if not name then
		return nil
	end
	return name, kb
end
