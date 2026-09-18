local ADDON, ns = ...

local Keys = {}
ns.MarkKeys = Keys

--------------------------------------------------------------------------
-- The mouse buttons that mark
--
-- A click on a mob in the 3D world is invisible to addons, and that is still
-- true. What is not true, and what this file exists to correct, is the
-- conclusion drawn from it: that world marking therefore had to hang off
-- PLAYER_TARGET_CHANGED with ctrl held. That path cannot re-mark or clear a
-- mob that is already your target, because no target change happens, and it
-- cannot tell which button did the targeting, so shift had to stand in for the
-- right button and the two paths disagreed about what shift meant.
--
-- A modified mouse button is not a world click. It is a key. The binding
-- system takes CTRL-BUTTON1 before the world ever sees it, and by the time the
-- binding runs the `mouseover` unit has already resolved to whatever sits
-- under the cursor, out in the world exactly as on a nameplate.
--
-- Clique ships this shape in this install and its whole 3D-world feature is
-- built on it: SetBindingClick onto a secure button carrying unit="mouseover",
-- for everything in its `hovercast` set. Its source contains no reference to
-- WorldFrame at all. It refuses BUTTON1 and BUTTON2 by exact name, because an
-- unmodified mouse button binding would eat plain targeting, and takes every
-- modified one, which is what proves a modified mouse button binds here.
--
-- Casting is protected and SetRaidTarget is not, so none of Clique's secure
-- header machinery is needed. An override binding onto an ordinary button is
-- the whole thing.
--
-- The keys themselves are settings, one per mark in ns.db.markBinds, so this
-- file names no key and no icon. What it will not accept is a bare BUTTON1 or
-- BUTTON2, for Clique's reason: an unmodified mouse button binding eats plain
-- targeting and the camera drag.
--------------------------------------------------------------------------

local BUTTON_NAME = "WarriorKitMarkButton"

local held = {}   -- id -> key currently on the override layer
local heldAny     -- true while at least one is up
local proven      -- nil until the readback has answered once
local warned

-- Not a secure button, because marking is not a protected action.
--
-- Given no size and no anchor on purpose, which is the shape Clique's own
-- global button has. It is never meant to be hit by a real cursor, and a frame
-- with zero size cannot be. EnableMouse(false) would say that more plainly, but
-- nothing here proves a click delivered by the binding system still reaches a
-- mouse disabled frame, and a silently inert button is the one failure this
-- file has no way to report.
local button = CreateFrame("Button", BUTTON_NAME, UIParent)
ns.UI.Press.Clicks(button, "down")
button:SetScript("OnClick", function(_, click)
	ns.Marking.Key(click)
end)

-- Override bindings layer on top of the binding set and are never written into
-- it, which is the same reason Charge/Icon.lua uses one for its key. SetBinding
-- would overwrite whatever you had on ctrl-left-click, and the next
-- SaveBindings, which the Key Bindings panel calls when you click Okay, would
-- make that permanent.
--
-- pcalled because an override binding call is refused under combat lockdown and
-- because nothing here proves the call takes a mouse button name on 2.5.6.
local function Set(key, id)
	if type(SetOverrideBindingClick) ~= "function" then
		return false
	end
	return (pcall(SetOverrideBindingClick, button, true, key, BUTTON_NAME, id))
end

local function Clear()
	if type(ClearOverrideBindings) ~= "function" then
		return
	end
	pcall(ClearOverrideBindings, button)
end

-- The override layer read back, see UI/Bound.lua. Nil where the client has not
-- answered.
local function Reads(key, id)
	return ns.UI.Bound.Reads(key, BUTTON_NAME, id)
end

