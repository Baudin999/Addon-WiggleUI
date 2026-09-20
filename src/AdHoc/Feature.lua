local ADDON, ns = ...

-- Everything Core needs to know about the bars you made yourself. AdHoc.lua is
-- the list, Bars.lua is the frames, the keys and the tick, Panel.lua is the
-- page, and this file is the registration and the slash word. It draws
-- nothing.

-- What `/wui adhoc <bar> <key>` says back. Three sentences rather than one,
-- because a key this addon takes is a key something else was using, and saying
-- which is what stops somebody wondering all evening why their jump is gone.
local function BindWord(index, key)
	local bar = ns.AdHoc.Get(index)
	local displaced, why = ns.AdHocBars.Bind(index, key)
	if not displaced then
		ns.Print(why)
	elseif key == "" then
		ns.Print(bar.name .. " is unbound.")
	elseif displaced ~= "" then
		ns.Print(("%s opens %s. It shadows %s, and your saved bindings are untouched.")
			:format(key, bar.name, displaced))
	else
		ns.Print(("%s opens %s. Nothing else wanted it."):format(key, bar.name))
	end
end

local function List()
	local list = ns.AdHoc.All()
	if #list == 0 then
		return "no bars yet. /wui adhoc add <name> makes one."
	end
	for index, bar in ipairs(list) do
		ns.Print(("%d %s: %s, %d square%s"):format(index, bar.name,
			ns.AdHocBars.Describe(index), #bar.buttons, #bar.buttons == 1 and "" or "s"))
	end
	return nil
end

local Word = ns.Command.Word({
	name = "adhoc",
	apply = function() ns.AdHocBars.Apply() end,
	show = List,

	ns.Command.Zoom("adhocZoom", "ad hoc bars at %.1fx."),

	{ "radius", key = "adhocRadius", apply = function() ns.AdHocBars.Apply() end,
		number = function() return ns.AdHocBars.RadiusRange() end,
		say = function(units)
			return ("the squares sit %d units out, and a push shorter than that picks nothing.")
				:format(units)
		end },

	{ "add", run = function(_, rawValue)
		local index, why = ns.AdHoc.Add(rawValue:match("^%s*(.-)%s*$"))
		ns.Print(index and ("added " .. ns.AdHoc.Get(index).name .. ".") or why)
	end },

	{ "on", toggle = true, key = "adhoc", what = "adhoc",
		say = function(on) return "ad hoc bars " .. (on and "on." or "off.") end },

	-- A word that is not one of the above is a bar, by number or by name, and
	-- what follows it is the key.
	otherwise = function(option, value)
		if option == "off" then
			ns.db.adhoc = false
			ns.AdHocBars.Apply()
			ns.Print("ad hoc bars off.")
			return
		end
		local index = ns.AdHoc.Find(option)
		if not index then
			ns.Print(("no bar called %s. /wui adhoc lists them."):format(option))
			return
		end
		local key = value:upper()
		if key == "NONE" then
			key = ""
		end
		BindWord(index, key)
	end,
})

ns.Register({
	name = "adhoc",
	order = 35,

	switch = {
		key = "adhoc",
		label = "bars of your own, each on a key",
		apply = function() ns.AdHocBars.Apply() end,
		page = "Ad hoc bars",
	},

	zooms = {
		{ key = "adhocZoom", label = "Ad hoc bars", apply = function() ns.AdHocBars.Apply() end },
	},

	defaults = {
		adhoc = true,
		-- 1, like every other zoom in the addon. It was 1.4, to push a 27 unit
		-- square up to the size the client's own action bar draws at, and that
		-- was the wrong lever: a fractional zoom resamples every icon on the
		-- ring, and it only reached a player who had never typed `adhoc zoom`,
		-- because a saved 1 overrides a default of 1.4 and says nothing about
		-- it. The square is 54 units now, which is the size it should have been
		-- and is sharp, and this row is back to being what it says it is: the
		-- number you turn when you want a ring bigger than the one it ships at.
		adhocZoom = 1,
		-- How far out the squares sit, in units at zoom one, and with it how
		-- far you have to push before a release picks one.
		--
		-- 140 rather than the 86 this shipped at. 86 is `SIZE * 1.6`, which is
		-- the tightest circle that keeps the name in the middle clear of the
		-- squares, and a floor is not an answer: a bar of four at 86 is a
		-- cluster in the middle of the screen, and the push that fires one of
		-- them was twenty units whatever the circle was, so the ring you were
		-- looking at had nothing to do with the gesture you were making. At 140
		-- the four squares are a ring, and the push is out to them.
		adhocRadius = 140,
	},

	-- A bar is the character's: a trade skill belongs to one character and a
	-- totem to one class, and a bar of either written into the account would be
	-- a bar of spells another character does not know.
	--
	-- The list starts empty rather than carrying a bar here, because
	-- ApplyDefaults copies a default one level deep and a list of tables would
	-- hand every character the same rows.
	charDefaults = {
		adhocBars = {},   -- { name, key, displaced, buttons = { { kind, name, id, icon } } }
		adhocShown = 1,   -- which one the page is showing
	},

	words = { adhoc = Word },

	help = {
		"adhoc, every bar, its key and how many squares it holds",
		"adhoc add <name>, a new bar",
		"adhoc <bar> <key|none>, the key you hold to open that ring",
		"adhoc zoom 1.5, the bars' zoom, 0.5 to 3",
		"adhoc radius 160, how far out the squares sit and how far you push",
		"adhoc on|off",
	},

	status = function()
		if not ns.db.adhoc then
			return "off"
		end
		local parts = {}
		for index, bar in ipairs(ns.AdHoc.All()) do
			parts[#parts + 1] = bar.name .. " " .. ns.AdHocBars.Describe(index)
		end
		if #parts == 0 then
			return "none yet"
		end
		return table.concat(parts, ", ")
	end,

	panel = function(ui) ns.AdHocPanel.Build(ui) end,
})
