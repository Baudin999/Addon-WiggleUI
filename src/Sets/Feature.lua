local ADDON, ns = ...

local Sets = ns.Sets

--------------------------------------------------------------------------
-- /wui set, and where the sets are kept
--
-- No window and no page. That is the shape of this phase rather than an
-- oversight: the model, the planner and the queue are a thing you can use for a
-- week with four words, and the character sheet's own page is written against
-- ns.Sets in another branch. Nothing below draws anything.
--
-- The word is `set` and not `loadout`. Class/*.lua calls its bar plan a loadout
-- and the commit that took the weapon loadouts out calls the clash out by name.
--------------------------------------------------------------------------

-- A name typed in any case, against the list. Answering with the stored
-- spelling rather than what was typed, so every sentence printed below says the
-- set's own name back.
local function Named(typed)
	local record = Sets.Get(typed)
	if record then
		return record.name
	end
	ns.Print(("no set called %q. set on its own lists them."):format(typed))
	return nil
end

local function Said(done, why, saying)
	if done then
		ns.Print(saying)
	else
		ns.Print(why)
	end
end

local function List()
	local all = Sets.All()
	if #all == 0 then
		ns.Print("no sets yet. set save <name> takes a picture of what you have on.")
		return
	end
	local active = Sets.Active()
	for index = 1, #all do
		local record = all[index]
		ns.Print(("  %s (%s)%s"):format(record.name, Sets.Describe(record.name),
			record == active and " -- this spec's" or ""))
	end
end

--------------------------------------------------------------------------
-- The words
--
-- Four that do something and three that read. `save` fills all nineteen and
-- partial sets are built by editing, which is phase 3's: a word that took a
-- slot number would be a slot number nobody can remember, and the doll is where
-- a slot is a thing you point at.
--------------------------------------------------------------------------

local VERBS = {
	save = function(rest)
		local name = rest ~= "" and Sets.Get(rest) and Sets.Get(rest).name or nil
		if not name then
			local record, why = Sets.New(rest)
			if not record then
				ns.Print(why)
				return
			end
			name = record.name
		end
		local done, why = Sets.Capture(name)
		Said(done, why, ("saved what you have on as %q."):format(name))
	end,

	wear = function(rest)
		local name = Named(rest)
		if name then
			local done, why = Sets.Wear(name)
			if not done then
				ns.Print(why)
			end
		end
	end,

	forget = function(rest)
		local name = Named(rest)
		if name then
			local done, why = Sets.Remove(name)
			Said(done, why, ("forgot %q. set undo puts it back."):format(name))
		end
	end,

	rename = function(rest)
		local old, new = rest:match("^(%S+)%s+(.+)$")
		local name = old and Named(old)
		if not name then
			ns.Print("rename takes the set's name and then the new one.")
			return
		end
		local done, why = Sets.Rename(name, new)
		Said(done, why, ("%q is called %q now."):format(name, new))
	end,

	-- A talent group, or the word `none` to stop following one. A set that
	-- follows nothing is the ordinary case, so taking the number off has to be
	-- as easy to type as putting it on.
	spec = function(rest)
		local typed, group = rest:match("^(%S+)%s+(%S+)$")
		local name = typed and Named(typed)
		if not name then
			ns.Print("spec takes the set's name and then a talent group, or none.")
			return
		end
		local which = tonumber(group)
		if not which and group:lower() ~= "none" then
			ns.Print("a talent group is a number, or none.")
			return
		end
		local done, why = Sets.Follow(name, which)
		Said(done, why, which and ("%q is worn for talent group %d."):format(name, which)
			or ("%q follows no spec."):format(name))
	end,

	swap = function(rest)
		local group = tonumber(rest)
		if not group then
			ns.Print("swap takes a talent group to change to.")
			return
		end
		local done, why = Sets.Swap(group)
		if not done then
			ns.Print(why)
		end
	end,

	undo = function()
		local done, why = Sets.Undo()
		Said(done, why, "put the sets back the way they were.")
	end,

	list = List,
}

local function Word(arg, rawArg)
	local verb, rest = arg:match("^(%S*)%s*(.-)%s*$")
	local run = VERBS[verb:lower()]
	if run then
		run(rest)
	else
		List()
	end
	-- rawArg is the untouched line, which this word has no use for: every name
	-- it takes is trimmed and folded before it is looked up. Named so the
	-- signature matches every other word in the addon.
	return rawArg
end

--------------------------------------------------------------------------

ns.Register({
	name = "gear sets",
	order = 39,

	charDefaults = {
		-- One array of records, in the order they were made, which is the order
		-- a page draws them in. Per character, because gear is a fact about one
		-- character: a name here is a name for pieces nobody else on the
		-- account is carrying.
		--
		-- A record is { name, group, slots }, and slots[slot] is a table for an
		-- item, false for deliberately empty and nil for unset. The three
		-- states are why this is a table of tables rather than a list of item
		-- ids: nil and false have to be told apart and only a table can hold
		-- both.
		gearSets = {},
	},

	words = { set = Word },

	help = {
		"set, the sets on this character and how much of each you have on",
		"set save <name>, what you have on now, under that name",
		"set wear <name>, put it on",
		"set forget <name>, drop one",
		"set rename <name> <new name>",
		"set spec <name> <group|none>, the talent group the set is worn for",
		"set swap <group>, change talents and then put that group's set on",
		"set undo, one step back",
	},

	status = function()
		local all = Sets.All()
		if #all == 0 then
			return "no sets saved."
		end
		local active = Sets.Active()
		if active then
			return ("%d set%s; this spec wears %s, %s")
				:format(#all, #all == 1 and "" or "s", active.name, Sets.Describe(active.name))
		end
		return ("%d set%s, none of them tied to a spec."):format(#all, #all == 1 and "" or "s")
	end,
})
