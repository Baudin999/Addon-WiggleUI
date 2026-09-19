local ADDON, ns = ...

local UI = ns.UI

--------------------------------------------------------------------------
-- A shake of the mouse
--
-- The pointer thrown left and right a few times in a row, which is the one
-- gesture a hand makes on purpose and almost never by accident. Read off the
-- horizontal position alone: a shake is sideways, and a pointer crossing the
-- screen on its way to a button turns at most once.
--
-- A leg is a run in one direction. It turns when the pointer comes back SPAN
-- units from the furthest point it reached, so a tremor at the end of a sweep
-- is not a turn and every leg counted is at least SPAN long. TURNS turns inside
-- WINDOW seconds is a shake. After one, the detector is deaf for QUIET seconds,
-- so a hand that keeps shaking a moment longer does not answer itself.
--
-- The state is one table per detector and the feed writes numbers into it and
-- nothing else, because it runs on a tick.
--------------------------------------------------------------------------

local SPAN = 60
local TURNS = 6
local WINDOW = 1.2
local QUIET = 1

-- The detector at rest. Called once by whoever owns one.
function UI.Wiggle()
	local state = { turns = {}, head = 1, quiet = 0 }
	for index = 1, TURNS do
		state.turns[index] = -math.huge
	end
	return state
end

-- Forget the leg in progress, so a pointer that jumped, or was handed back by
-- a camera turn, is not read as having travelled.
function UI.WiggleLose(state)
	state.pivot = nil
end

-- One position, in UIParent units, at one time. True on the sample that
-- completes a shake.
function UI.WiggleFeed(state, x, now)
	if now < state.quiet then
		state.pivot = nil
		return false
	end
	if not state.pivot then
		state.pivot, state.far, state.way = x, x, 0
		return false
	end
	local way = state.way
	if way == 0 then
		if x - state.pivot >= SPAN then
			state.way, state.far = 1, x
		elseif state.pivot - x >= SPAN then
			state.way, state.far = -1, x
		end
		return false
	end
	if (x - state.far) * way > 0 then
		state.far = x
		return false
	end
	if (state.far - x) * way < SPAN then
		return false
	end

	-- A turn at the furthest point, and the leg back is already SPAN long.
	state.pivot, state.far, state.way = state.far, x, -way
	local turns, head = state.turns, state.head
	turns[head] = now
	head = head % TURNS + 1
	state.head = head
	-- The slot after the one just written is the oldest of the last TURNS.
	if now - turns[head] > WINDOW then
		return false
	end
	for index = 1, TURNS do
		turns[index] = -math.huge
	end
	state.quiet = now + QUIET
	state.pivot = nil
	return true
end
