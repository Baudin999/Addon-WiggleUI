local ADDON, ns = ...

local Switch = {}
ns.Switch = Switch

--------------------------------------------------------------------------
-- Switching target and swinging at it
--
-- TAB picks the next enemy and stops there. In a fight that costs a second
-- press, because the swing does not follow the target, and the mob you just
-- switched to stands there untouched until you notice. This is one key that
-- does both, in that order and inside one macro, so the attack lands on the
-- mob the cycle just picked rather than on whatever was targeted a moment
-- before.
--
-- It is a secure action button carrying a macro rather than Lua calling the
-- two functions, for the reason Charge/Icon.lua is one: starting an attack is
-- protected, and a macro run off a hardware key press is the path that is
-- allowed to do it. The macro is a constant, which the charge macro is not, so
-- nothing here is ever rewritten and combat can refuse only a rebind.
--
-- Bind it in /wui or with `/wui switch <key>`, or put
-- `/click WiggleUISwitchButton` in a normal macro and drag that to a bar.
--------------------------------------------------------------------------

local BUTTON_NAME = "WiggleUISwitchButton"
Switch.BUTTON_NAME = BUTTON_NAME

-- /targetenemy is TAB's own binding, TARGETNEARESTENEMY, said as a macro
-- command, so this cycles exactly the way TAB does and honours the same
-- settings. /startattack carries harm and nodead because the cycle can land on
-- nothing at all when there is nothing in range to land on, and a bare
-- /startattack then answers back in chat for a key press that did nothing.
--
-- The conditional belongs on the attack line and nowhere else. A bare
-- [harm,nodead] tests the target you already have, not the one the cycle is
-- about to pick, so on /targetenemy it would decide whether the cycle runs at
-- all: your mob dies, the corpse fails nodead, and the key does nothing on the
-- one press it exists for. Nothing filters what TargetNearestEnemy picks, and
-- TAB skips corpses on its own anyway.
local MACRO = table.concat({
	"/targetenemy",
	"/startattack [harm,nodead]",
}, "\n")

-- No size and no anchor, the shape Marking/Keys.lua uses and Clique uses for
-- its own global button. It is never meant to be hit by a real cursor, and a
-- frame with no size cannot be. It is left shown, because a click delivered by
-- the binding system is only proven to arrive on a shown frame.
--
-- The press, because only the key ever fires it. It used to register the press
-- and leave the attribute unset, which worked only while the player kept the
-- client's key-down setting on.
local button = ns.UI.Press.Button(UIParent, BUTTON_NAME, "down")
button:SetAttribute("type", "macro")
button:SetAttribute("macrotext", MACRO)

-- An override binding held by UI/Bound.lua, and set here rather than in
-- Bindings.xml: a binding listed there runs ordinary Lua, and ordinary Lua may
-- not start an attack. So TAB stays TAB in your bindings file even while this
-- holds it.
local hold = ns.UI.Bound.Key({
	button = button, name = BUTTON_NAME,
	store = ns.KeySetting("switchKey"),
})

Switch.Apply, Switch.Bind, Switch.Describe = hold.Apply, hold.Bind, hold.Describe

-- PLAYER_LOGIN rather than ADDON_LOADED, because the binding set the override
-- lands on top of is not built until then.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	Switch.Apply()
end)
