-- Every frame that holds something has a rectangle
--
-- A frame on this client is a rectangle, and a frame that has not got one is
-- not drawn. Neither is anything anchored inside it. That is the whole of the
-- rule and it is invisible in review, because a container is written to hold
-- things rather than to be seen and the line that would have sized it reads
-- like housekeeping nobody needs.
--
-- The quest tracker is what asked for this check. Its zone strip arrived, the
-- tally and the rows moved into a frame of their own so that one anchor could
-- move them off the strip's width, and that frame was given a width and no
-- height. Every assertion in section 85 passed: the model answered the right
-- quests, the pool held the right rows, the rows carried the right strings,
-- and on the screen the tracker drew its zone tabs down the left of an empty
-- column. A tracker with no quests on it, made of quests.
--
-- So the rule is asserted off the geometry rather than off the source. A frame
-- is held to it when three things are true of it:
--
--   it is on the addon's pixel grid, which is every frame this addon draws and
--   none of Blizzard's, asked through ns.UI.OnGrid the way section 33 asks;
--   it is visible, because a pool's spare rows are hidden and sized to nothing
--   until something lands on them, which is the shape a pool is meant to be;
--   and it holds something, meaning a texture, a font string or a child frame.
--   An empty frame with no rectangle draws nothing either way.
--
-- Width and height both, and the question asked of each is GetWidth and
-- GetHeight rather than the number last written: a frame anchored by two
-- opposing edges has a size it was never told, which is how the scroll
-- viewports and every stretched row in the addon are built, and the client
-- resolves that the same way the stub does.
--
-- Run last, because it is a sweep of what every section above it has built.
-- Nothing here opens anything: what is on the screen when this runs is
-- whatever the run has left standing, and the more of that the better.

local H = ...
local ns, check = H.ns, H.check

local function onGrid(frame)
	local node = frame
	while node and node ~= _G.UIParent do
		if ns.UI.OnGrid(node) then
			return true
		end
		node = node.parent
	end
	return false
end

-- What the frame is holding, as a count, so a container with nothing in it is
-- excused and one with a row in it is not.
local function holds(frame)
	return #frame.regions + #frame.children
end

local walked, held, flat = 0, 0, 0

local seen = {}
local function walk(frame)
	if seen[frame] then
		return
	end
	seen[frame] = true
	walked = walked + 1

	if frame ~= _G.UIParent and frame:IsVisible() and holds(frame) > 0
		and onGrid(frame) then
		held = held + 1
		local wide, tall = frame:GetWidth() or 0, frame:GetHeight() or 0
		if wide <= 0 or tall <= 0 then
			flat = flat + 1
			check(false, ("%s holds %d things and measures %.1f by %.1f")
				:format(tostring(frame:GetName() or "an unnamed frame"),
					holds(frame), wide, tall))
		end
	end

	for _, kid in ipairs(frame.children) do
		walk(kid)
	end
end

walk(_G.UIParent)

check(held > 0, "nothing on the grid was holding anything, so this swept nothing")

print(("rects %d frames walked, %d of them on the grid with something in them, %d with no rectangle")
	:format(walked, held, flat))
