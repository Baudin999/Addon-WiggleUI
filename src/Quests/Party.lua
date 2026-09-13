local ADDON, ns = ...

local Party = {}
ns.QuestParty = Party

local Client = ns.QuestClient

--------------------------------------------------------------------------
-- Who else is on this quest, and how far along they are
--
-- The one fact a quest log has never carried and the one everybody in a party
-- wants: of the four people standing next to you, how many are on this, and
-- which of them still need the wolves. It decides which quest you do next, and
-- without it the answer is somebody reading their log out loud in voice chat.
--
-- **This file is the one source.** The quest window and the tracker over the
-- world both draw it, off the `party` field Quests/Log.lua puts on every quest
-- at each read, and neither of them asks the client or Questie anything about
-- the group. Two drawings of one answer cannot disagree about who is on a quest.
--
-- **Two things can answer and neither of them always can.**
--
-- The client's own IsUnitOnQuest takes a row of your log and a unit and says
-- whether they are on it. It is the better answer for who, because it is true
-- of everybody in the group whatever they are running. It says nothing about
-- how far along they are. It does not exist on every build this addon ships
-- for, which is why it goes through Quests/Client.lua and comes back nil rather
-- than false. On 2.5.6 it is `IsUnitOnQuest(questIndex, "party"..j)`, which is
-- how Blizzard_UIPanels_Game/TBC/QuestLogFrame.lua calls it.
--
-- Questie's comms is the other, and it is the only answer for how far. It
-- broadcasts your log to the group and keeps what it hears back in
-- `QuestieComms.remoteQuestLogs[questId][name]`: one entry per objective, in
-- the client's own objective order, carrying `fulfilled`, `required` and
-- `finished` (Modules/Network/QuestieComms.lua, v11.37.1). That is only ever the
-- people running Questie, so it is a floor rather than a count.
--
-- Both are read and the answers are merged by name, because each one knows
-- somebody the other does not: the client knows the party member with no
-- addons, and Questie knows them on a client that will not say. Merging on the
-- name rather than counting is what stops the same person being counted twice.
--
-- **Questie has heard from more people than your group.** It yells your
-- progress to anyone nearby running it and keeps what they yell back, which its
-- own tooltip marks "(Nearby)". A stranger killing the same boars is not party.
-- So a name Questie hands over counts only when it is somebody in the group,
-- and the roster is what says who that is.
--
-- **Nobody and cannot say are both an empty list.** The row draws no number for
-- either, which is the honest thing: a "0" beside a quest would be this addon
-- claiming it asked and got an answer, and on Classic Era with Questie switched
-- off it asked nothing at all. Party.Describe is where the difference is said
-- out loud, for the panel and for the slash word.
--
-- **Nothing here is a client quest log call.** The one there is, IsUnitOnQuest,
-- is in Quests/Client.lua with the rest of them. What this file names is the
-- group: the roster the addon already keeps, and UnitName and UnitClass for the
-- member's own name and colour.
--------------------------------------------------------------------------

-- Questie's comms, or nil. ns.Questie in Core takes the call this file is about
-- to make, because a module coming back proves nothing on its own.
local function Comms()
	return ns.Questie("QuestieComms", "GetQuest")
end

--------------------------------------------------------------------------

-- Everyone in the group but you, by the name Questie would file them under.
--
-- Off the roster the addon already keeps rather than a walk of the party tokens.
-- It is rebuilt on every roster change, it holds a raid as readily as a party,
-- and the pets it also knows about are not in the list it hands out.
--
-- The key is `Name-Realm` for somebody from another realm and `Name` otherwise,
-- which is the sender Questie's comms is handed by the client and so the key its
-- remote logs are filed under. The short name is kept beside it for drawing.
local function Group()
	local units = ns.Unit.Roster.Units()
	local group = {}
	for at = 1, #units do
		local unit = units[at]
		if unit ~= "player" then
			local name, realm = UnitName(unit)
			if name then
				local _, class = UnitClass(unit)
				local key = (realm and realm ~= "") and (name .. "-" .. realm) or name
				group[key] = { unit = unit, name = name, class = class }
			end
		end
	end
	return group
end

-- The member entry for a key, made the first time either source names them.
local function Member(found, key, who)
	local member = found[key]
	if not member then
		member = { name = who.name, class = who.class }
		found[key] = member
	end
	return member
end

-- What the client says.
local function FromClient(index, group, found)
	for key, who in pairs(group) do
		if Client.OnQuest(index, who.unit) then
			Member(found, key, who)
		end
	end
end

-- One member's objectives as Questie filed them, by the client's objective
-- index. A packet with no count in it answers no line rather than a "nil/nil".
local function Steps(objectives)
	local steps = {}
	if type(objectives) ~= "table" then
		return steps
	end
	for at, objective in pairs(objectives) do
		if type(at) == "number" and type(objective) == "table"
			and type(objective.fulfilled) == "number" and type(objective.required) == "number" then
			steps[at] = {
				fulfilled = objective.fulfilled,
				required = objective.required,
				done = objective.finished and true or objective.fulfilled >= objective.required,
			}
		end
	end
	return steps
end

