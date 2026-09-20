-- The second talent group, and the swap into it
--
-- Section 58 drives the resolver: a signature spell outranks the trees, the
-- trees answer for a spec that has no signature, and a character who has
-- committed to nothing gets nil. All of it through Spec.Forget, which is the
-- addon dropping its own held answer on purpose. This is the half of that
-- nobody was calling. Dual specialisation is on this client, a swap spends no
-- talent point and fires no CHARACTER_POINTS_CHANGED, and until
-- ACTIVE_TALENT_GROUP_CHANGED was registered the addon went on answering the
-- spec you had logged in as: the rotation squares, the cooldown row and the
-- debuff list all read a tree you were no longer standing in, until a reload.
--
-- So the swap here is driven the way the client drives one. The talent trees
-- are moved to what the other group holds, which is what GetTalentTabInfo
-- answers once the other group is live, and nothing else is touched: no
-- Spec.Forget, no second login. What has to make the registry answer again is
-- the event and nothing else, and the assertion above the event is the one
-- that fails if somebody drops the registration: the addon is asked while the
-- client already reads as the other spec and has to still answer the old one.
--
-- Both ways of arriving at it are exercised, because they are different
-- mechanisms. The event on its own is what a swap at a trainer's, or from
-- Blizzard's own talent window, looks like. ns.SetActiveSpecGroup is the
-- addon asking for the swap itself, and the client's own answer to that is the
-- event coming back.
--
-- The three shims are then asked on a client that has none of the calls, which
-- is Classic Era and is not a hypothetical: the same files load there. One
-- group, group one, and a setter that says it did not ask, rather than a Lua
-- error in a login handler on a client nobody here logs in to.
--
-- What this cannot prove is that the game agrees, the way no section can. The
-- calls answer what client/18-talents.lua says they answer.

local H = ...
local ns, check, fire = H.ns, H.check, H.fire
local talentTrees, own, model = H.talentTrees, H.own, H.talentModel

local Class, Spec = ns.Class, ns.Class.Spec

local SPECS = Spec.All()
local mine = Spec.Mine()

-- Everything this section drives, read before it drives any of it and handed
-- back at the foot of the file. The trees and the signature spells are the
-- scene every section below this one reads its spec off, and the two numbers
-- on the talent model are what section 67 comes to expecting.
local held = {
	groups = model.groups,
	active = model.active,
	token = Spec.Token(),
	points = {},
	unknown = {},
}
for index, tree in ipairs(talentTrees.player) do
	held.points[index] = tree.points
end
for _, spec in ipairs(SPECS) do
	for _, id in ipairs(spec.signature or {}) do
		held.unknown[id] = own.unknown[id]
	end
end

-- The client reading as one spec and no other: its signature known, every
-- other spec's unknown, and every talent point in its tree. Both readings
-- rather than one, because the resolver takes whichever answers first and a
-- scene that moved only the trees would prove nothing about a class whose
-- specs carry signatures.
local function Stand(spec)
	for _, other in ipairs(SPECS) do
		for _, id in ipairs(other.signature or {}) do
			own.unknown[id] = (other ~= spec) or nil
		end
	end
	for index, tree in ipairs(talentTrees.player) do
		tree.points = (index == spec.tree) and 41 or 0
	end
end

-- What the registry answers for one spec on one field, including the class's
-- own where the spec says nothing about it. A spec that writes no rotation is
-- not a spec with no rotation.
local function Says(spec, field)
	local def = Class.All()[H.PLAYER_CLASS]
	return spec[field] or (def and def[field])
end

