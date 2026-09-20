-- A resolution change that lands in combat
--
-- The grid re-scales every frame on it when the general size moves, and the
-- unit frames put anchors on it that hold secure unit buttons. SetScale on a
-- protected frame in lockdown raises. Refused frames wait for
-- PLAYER_REGEN_ENABLED. A monitor swap moves the grid's pixel and nothing's
-- size on the screen, which is asserted first.

local H = ...
local state = H.state
local Region, ns = H.Region, H.ns
local fire, check = H.fire, H.check

local box = _G.WiggleUIPlayerFrame
check(box ~= nil, "the player frame's anchor is not a named frame, so this cannot be tested")
if box then
	local blocked, inCombat = {}, false
	local realLockdown, realProtected = _G.InCombatLockdown, Region.IsProtected
	_G.InCombatLockdown = function() return inCombat end
	function Region:IsProtected() return blocked[self] == true end

	-- A new monitor out of combat. The grid's pixel moves with it, and nothing
	-- on the grid changes size on the screen: every frame is scaled by the
	-- screen over the author's 1440, so its share of the monitor is the same.
	local before = box:GetScale()
	local panel = ns.UI.Windows[1].frame
	local panelBefore = panel:GetScale()
	state.SCREEN_H = 2160
	_G.GetPhysicalScreenSize = function() return 3840, state.SCREEN_H end
	fire("DISPLAY_SIZE_CHANGED")
	check(math.abs(ns.UI.Scale() - 768 / state.SCREEN_H) < 1e-9,
		"the grid did not pick up the new screen height")
	check(math.abs(box:GetScale() - before) < 1e-9,
		("a 4K panel drew the player frame at %.4f where 1440 drew it at %.4f")
			:format(box:GetScale(), before))
	check(math.abs(panel:GetScale() - panelBefore) < 1e-9,
		"a 4K panel drew a window at another share of the screen than 1440 did")

	-- The general size in combat is what re-scales everything now, and a
	-- protected anchor refuses it until the fight ends.
	blocked[box], inCombat = true, true
	ns.UI.SetGeneral(2)
	local wanted = before * 2
	check(box:GetScale() == before,
		("a protected anchor was re-scaled in combat, %.4f"):format(box:GetScale()))
	check(math.abs(_G.WiggleUIEnemyBarsAnchor:GetScale() - 768 / 1440 * 2) < 1e-9,
		"an unprotected frame was deferred along with the protected one")

	inCombat = false
	fire("PLAYER_REGEN_ENABLED")
	check(math.abs(box:GetScale() - wanted) < 1e-9,
		("the anchor never caught up after combat, %.4f"):format(box:GetScale()))
	print(("lockdown a protected anchor held %.4f in combat and took %.4f after it")
		:format(before, box:GetScale()))

	ns.UI.SetGeneral(1)
	_G.InCombatLockdown, Region.IsProtected = realLockdown, realProtected
	state.SCREEN_H = 1440
	_G.GetPhysicalScreenSize = function() return 3440, state.SCREEN_H end
	fire("DISPLAY_SIZE_CHANGED")
end
