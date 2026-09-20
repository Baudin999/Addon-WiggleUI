local ADDON, ns = ...

-- The setup's registration: the one saved flag, the word, and the first login.
--
-- setupDone is a record rather than a setting, and Core/Core.lua's KEPT list
-- says so: `/wui defaults yes` puts your screen back without asking the four
-- questions again, and scripts/bake-defaults.sh never ships a true, which would
-- be a setup no new player ever saw.

local Setup = ns.Setup

-- Under the addon's own button in the game menu. The player who wants the
-- setup again is usually the one who skipped it and has not found /wui yet, and
-- Escape is the one key everybody already presses.
ns.GameMenu.Add({
	name = "WiggleUIGameMenuSetup",
	label = "WiggleUI Setup",
	tip = "The four first questions again: the mode, the colours, the unit frames and where tooltips open.",
	open = function() Setup.Show() end,
})

-- Up at the first PLAYER_LOGIN of an account that has not answered it. Login
-- rather than ADDON_LOADED because the cards draw your own frame, portrait and
-- class colour, and none of those exist before the player does.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	if not ns.db.setupDone then
		Setup.Show()
	end
end)

ns.Register({
	name = "setup",
	order = 42,

	defaults = {
		setupDone = false,
	},

	words = {
		setup = function()
			Setup.Show()
		end,
	},

	help = {
		"setup, the four first questions again: mode, colours, unit frames and tooltips",
	},

	status = function()
		return ns.db.setupDone and "answered" or "not answered yet"
	end,

	panel = function(ui)
		ui.Section("Setup", "On and off")
		ui.Lede("The four questions a new player is asked at the first login: the mode, the colours, the unit frames and where tooltips open. Everything else stays as it is.")
		ui.Action(function() return "run the setup again" end, function()
			ns.Options.Hide()
			Setup.Show()
		end)
	end,
})