local heard = {}
local chat = _G.DEFAULT_CHAT_FRAME.AddMessage
_G.DEFAULT_CHAT_FRAME.AddMessage = function(_, text)
	heard[#heard + 1] = tostring(text)
end

local function said(what)
	for index = 1, #heard do
		if heard[index]:find(what, 1, true) then
			return true
		end
	end
	return false
end

----------------------------------------------------------------------
-- How many groups this character owns
----------------------------------------------------------------------

check(Spec.Groups() == 1,
	("this client came up with %d talent groups and the fixture is a character"
		.. " who has not bought the second"):format(Spec.Groups()))

model.groups = 2
check(Spec.Groups() == 2,
	("the client answers two talent groups and the addon reads %d")
		:format(Spec.Groups()))
check(Spec.Group() == 1,
	("the addon reads group %d and the live one is the first"):format(Spec.Group()))

----------------------------------------------------------------------
-- The swap, as the client performs one
----------------------------------------------------------------------

local other
for _, spec in ipairs(SPECS) do
	if spec ~= mine then
		other = other or spec
	end
end

if mine and other then
	Stand(other)
	check(Spec.Token() == mine.key,
		("the client already reads as %s and the addon answered %s before"
			.. " anything told it the group had moved")
			:format(other.key, tostring(Spec.Token())))

	heard = {}
	model.active = 2
	fire("ACTIVE_TALENT_GROUP_CHANGED", 2)

	check(Spec.Group() == 2,
		("the second group is live and the addon reads group %d"):format(Spec.Group()))
	check(Spec.Token() == other.key,
		("the group changed under a %s and the addon still reads %s")
			:format(other.key, tostring(Spec.Token())))
	check(Class.Of("rotation") == Says(other, "rotation"),
		("the live group is %s and the registry hands back another spec's rotation")
			:format(other.key))
	check(Class.Of("debuffs") == Says(other, "debuffs"),
		("the live group is %s and the registry hands back another spec's debuffs")
			:format(other.key))
	check(said("/reload"),
		"the spec moved under the player and nothing said what to do about the bars")

	-- And back, through the addon's own setter rather than by hand. What the
	-- client does with it is cast a spell and then say so, so the event is the
	-- client's answer here rather than this file's.
	Stand(mine)
	check(ns.SetActiveSpecGroup(1) == true, "the client would not be asked to swap group")
	check(model.activated[#model.activated] == 1,
		("the client was asked for group %s and the addon wanted the first")
			:format(tostring(model.activated[#model.activated])))
	check(Spec.Group() == 1 and Spec.Token() == mine.key,
		("the swap back left the addon in group %d reading %s")
			:format(Spec.Group(), tostring(Spec.Token())))
end

----------------------------------------------------------------------
-- A client with none of the three calls
--
-- Classic Era, where the same files load and nothing about dual spec exists.
-- One group and group one is the answer there, and it is a real answer: a
-- character with one set of talents is standing in it.
----------------------------------------------------------------------

do
	local spec, count = _G.C_SpecializationInfo, _G.GetNumTalentGroups
	_G.C_SpecializationInfo, _G.GetNumTalentGroups = nil, nil

	check(Spec.Groups() == 1,
		("a client with no GetNumTalentGroups was read as %d groups"):format(Spec.Groups()))
	check(Spec.Group() == 1,
		("a client with no GetActiveSpecGroup was read as group %d"):format(Spec.Group()))
	check(ns.SetActiveSpecGroup(2) == false,
		"a client with no SetActiveSpecGroup said the swap had been asked for")

	-- And the other half of what the probe is for: a call that is there and
	-- raises. Both flavours have shipped one, which is why every one of these
	-- goes through pcall rather than a type check alone.
	_G.GetNumTalentGroups = function()
		error("this client has no talent groups")
	end
	check(Spec.Groups() == 1,
		("a GetNumTalentGroups that raises was read as %d groups"):format(Spec.Groups()))

	_G.C_SpecializationInfo, _G.GetNumTalentGroups = spec, count
end

----------------------------------------------------------------------
-- Everything back
----------------------------------------------------------------------

for index, tree in ipairs(talentTrees.player) do
	tree.points = held.points[index]
end
for _, spec in ipairs(SPECS) do
	for _, id in ipairs(spec.signature or {}) do
		own.unknown[id] = held.unknown[id]
	end
end
model.groups, model.active = held.groups, held.active
Spec.Forget()
check(Spec.Token() == held.token,
	("the section came in as %s and left as %s")
		:format(tostring(held.token), tostring(Spec.Token())))

_G.DEFAULT_CHAT_FRAME.AddMessage = chat

print(("groups two talent groups here and one on a client with none of the"
	.. " three calls; %s"):format(other
		and ("a swap into " .. other.key .. " heard on the event")
		or "no second spec this class has to swap into"))
