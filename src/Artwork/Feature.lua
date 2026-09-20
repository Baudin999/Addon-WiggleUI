local ADDON, ns = ...

-- Everything Core and the panel need to know about the bar art.
-- Artwork.lua holds the behaviour and never talks to either.

local function Describe()
	local count = ns.Artwork.Found()
	if count == 0 then
		return "found nothing to strip, this client names the art something else"
	end
	if ns.db.blizzArt then
		return ("Blizzard art shown, %d regions"):format(count)
	end
	if ns.Artwork.Deferred() then
		return ("stripped %d regions, the rest follows when combat drops"):format(count)
	end
	return ("stripped %d regions"):format(count)
end

local function Set(value)
	ns.db.blizzArt = value
	ns.Artwork.Apply()
end

ns.Register({
	name = "artwork",
	order = 17,

	-- Signed into Core/Handback.lua. Two entries rather than one because they
	-- are two things a player can name: a gryphon is art and the micro menu is a
	-- row of buttons, and the reading on that control prints whichever of them
	-- is still ours.
	handback = {
		{ what = "the gryphons, the metal strip and the page arrows",
			ours = function() return not ns.db.blizzArt end,
			hand = function(back)
				Set(back and true or false)
				return not ns.Artwork.Deferred()
			end },

		{ what = "the micro menu",
			ours = function() return ns.db.hideBlizzMicroMenu and true or false end,
			hand = function(back)
				ns.db.hideBlizzMicroMenu = not back
				return ns.BlizzHide.Apply()
			end },
	},

	defaults = {
		-- False means the gryphons and the metal strip are gone, which is the
		-- point of the part and so the state it starts in.
		blizzArt = false,

		-- The micro menu, taken down by Core/BlizzHide.lua and defaulted here
		-- because this is the part that owns the rest of the client's bottom
		-- bar. On, for the reason every other hide switch ships on: an addon
		-- that draws its own character sheet, spell book, talents and quest log
		-- and leaves the client's row of buttons under them has added to the
		-- screen rather than replaced anything, and the alternative was a
		-- player finding Edit Mode.
		hideBlizzMicroMenu = true,
	},

	words = {
		art = function(arg)
			Set(ns.Command.Toggle(arg))
			ns.Print("Blizzard bar art " .. (ns.db.blizzArt and "shown" or "stripped")
				.. ", " .. Describe() .. ".")
		end,
	},

	help = {
		"art on|off",
	},

	status = Describe,

	reset = function()
		Set(ns.DefaultFor("blizzArt"))
	end,

	panel = function(ui)
		ui.Section("Bar art", "Action bars")
		ui.Lede("The gryphons, the metal strip behind bar 1 and the page arrows, on or off.")
		ui.Check("show Blizzard bar art",
			function() return ns.db.blizzArt end,
			Set)
		ui.Hint("The experience bar is left alone either way. Everything goes back in one call, so off is a state rather than a reload.")
		ui.Reading("bar art", Describe)
	end,
})
