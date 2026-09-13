-- Who else in the group is on a quest, as Questie hears it.
--
-- Beside 12-questlog.lua rather than inside it, because it is not the client's
-- log: it is another addon's copy of four other people's. The client's half of
-- the answer, IsUnitOnQuest and the parties it names, stays in that file,
-- because it reads the same rows the log does. This file adds its two handles
-- to the H.quests that file built.
--
-- Questie's comms is the other half of who else is on a quest, and the only
-- half that says how far along. It knows one name the client's call does not
-- know here and misses one the client has. The window must end up with three
-- and not four: Sneaky is in both answers and is one person.
--
-- Tusksfirst is you in the party scripts/harness/sections/39-party-raid.lua
-- stands up. Questie hands your own name back with everyone else's, and a row
-- that counted it would say one party member is on every quest in your log.
--
-- Wanderer is nobody in the group. Questie yells your progress to anyone nearby
-- running it and files what they yell back beside the party's, so a stranger on
-- the same quest is in this answer and must not be in the window's.
--
-- Each name holds what Questie stores for it: one entry per objective, by the
-- client's objective number, in the shape
-- Modules/Network/QuestieComms.lua:343 builds in v11.37.1. Sneaky has spoken to
-- Baros and Ironhide has not.

local H = ...
local questie = _G.QuestieLoader

local HEARD
do
	local function Said(fulfilled, required)
		return {
			[1] = { index = 1, type = "e", fulfilled = fulfilled, required = required,
				finished = fulfilled == required },
		}
	end
	HEARD = {
		[102] = {
			Sneaky = Said(1, 1), Tusksfirst = Said(0, 1), Ironhide = Said(0, 1),
			Wanderer = Said(1, 1),
		},
	}
end

questie:ImportModule("QuestieComms").GetQuest = function(_, questId)
	return HEARD[questId]
end

-- The moment a packet lands. QuestieComms calls this straight after it writes
-- one into the remote logs, and Quests/Party.lua hangs its repaint on it at
-- login. The body is Questie's debounced redraw of its own map marks, which is
-- nothing this addon draws, so the stub counts the calls on the module and does
-- nothing else.
local marks = questie:ImportModule("QuestiePartyObjectives")
marks.calls = 0
marks.ScheduleUpdate = function(self)
	self.calls = self.calls + 1
end

-- What each of Questie's party members has told it, by quest id, so a section
-- can change what one of them said.
H.quests.heard = HEARD
-- Questie's party objectives module, so a section can land a packet. Its
-- `calls` is how many times its own redraw ran under whatever hung on it.
H.quests.marks = marks
