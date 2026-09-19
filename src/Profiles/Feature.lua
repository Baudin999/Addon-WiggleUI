local ADDON, ns = ...

local Profiles = ns.Profiles

--------------------------------------------------------------------------
-- The profiles page and the profile word
--
-- Switching and deleting both go through UI.Ask. A switch reloads the
-- interface and a delete cannot be undone, and a dropdown pick is too easy a
-- press for either.
--------------------------------------------------------------------------

local draft = ""

local function AskSwitch(name)
	if name == Profiles.Active() then
		return
	end
	ns.UI.Ask({
		title = "Switch profile",
		question = ("Wear %q on this character? The interface reloads to put it on."):format(name),
		accept = "switch",
		onAccept = function()
			Profiles.Use(name)
			ReloadUI()
		end,
	})
end

local function AskDelete(name)
	if not name or name == Profiles.Active() then
		return
	end
	local users = Profiles.Users(name)
	ns.UI.Ask({
		title = "Delete profile",
		question = #users == 0
			and ("Delete %q? This cannot be undone."):format(name)
			or ("Delete %q? %s wear%s it and get%s a profile of their own at the next login.")
				:format(name, table.concat(users, ", "), #users == 1 and "s" or "",
					#users == 1 and "s" or ""),
		accept = "delete",
		onAccept = function()
			Profiles.Delete(name)
			ns.Options.Refresh()
		end,
	})
end

local function Options(skipActive)
	local out = {}
	for _, name in ipairs(Profiles.Names()) do
		if not (skipActive and name == Profiles.Active()) then
			out[#out + 1] = { value = name }
		end
	end
	return out
end

local function Wearing()
	local name = Profiles.Active()
	local users = Profiles.Users(name)
	if #users == 0 then
		return name
	end
	return ("%s, with %s"):format(name, table.concat(users, ", "))
end

local function NewOk()
	local name = Profiles.Clean(draft)
	return name ~= nil and not Profiles.Exists(name)
end

local function NewLabel()
	local name, why = Profiles.Clean(draft)
	if not name then
		return draft == "" and "type a name above to copy this profile" or why
	end
	if Profiles.Exists(name) then
		return ("there is already a profile called %q"):format(name)
	end
	return ("copy this profile to %q and wear it"):format(name)
end

local function NewPress()
	local name, why = Profiles.New(draft)
	if not name then
		ns.Print(why)
		return
	end
	draft = ""
	Profiles.Use(name)
	ns.Print(("copied to %q. Reloading to wear it."):format(name))
	ReloadUI()
end

--------------------------------------------------------------------------
-- /wk profile
--------------------------------------------------------------------------

local function List()
	for _, name in ipairs(Profiles.Names()) do
		ns.Print(("  %s%s"):format(name, name == Profiles.Active() and " (this character)" or ""))
	end
end

-- A name typed in any case, matched against the list.
local function Named(typed)
	for _, name in ipairs(Profiles.Names()) do
		if name:lower() == typed:lower() then
			return name
		end
	end
	ns.Print(("no profile called %q. profile on its own lists them."):format(typed))
end

local VERBS = {
	use = function(rest)
		local name = Named(rest)
		if name and name ~= Profiles.Active() then
			Profiles.Use(name)
			ns.Print(("wearing %q. Reloading."):format(name))
			ReloadUI()
		end
	end,
	new = function(rest)
		draft = rest
		NewPress()
	end,
	delete = function(rest)
		local name = Named(rest)
		if name then
			local done, why = Profiles.Delete(name)
			ns.Print(done and ("deleted %q."):format(name) or why)
		end
	end,
	export = function()
		Profiles.ShowExport()
	end,
	import = function()
		Profiles.ShowImport()
	end,
}

local function Word(arg)
	local verb, rest = arg:match("^(%S*)%s*(.-)%s*$")
	local run = VERBS[verb:lower()]
	if run then
		run(rest)
		return
	end
	ns.Print(("this character wears %s."):format(Wearing()))
	List()
end

ns.Register({
	name = "profiles",
	order = 43,

	words = { profile = Word },

	help = {
		"profile, list the profiles and say which one this character wears",
		"profile use <name>, wear another profile, reloading",
		"profile new <name>, copy this one under a new name and wear it",
		"profile delete <name>, delete one this character is not wearing",
		"profile export | import, a string to share a profile with another player",
	},

	status = function()
		return ("wearing %s."):format(Wearing())
	end,

	panel = function(ui)
		ui.Section("Profiles", "Under the hood")
		ui.Lede("Every setting on this character, theme and window spots included, comes from one profile. Groups, the gold ledger and other records stay on the account.")

		ui.Reading("this character wears", Wearing)
		ui.Picker("switch to", Profiles.Active, AskSwitch, function() return Options(false) end)
		ui.Hint("Two characters can wear the same profile, and a change on one shows on the other. Switching reloads the interface.")

		ui.TextField("new profile", function() return draft end, function(text) draft = text or "" end)
		ui.Action(NewLabel, NewPress, NewOk)

		ui.ActionPair(function() return "export this one" end, Profiles.ShowExport, nil,
			function() return "import a string" end, Profiles.ShowImport, nil)
		ui.Hint("An export carries only what differs from the shipped screen. Importing makes a new profile and wears it, and leaves this one as it is.")

		ui.Picker("delete", function() return nil end, AskDelete, function() return Options(true) end)
	end,
})
