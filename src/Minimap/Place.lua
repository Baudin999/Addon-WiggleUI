local ADDON, ns = ...

-- Where the minimap sits.
--
-- Every other frame this addon puts on the screen moves when you unlock the
-- frames. The map did not, and the reason is that it is not ours: MinimapCluster
-- inherits EditModeMinimapSystemTemplate on this client, so its corner is
-- whatever the Edit Mode layout says, and the only way to move it was to open
-- Edit Mode and drag it there. That is a second place to put frames, for one
-- frame, and the answer to "why will this one not move" was nowhere near the
-- lock.
--
-- So the lock reaches it, through the same UI.Placeable every other placed
-- frame here uses, and the two ways of moving it are kept in step rather than
-- left to race.
-- Three of the client's own methods say when Edit Mode has an opinion, and each
-- is hooked rather than replaced:
--
--   ApplySystemAnchor   the layout being put on the frame, which happens at
--                       login when the server sends the layouts down, on a
--                       display or scale change, and on every layout switch.
--                       Ours goes on after it, or the map walks back to its
--                       corner some seconds into every session.
--
--   OnDragStop          a drag made inside Edit Mode. Written down as ours, so
--                       the two never hold different answers and the one that
--                       wins is not merely the one that ran last.
--
--   ResetToDefaultPosition   Edit Mode's own reset. It clears ours too, which
--                       is what makes that button still mean something.
--
-- Nothing here names ns.EditMode. That file carries a layout between computers
-- and knows nothing about this frame; this one talks to the frame in front of
-- it and asks for every method by name first, because the Edit Mode in 2.5.6 is
-- a backport and a method the retail source has is not a method this client is
-- promised to have. On a flavour with no Edit Mode at all, the three hooks find
-- nothing, the placing still works, and the map is simply a frame you can drag.

local Place = {}
ns.MinimapPlace = Place

-- What the client anchors the cluster at in Minimap.xml, used only if the frame
-- has no Edit Mode to hand it back to.
local BUILT_POINT = "TOPRIGHT"

local cluster, map, place

--------------------------------------------------------------------------
-- The two frames
--------------------------------------------------------------------------

-- What moves. Everything on the map hangs off it: the map itself, the zone
-- text, Blizzard's corner buttons and this addon's bezel and clock under them.
local function Cluster()
	if cluster then
		return cluster
	end
	local frame = _G.MinimapCluster
	if type(frame) ~= "table" or type(frame.SetPoint) ~= "function" then
		return nil
	end
	cluster = frame
	return cluster
end

-- What the drag is taken by. The map fills the cluster and answers the mouse
-- already, and the strip of cluster left over is the zone text, so a drag
-- delivered to the cluster would only start on a few pixels of it.
local function Grip()
	if map then
		return map
	end
	local frame = _G.Minimap
	if type(frame) ~= "table" or type(frame.RegisterForDrag) ~= "function" then
		return nil
	end
	map = frame
	return map
end

-- The anchor the player dragged the map to, or nothing.
--
-- Empty rather than nil for the reason corralPoint is empty: the absence of a
-- position is a real state that has to survive a merge with the defaults, and a
-- key whose default is nil is a key the defaults table never carries at all.
local function Saved()
	local anchor = ns.db.minimapPoint
	if anchor and anchor[1] then
		return anchor
	end
	return nil
end

--------------------------------------------------------------------------
-- Keeping step with Edit Mode
--------------------------------------------------------------------------

-- A drag made in Edit Mode, read off the frame and kept as ours.
--
-- Edit Mode can snap a system to another system rather than to the screen, and
-- an offset against another frame is not an offset this file can hold: writing
-- it down against UIParent would move the map somewhere nobody asked for on the
-- next login. So that case hands the frame back instead, and Edit Mode's own
-- anchor is left to hold it.
local function Captured()
	local frame = Cluster()
	if not frame then
		return
	end
	local point, relativeTo, relativePoint, x, y = frame:GetPoint()
	if not point then
		return
	end
	if relativeTo and relativeTo ~= UIParent then
		ns.db.minimapPoint = {}
		return
	end
	ns.db.minimapPoint = { point, "UIParent", relativePoint,
		ns.UI.Whole(x), ns.UI.Whole(y) }
