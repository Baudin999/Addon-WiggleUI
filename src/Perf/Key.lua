local ADDON, ns = ...

local Key = {}
ns.PerfKey = Key

--------------------------------------------------------------------------
-- Ctrl-R
--
-- The key the client already puts a frame rate on, taken for a window that
-- says rather more.
--
-- **This is a key taken off Blizzard, and that is the argument for it.** The
-- dungeon log asks for a key of its own because there is no adventure guide on
-- these clients to replace. Here there is something to replace: TOGGLEFPS draws
-- one averaged number in a corner, an average is the one figure that cannot
-- show a stutter, and the muscle memory for "how is this machine doing" is
-- already on Ctrl-R. Putting the answer somewhere else would leave the worse
-- answer on the key everyone reaches for.
--
-- How the key is held is UI/Bound.lua's. TOGGLEFPS is shadowed while this
-- holds the key and comes straight back the moment the switch goes off.
--
-- **The button is not secure and does not need to be.** Opening a window is
-- ordinary Lua, so the key works in combat, which for a window you open to find
-- out why a pull stuttered is the whole point of it.
--------------------------------------------------------------------------

local BUTTON_NAME = "WiggleUIPerfButton"
Key.BUTTON_NAME = BUTTON_NAME

-- No size and no anchor, the shape every other global button in the addon has.
-- Left shown, because a click delivered by the binding system is only proven to
-- arrive on a shown frame.
local button = CreateFrame("Button", BUTTON_NAME, UIParent)
ns.UI.Press.Clicks(button, "up")
button:SetScript("OnClick", function()
	ns.PerfHud.Toggle()
end)

local hold = ns.UI.Bound.Key({
	button = button, name = BUTTON_NAME,
	store = ns.KeySetting("perfKey"),
})

Key.Apply, Key.Bind, Key.Describe = hold.Apply, hold.Bind, hold.Describe

-- Taken at login as well as on every rebuild of the binding set, because the
-- rebuild that matters happens once during login and a key nobody took cannot
-- be put back by it.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	Key.Apply()
end)
