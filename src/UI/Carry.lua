local ADDON, ns = ...

local Carry = {}
ns.UI.Carry = Carry

--------------------------------------------------------------------------
-- Something the client's cursor cannot hold
--
-- A drag between two of this addon's windows, for a thing GetCursorInfo has
-- no kind for. A passive talent is the case: PickupSpell refuses it, so a drag
-- out of the talent window has nothing to put on the cursor, and the debuff
-- row on the options page still wants to be dropped on.
--
-- It is OPie's ring editor, which does the same thing for its own slices. The
-- drag sets the cursor to the thing's picture with SetCursor, the button coming
-- up puts the pointer back, and the drop is whichever frame is under the
-- pointer at that moment. OnReceiveDrag never fires for this, because the
-- client's cursor is empty the whole way.
--
-- A frame that takes a drop says so with Carry.Target, and what it is handed
-- is whatever the drag lifted. This file knows neither end: the talent window
-- lifts a table, the debuff row reads it.
--------------------------------------------------------------------------

local held = nil

-- Weak keys, because a frame is never destroyed on these clients but a page
-- that is rebuilt hands out new ones, and the old ones have no business here.
local targets = setmetatable({}, { __mode = "k" })

-- SetCursor takes a file id or a path, and nil puts the client's own pointer
-- back. Both clients have it; through pcall because a texture the client will
-- not draw raises.
local function Picture(texture)
	pcall(SetCursor, texture)
end

function Carry.Lift(thing, texture)
	held = thing
	Picture(texture)
end

-- What a drag is carrying, or nil. A target asks while the pointer is over it,
-- to light up only for something it would take.
function Carry.Held()
	return held
end

function Carry.Target(frame, take)
	targets[frame] = take
end

-- The button came up. Hands the thing to the frame under the pointer, if that
-- frame takes drops, and says whether one did.
function Carry.Land()
	local thing = held
	held = nil
	Picture(nil)
	if thing == nil then
		return false
	end
	local focus = ns.MouseFocus()
	local take = focus and targets[focus]
	if not take then
		return false
	end
	take(thing)
	return true
end
