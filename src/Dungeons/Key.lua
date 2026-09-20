local ADDON, ns = ...

local Key = {}
ns.DungeonKey = Key

--------------------------------------------------------------------------
-- The key that opens the dungeon log
--
-- Shift-L out of the box, and any key you like in the settings window.
--
-- **It is a key of its own rather than a key taken off Blizzard.** The quest
-- log takes L and the world map takes M, because the client already has a
-- window for each of those and the honest thing to do is put the client's own
-- in the attic and stand in front of it. There is no adventure guide on either
-- of these clients. Nothing is being replaced, so nothing is being taken, and
-- the key is one this addon asks for.
--
-- Shift-L because L is the log key and this is the other log. A player who
-- knows L knows where to reach, and the modifier is what says which one.
--
-- How the key is held is UI/Bound.lua's.
--
-- **The button is not secure and does not need to be.** Opening a window is
-- ordinary Lua. The charge and target switch keys are on secure buttons because
-- starting an attack is protected and only a macro run off a hardware press may
-- do it; nothing here is. So this is a plain button with an OnClick, which also
-- means the key still works in combat, which for a window you open to read is
-- the whole point of it not being secure.
--------------------------------------------------------------------------

local BUTTON_NAME = "WiggleUIDungeonsButton"
Key.BUTTON_NAME = BUTTON_NAME

-- No size and no anchor, the shape every other global button in the addon has.
-- It is never meant to be hit by a real cursor, and a frame with no size cannot
-- be. Left shown, because a click delivered by the binding system is only
-- proven to arrive on a shown frame.
local button = CreateFrame("Button", BUTTON_NAME, UIParent)
ns.UI.Press.Clicks(button, "up")
button:SetScript("OnClick", function()
	ns.DungeonWindow.Toggle()
end)

local hold = ns.UI.Bound.Key({
	button = button, name = BUTTON_NAME,
	store = ns.KeySetting("dungeonKey"),
	wanted = function() return ns.db.dungeons end,
	off = "the dungeon log is off",
})

Key.Apply, Key.Bind, Key.Describe = hold.Apply, hold.Bind, hold.Describe