-- ApplyDefaults fills a missing setting, not a missing key inside one, so a
-- saved markBinds from before a mark existed would leave that mark unbound
-- forever with no way to tell it from a key you cleared on purpose. Fill from
-- the registered default once, and only where nothing is saved at all.
local function Seed()
	local saved = ns.db and ns.db.markBinds
	local default = ns.DefaultFor("markBinds")
	if type(saved) ~= "table" or type(default) ~= "table" then
		return
	end
	for id, key in pairs(default) do
		if saved[id] == nil then
			saved[id] = key
		end
	end
end

local function Bound(id)
	local key = ns.db and ns.db.markBinds and ns.db.markBinds[id]
	if type(key) ~= "string" or key == "" then
		return nil
	end
	return key
end

-- Returns whether any override is up. Marking.lua asks before running the
-- PLAYER_TARGET_CHANGED fallback, so the two paths are never both live.
function Keys.Active()
	return heldAny == true
end

function Keys.Apply()
	Seed()

	if ns.Lockdown.Held(Keys.Apply) then
		return
	end

	Clear()
	held, heldAny = {}, false

	if not (ns.db and ns.db.marking) then
		return
	end

	for _, mark in ipairs(ns.Marking.MARKS) do
		local key = Bound(mark.id)
		if key and not ns.UI.Bound.Bare(key) then
			if Set(key, mark.id) then
				held[mark.id] = key
				heldAny = true

				local reads = Reads(key, mark.id)
				if reads ~= nil then
					proven = reads
				end
			elseif not warned then
				warned = true
				ns.Print("this client would not take a mouse button for marking. Ctrl-targeting is doing the job instead.")
			end
		end
	end

	if heldAny and proven == false and not warned then
		warned = true
		ns.Print("this client accepted the marking keys and did not bind them. Clear them in /wk to put ctrl-targeting back.")
	end
end

-- Which other mark already owns this key, or nil. Two marks on one key is the
-- one mistake the panel cannot show you afterwards: the second binding wins
-- silently and the first mark simply stops working.
function Keys.Conflict(id, key)
	for _, mark in ipairs(ns.Marking.MARKS) do
		if mark.id ~= id and Bound(mark.id) == key then
			return mark.label
		end
	end
	return nil
end

-- The one place a marking key is written. Returns false and a reason, so the
-- panel and the slash word report the same refusal in the same words.
function Keys.Bind(id, key)
	key = key or ""
	local bare = ns.UI.Bound.Refusal(key)
	if bare then
		return false, bare
	end

	local clash = key ~= "" and Keys.Conflict(id, key)
	if clash then
		return false, ("%s is already marking %s."):format(key, clash:lower())
	end

	ns.db.markBinds[id] = key
	Keys.Apply()

	-- Apply defers under lockdown and leaves the old bindings up, so `held` is
	-- still describing the previous key here. Say that rather than read it.
	if ns.Lockdown.Owed(Keys.Apply) then
		return false, "saved. This client will not change a binding in combat, so it takes effect when the fight ends."
	end
	if key == "" then
		return true
	end
	if not held[id] then
		return false, ("this client would not take %s."):format(key)
	end
	return true
end

-- Always reports what the binding layer actually says, never what this file
-- meant to set. `unproven` means GetBindingAction has not answered yet, which
-- on this client it should at PLAYER_LOGIN.
function Keys.Describe()
	local parts = {}
	for _, mark in ipairs(ns.Marking.MARKS) do
		local key = Bound(mark.id)
		parts[#parts + 1] = ("%s %s"):format(mark.label:lower(), key or "unbound")
	end
	local line = table.concat(parts, ", ")

	if not heldAny then
		if ns.Lockdown.Owed(Keys.Apply) then
			return line .. " (waiting for combat to drop)"
		end
		return line
	end
	if proven == nil then
		return line .. " (unproven)"
	end
	if not proven then
		return line .. " (the client did not take them)"
	end
	return line
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", Keys.Apply)

-- And again when the client rebuilds its binding set, which drops every
-- override the addon holds. See ns.Rebind in Core/Core.lua.
ns.Rebind(Keys.Apply)