-- What Questie has heard, kept to the group. Your own name is dropped with the
-- strangers, because the group never holds you: you are on the quest, that is
-- why it is in your log, and a row saying one party member has it when the one
-- it means is you is worse than a row saying nothing.
local function FromQuestie(questId, group, found)
	local comms = Comms()
	if not comms or type(questId) ~= "number" then
		return
	end
	local ok, logs = pcall(comms.GetQuest, comms, questId)
	if not ok or type(logs) ~= "table" then
		return
	end
	for key, objectives in pairs(logs) do
		local who = type(key) == "string" and group[key]
		if who then
			Member(found, key, who).steps = Steps(objectives)
		end
	end
end

local function ByName(a, b)
	return a.name < b.name
end

--------------------------------------------------------------------------

-- Who else in your group is on this quest, in a stable order.
--
-- Each member is `{ name, class, steps }`. `steps` is there only for somebody
-- Questie has heard from, indexed like Client.Objectives, each one
-- `{ fulfilled, required, done }`; a member the client alone names has none,
-- because the client says who and never how far.
--
-- The index is the row of your own log the quest is at, because that is what
-- the client's call takes; the id is what Questie keys its own answer on. Both
-- are passed because the two sources ask different questions of the same quest.
function Party.Members(questId, index)
	local group, found = Group(), {}
	if type(index) == "number" then
		FromClient(index, group, found)
	end
	FromQuestie(questId, group, found)

	local members = {}
	for _, member in pairs(found) do
		members[#members + 1] = member
	end
	-- Sorted, so the same party draws the same lines twice running. `pairs` is
	-- in whatever order the hash happens to be in, and a tracker whose names
	-- shuffle on every repaint reads as three different answers.
	table.sort(members, ByName)
	return members
end

-- The same answer as names alone, for a caller that only wants who.
function Party.On(questId, index)
	local members = Party.Members(questId, index)
	local names = {}
	for at = 1, #members do
		names[at] = members[at].name
	end
	return names
end

-- A member's name in their class colour, as a string a font string draws.
function Party.Named(member)
	return ("|c%s%s|r"):format(ns.Unit.Color.ClassHex(member.class), member.name)
end

-- One member's line under one of your objectives: their name, and their count
-- where the objective has one. Nil where Questie has not said, because a line
-- with a name and no count would read as a member who has done none of it.
--
-- The count is left off an objective that wants one of something, which is
-- every talk-to and every event: "1/1" and "0/1" are a tick and no tick written
-- as a fraction, and the caller draws the tick. The second answer is that tick.
function Party.Step(member, at)
	local step = member.steps and member.steps[at]
	if not step then
		return nil, false
	end
	if step.required > 1 then
		return ("%s %d/%d"):format(Party.Named(member), step.fulfilled, step.required), step.done
	end
	return Party.Named(member), step.done
end

-- Everyone in a list, by coloured name, as one line. Nil for nobody.
function Party.With(members)
	if not members or #members == 0 then
		return nil
	end
	local named = {}
	for at = 1, #members do
		named[at] = Party.Named(members[at])
	end
	return "with " .. table.concat(named, ", ")
end

--------------------------------------------------------------------------
-- Hearing about it
--
-- A party member killing a boar changes nothing in your log, so none of your
-- own quest events fire for it. UNIT_QUEST_LOG_CHANGED fires for their unit
-- when their log changes, which both drawings already repaint on, and it fires
-- before their Questie has told yours the new count. So the count lands in
-- Questie a moment after the last repaint and would sit there unseen until your
-- next event.
--
-- QuestiePartyObjectives:ScheduleUpdate is the moment it lands. QuestieComms
-- calls it straight after writing a packet into its remote logs, and when a
-- player leaves the group (Modules/Network/QuestieComms.lua, v11.37.1), so a
-- listener hung on it runs with the new answer already readable.
--
-- Wrapped rather than handed to hooksecurefunc. The table is Questie's and not
-- the client's, so there is no taint to keep off it, and the harness has no
-- hooksecurefunc to hand: the wrap is what lets a section prove that a packet
-- landing repaints the tracker. The original runs first and its return goes
-- back unchanged.
--
-- Hung at PLAYER_LOGIN, when every addon has loaded whatever order the client
-- loaded them in, and once: the module is one table for the session.
--------------------------------------------------------------------------

local listeners = {}
local hung = false

-- Call fn whenever Questie hears new progress from the group.
function Party.OnHeard(fn)
	listeners[#listeners + 1] = fn
end

local function Heard()
	for at = 1, #listeners do
		listeners[at]()
	end
end

function Party.Hang()
	if hung then
		return true
	end
	local objectives = ns.Questie("QuestiePartyObjectives", "ScheduleUpdate")
	if not objectives then
		return false
	end
	local original = objectives.ScheduleUpdate
	objectives.ScheduleUpdate = function(...)
		local result = original(...)
		Heard()
		return result
	end
	hung = true
	return true
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	Party.Hang()
end)

--------------------------------------------------------------------------

-- Whether anything at all would answer. Both sources are asked about nothing in
-- particular, which is the only way to tell "nobody has it" from "nothing here
-- can say".
function Party.Ready()
	return Client.OnQuest(1, "player") ~= nil or Comms() ~= nil
end

function Party.Describe()
	local client = Client.OnQuest(1, "player") ~= nil
	local questie = Comms() ~= nil
	if client and questie then
		return "the client answers, and Questie fills in how far along they are"
	end
	if client then
		return "the client answers for every member of the group, and nothing says how far along"
	end
	if questie then
		return "only Questie answers, so only party members running it are counted"
	end
	return "nothing on this client can say who else is on a quest"
end
