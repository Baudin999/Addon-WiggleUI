local ADDON, ns = ...

local Profiles = {}
ns.Profiles = Profiles

--------------------------------------------------------------------------
-- What you can do with a profile
--
-- Core.lua keeps them and decides which one ns.db is. This file is every
-- operation on the list: switch, copy under a new name, delete, and the two
-- ends of a pasted string. Nothing here applies a profile. Switching writes a
-- name for the next load and the caller reloads, for the reason Core gives.
--------------------------------------------------------------------------

-- As long as the picker shows without cutting it off.
local NAME_LETTERS = 32

-- The name a string arrives under when it carries none.
local IMPORTED = "Imported"

function Profiles.Active()
	return ns.ProfileName()
end

function Profiles.Names()
	local names = {}
	for name in pairs((ns.ProfileStore())) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

function Profiles.Exists(name)
	return (ns.ProfileStore())[name] ~= nil
end

-- The other characters that last logged in wearing this profile. Only as
-- fresh as each one's last login, which is the most the account file knows.
function Profiles.Users(name)
	local _, users = ns.ProfileStore()
	local me, out = ns.CharacterKey(), {}
	for character, wearing in pairs(users or {}) do
		if wearing == name and character ~= me then
			out[#out + 1] = character
		end
	end
	table.sort(out)
	return out
end

-- A name as typed, trimmed, or nil and why.
function Profiles.Clean(text)
	local name = type(text) == "string" and text:match("^%s*(.-)%s*$") or ""
	if name == "" then
		return nil, "a profile needs a name"
	end
	if #name > NAME_LETTERS then
		return nil, ("a profile name is %d letters at most"):format(NAME_LETTERS)
	end
	if name:find("[%c|]") then
		return nil, "a profile name cannot hold a | or a control character"
	end
	return name
end

-- The first of name, name 2, name 3 that nothing is called yet.
local function Free(name)
	local base, at = name:sub(1, NAME_LETTERS - 3), 2
	while Profiles.Exists(name) do
		name = ("%s %d"):format(base, at)
		at = at + 1
	end
	return name
end

-- The profile this character wears, copied under a new name. Returns the
-- name, or nil and why.
function Profiles.New(text)
	local name, why = Profiles.Clean(text)
	if not name then
		return nil, why
	end
	if Profiles.Exists(name) then
		return nil, ("there is already a profile called %q"):format(name)
	end
	local profiles = ns.ProfileStore()
	profiles[name] = ns.ProfileCopy(Profiles.Active())
	return name
end

function Profiles.Use(name)
	if not Profiles.Exists(name) then
		return nil, ("there is no profile called %q"):format(tostring(name))
	end
	ns.UseProfile(name)
	return name
end

-- Every character wearing it falls back to one of its own at its next login,
-- which Core's Chosen does. The one this character wears is refused, because
-- ns.db is that table and the session would go on writing into a profile
-- that no longer has a name.
function Profiles.Delete(name)
	if name == Profiles.Active() then
		return nil, "that is the profile this character wears, switch first"
	end
	if not Profiles.Exists(name) then
		return nil, ("there is no profile called %q"):format(tostring(name))
	end
	local profiles = ns.ProfileStore()
	profiles[name] = nil
	return name
end

-- A string to paste somewhere, carrying the name and only the settings that
-- are not what the addon ships with.
function Profiles.Export(name)
	name = name or Profiles.Active()
	return ns.ProfileCodec.Write({
		name = name,
		from = ns.version,
		settings = ns.ProfileMoved(name),
	})
end

-- The settings a string may write. A key the addon does not register is one a
-- newer or older release had; a key of the wrong type is a string written by
-- hand. Both are dropped and counted rather than refusing the whole string,
-- because the rest of a friend's screen is still worth having.
local function Keep(settings)
	local kept, count, dropped = {}, 0, 0
	for key, value in pairs(settings) do
		local setting = type(key) == "string" and ns.Restorable(key)
		if setting and type(value) == type(ns.DefaultFor(key)) then
			kept[key] = value
			count = count + 1
		else
			dropped = dropped + 1
		end
	end
	return kept, count, dropped
end

-- A pasted string into a new profile. Returns its name and how many settings
-- it kept and dropped, or nil and why. It does not switch to it.
function Profiles.Import(text)
	local value, why = ns.ProfileCodec.Read(text)
	if not value then
		return nil, why
	end
	if type(value) ~= "table" or type(value.settings) ~= "table" then
		return nil, "that string holds no profile"
	end
	local kept, count, dropped = Keep(value.settings)
	local name = Free(Profiles.Clean(value.name) or IMPORTED)
	local profiles = ns.ProfileStore()
	profiles[name] = kept
	return name, count, dropped
end
