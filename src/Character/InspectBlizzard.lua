local ADDON, ns = ...

--------------------------------------------------------------------------
-- Blizzard's inspect window, out of the way
--
-- The same cage the character sheet's own Blizzard.lua puts CharacterFrame in,
-- with two differences worth naming, because both are about the frame rather
-- than about this addon.
--
-- **There is usually no frame to cage.** Blizzard_InspectUI is load on demand
-- and the one thing that loads it is `InspectUnit`, which calls
-- `InspectFrame_LoadUI` and then `InspectFrame_Show`. Replace `InspectUnit` and
-- the addon never loads at all, so InspectFrame never exists. It is named
-- anyway: another addon on the machine may load it, the attic is idempotent,
-- and a name this client does not carry costs one lookup against nil.
--
-- **The key it takes is not a key.** The character sheet swaps ToggleCharacter
-- so the C key lands on this addon's window. There is no binding for inspect
-- and never has been: the gesture is the entry on the right click menu of a
-- unit frame, and that entry calls `InspectUnit(contextData.unit)` on both of
-- the clients this addon runs on. So the global taken here is the whole of the
-- gesture, and taking it is what makes right clicking somebody's portrait and
-- choosing Inspect open the sheet this part draws.
--
-- That is the third global function swap in the addon, after the quest log's
-- and the character sheet's, and it is here for the same reason: one file,
-- named after the frame it is doing it to.
--
-- **The swap is not a taint risk and it is worth saying why once.** The entry
-- that calls it is a dropdown button, the dropdown is Lua the client runs after
-- the click has already been dispatched, and nothing protected follows the call
-- on that path: the replacement opens a window with no secure frame in it, and
-- the ShowUIPanel the original would have reached never runs. The rule this
-- addon keeps about never writing on a Blizzard frame is about a widget a
-- secure path acts on, which this is not, and Core/BlizzAdapter.lua only ever
-- hands a global back to whoever it took it from.
--
-- **The switch is the one on the Blizzard page.** There is one place in this
-- addon where a frame of the client's is switched off, it is the list in
-- Core/BlizzHide.lua, and a switch that lived on the character part's own page
-- would be the seventeenth place somebody has to look.
--------------------------------------------------------------------------

-- The window and the three pages the client hangs off it. All four are probed
-- before they are touched, because none of them exists until something loads
-- Blizzard_InspectUI and with the switch on nothing does.
local FRAMES = {
	"InspectFrame",
	"InspectPaperDollFrame",
	"InspectTalentFrame",
	"InspectPVPFrame",
}

-- What the menu entry does while the switch is on.
--
-- Declared once at load rather than built at the swap, for the reason
-- Character/Blizzard.lua declares its own: the pass this file signs into runs
-- once a second forever, and a closure made on every pass is a function object
-- a second for the collector to walk.
--
-- The unit is whatever the caller handed over, which from the client's own menu
-- is the unit the portrait was drawn for. A nil reaches Character/Inspect.lua's
-- own guard and comes back as a sentence, which is what any other caller that
-- got it wrong should see.
local function Inspect(unit)
	ns.Inspect.Look(unit)
end

ns.InspectBlizzard = ns.BlizzAdapter.Cage({
	frames = FRAMES,
	feature = "inspect",
	switch = "hideBlizzInspect",
	global = "InspectUnit",
	Toggle = Inspect,
	pass = true,
	held = true,
	loads = "Blizzard_InspectUI",
	place = "never loaded",
	off = "on screen, because this addon's own inspect is off",
	offKey = "the menu entry",
	onKey = "the menu entry",
})