end

-- Edit Mode's reset button, which puts the system back where the preset layout
-- had it. The hook below runs after that has happened, and after this file's
-- own ApplySystemAnchor hook has put the old point back on the way through, so
-- the default is asked for a second time with nothing left to override it.
local function Released()
	ns.db.minimapPoint = {}
	local frame = Cluster()
	if frame and type(frame.ApplySystemAnchor) == "function" then
		pcall(frame.ApplySystemAnchor, frame)
	end
	ns.Options.Refresh()
end

-- The three methods, each taken once and only if this client has it.
--
-- pairs over a table the loop clears out of, because Blizzard_EditMode can load
-- on demand: a method that is not there at login may be there by the time the
-- next addon finishes loading, and one that is already hooked must not be
-- hooked twice.
local HOOKS = {
	ApplySystemAnchor = function() Place.Apply() end,
	OnDragStop = Captured,
	ResetToDefaultPosition = Released,
}

local function Hook(frame)
	if type(hooksecurefunc) ~= "function" then
		return
	end
	for name, after in pairs(HOOKS) do
		if type(frame[name]) == "function"
			and pcall(hooksecurefunc, frame, name, after) then
			HOOKS[name] = nil
		end
	end
end

--------------------------------------------------------------------------

-- No rim and no name passed, unlike most of the frames this addon places. Those
-- are chromeless rectangles: a piece of empty screen you would have to find
-- from memory, so unlocking draws an edge round them and writes their name
-- above it. This one is a picture of where you are standing, and a rim over it
-- would be a rim drawn over the world.
local function Build(frame)
	place = ns.UI.Placeable(frame, {
		grip = Grip() or frame,
		moved = function(anchor)
			ns.db.minimapPoint = anchor
			ns.Options.Refresh()
		end,
	})
end

function Place.Apply()
	if not ns.db then
		return
	end
	local frame = Cluster()
	if not frame then
		return
	end
	if not place then
		Build(frame)
		Hook(frame)
	end
	local anchor = Saved()
	if anchor then
		place:Place(anchor)
	end
end

function Place.Lock()
	if place then
		place:Lock(not ns.db.locked)
	end
end

-- Hand the map back to whoever placed it before the addon did. Edit Mode where
-- there is one, and the corner Minimap.xml anchors it at where there is not.
function Place.Reset()
	ns.db.minimapPoint = {}
	local frame = Cluster()
	if not frame then
		return
	end
	if type(frame.ApplySystemAnchor) == "function"
		and pcall(frame.ApplySystemAnchor, frame) then
		return
	end
	frame:ClearAllPoints()
	frame:SetPoint(BUILT_POINT, UIParent, BUILT_POINT, 0, 0)
end

-- Whether the map has been dragged off wherever the client had it. The panel
-- reads it so the reset button is only offered when there is something to
-- reset, which is the shape the corral's own reset has.
function Place.Moved()
	return Saved() ~= nil
end

function Place.Describe()
	if not Cluster() then
		return "not placed, this client has no MinimapCluster to move"
	end
	local anchor = Saved()
	if not anchor then
		return "where the client's own layout puts it"
	end
	return ("dragged, %s at %d, %d from the screen's %s")
		:format(anchor[1]:lower(), anchor[4], anchor[5], anchor[3]:lower())
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")

-- Login is the first Apply and nothing before it counts: there is no ns.db to
-- read a saved anchor out of. ADDON_LOADED after it is for the one case the
-- three hooks cannot be taken at login, which is Blizzard_EditMode arriving on
-- demand, and it stops firing into anything the moment all three are taken.
local ready = false

events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		ready = true
		Place.Apply()
		Place.Lock()
	elseif ready and next(HOOKS) and Cluster() then
		Hook(Cluster())
		Place.Apply()
	end
end)
