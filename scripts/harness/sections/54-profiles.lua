-- Profiles
--
-- Every setting lives in a named profile and ns.db is the one this character
-- wears, with a metatable sending records through to the account table.
--
-- What is asserted, in the order it is written:
--
--   That ns.db is the profile table itself, named for this character, and
--   that a setting lands in it while a record lands on the account.
--
--   That an export comes back as the same settings under a free name, and
--   that an import keeps only keys a feature registers, of the type it
--   registers, and refuses a string that is not one of ours.
--
--   That copying, switching and deleting do what they say, and that the
--   profile being worn cannot be deleted.
--
--   And the box: the export shows the string, and a paste into the import
--   switches this character to it and asks for one reload.

local H = ...
local ns, check, state = H.ns, H.check, H.state
local Profiles = ns.Profiles

local mine = ns.ProfileName()
local profiles = _G.WarriorKitDB.profiles

----------------------------------------------------------------------
-- Where a key lands
----------------------------------------------------------------------

check(mine == ns.CharacterKey(), "a fresh character does not wear a profile named for it")
check(rawequal(profiles[mine], ns.db), "ns.db is not the profile this character wears")

local locked = ns.db.locked
ns.db.locked = not locked
check(rawget(ns.db, "locked") == not locked, "a setting did not land in the profile")
check(_G.WarriorKitDB.locked == nil, "a setting landed on the account")
ns.db.locked = locked

check(rawget(ns.db, "purse") == nil and type(_G.WarriorKitDB.purse) == "table",
	"a record is in the profile rather than on the account")
check(ns.db.purse == _G.WarriorKitDB.purse, "a record read through ns.db is not the account's")

----------------------------------------------------------------------
-- The string
----------------------------------------------------------------------

ns.db.locked = not ns.DefaultFor("locked")
local text = Profiles.Export()
check(type(text) == "string" and text:sub(1, 4) == "WK1:", "the export is not a WK1 string")

local name, kept, dropped = Profiles.Import(text)
check(name == mine .. " 2", ("an import of a taken name came in as %q"):format(tostring(name)))
check(kept == 1 and dropped == 0,
	("an export of one moved setting imported %s kept and %s dropped")
		:format(tostring(kept), tostring(dropped)))
check(profiles[name] and profiles[name].locked == ns.db.locked,
	"the imported profile does not carry the setting it was exported with")
profiles[name] = nil
ns.db.locked = locked

local forged = ns.ProfileCodec.Write({
	name = "Forged",
	settings = { nonsense = 1, locked = "yes", purse = {}, theme = ns.db.theme },
})
name, kept, dropped = Profiles.Import(forged)
check(name == "Forged" and kept == 1 and dropped == 3,
	"an import kept a key no feature registers, a record, or a value of the wrong type")
check(profiles.Forged and profiles.Forged.purse == nil, "an import wrote a record into a profile")
profiles.Forged = nil

check(Profiles.Import("hello") == nil, "an import took a string that is not ours")
check(Profiles.Import(text:sub(1, -9)) == nil, "an import took a string cut short")

----------------------------------------------------------------------
-- Copy, switch, delete
----------------------------------------------------------------------

check(Profiles.New("Alt") == "Alt" and profiles.Alt ~= nil, "a copy under a new name was not made")
check(Profiles.New("Alt") == nil, "a copy was made over a profile that exists")
check(Profiles.New("   ") == nil, "a copy was made under a blank name")
check(Profiles.Delete(mine) == nil, "the profile this character wears was deleted")

Profiles.Use("Alt")
check(_G.WarriorKitCharDB.profile == "Alt", "switching did not write the name for the next load")
Profiles.Use(mine)
check(Profiles.Delete("Alt") == "Alt" and profiles.Alt == nil, "a profile nobody wears was not deleted")

----------------------------------------------------------------------
-- The box
----------------------------------------------------------------------

local field = Profiles.ShowExport()
check(field:GetText():gsub("%s", "") == Profiles.Export(), "the export box does not hold the export")

Profiles.ShowImport()
field:SetText(Profiles.Export())
local reloads = state.reloads
Profiles.Press()
local arrived = _G.WarriorKitCharDB.profile
check(arrived ~= mine and profiles[arrived] ~= nil, "an import from the box did not switch to it")
check(state.reloads == reloads + 1, "an import from the box did not reload once")
Profiles.Use(mine)
profiles[arrived] = nil

-- Shut, because a window left up covers what the pointer sections below aim at.
_G.WarriorKitProfileString:Hide()
