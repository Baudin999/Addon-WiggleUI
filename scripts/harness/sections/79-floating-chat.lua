-- Floating chat
--
-- Feeds/Messages.lua, the second caller of ns.Ck.Float, which borrows the
-- drops' lane or mirrors it.
--
-- Does the mirror mirror. The default puts messages on the other side from the
-- drops, off the drops' own numbers, so a whisper with the drops coming from
-- the right starts forty in from the left edge and is pinned by that corner.
--
-- Does the same side share the column. A whisper there goes into the drops'
-- lane and sits under the drop already in it, and when it leaves it goes back
-- to its own pool rather than the loot's, which is the per-push onGone.
--
-- Does each switch switch, and does your own line stay off the screen.
--
-- Does a long line hold longer and stop at three lines. The hold is a
-- per-push ttl the lane had no way to take before this file.

local H = ...
local ns, fire, check = H.ns, H.fire, H.check

local Animations = ns.Ck.Animations
local Floats, Messages = ns.Floats, ns.Messages

local FRAME = 1 / 60

local function beat(seconds)
	local tick = ns.UI.Ticking("anim")
	while seconds > 0 do
		local step = (seconds < FRAME) and seconds or FRAME
		if tick then
			tick:Beat(step)
		end
		H.advance(step)
		seconds = seconds - step
	end
end

local function whisper(text, who, guid)
	fire("CHAT_MSG_WHISPER", text, who, nil, nil, nil, nil, nil, nil, nil, nil, nil, guid)
end

-- The drops' numbers, written for the reason 79-floating-messages.lua writes
-- them: the shipped screen is a capture and this section is about the lane.
local WRITTEN = {
	lootFloatSide = "RIGHT", lootFloatEdge = 40, lootFloatRest = 40,
	lootFloatTop = 100, lootFloatGap = 4, lootFloatEnter = 0,
	lootFloatAlpha = 100, lootFloatSeconds = 0.5, lootFloatHold = 1,
	lootFloatStagger = 0.08, lootFloatMost = 5, lootFloatWidth = 380,
	lootFloatIcon = 50, lootFloatName = 20, lootFloatCount = 16,
}
local held = {}
for key, value in pairs(WRITTEN) do
	held[key] = ns.db[key]
	ns.db[key] = value
end
for key, value in pairs(Messages.Defaults()) do
	held[key] = ns.db[key]
	ns.db[key] = value
end
Floats.Apply()
H.chat.classByGuid.M1 = "MAGE"

beat(10)
check(Messages.Count() == 0 and Floats.Count() == 0,
	("%d messages and %d drops were still up at the head of the section")
		:format(Messages.Count(), Floats.Count()))

----------------------------------------------------------------------
-- The mirror
----------------------------------------------------------------------

do
	whisper("need a summon?", "Jaina-Realm", "M1")
	check(Messages.Count() == 1, "a whisper did not float")

	-- The row is found by the element it wears, because the event path hands
	-- nothing back and a handle kept for the harness is a handle nothing else
	-- should hold.
	check(Floats.Count() == 0, "a whisper went into the drops' column on the opposite side")
	beat(0.1)
	local frame
	for _, candidate in ipairs(H.frames) do
		if candidate.wuiWorn == "messages" and candidate:IsShown() then
			frame = candidate
		end
	end
	check(frame ~= nil, "no row wearing the messages element is on screen")
	if frame then
		local point, _, relativePoint, x = frame:GetPoint(1)
		check(point == "TOPLEFT" and relativePoint == "TOPLEFT",
			("with the drops from the right a message is pinned %s to %s, not to the left")
				:format(tostring(point), tostring(relativePoint)))
		check(x > 0, ("a mirrored message is at %s, which is not inside the left edge")
			:format(tostring(x)))
		check(frame.face:IsShown(), "a whisper from a mage has no class icon")
		check(frame.name:GetText():find("Jaina", 1, true) and not frame.name:GetText():find("Realm"),
			("the name over the whisper reads %q"):format(tostring(frame.name:GetText())))
	end

	-- The least hold is three seconds. At two and a half it is still up.
	beat(2.5)
	check(Messages.Count() == 1, "a short whisper went before the three seconds it holds for")
	beat(2)
	check(Messages.Count() == 0, "a short whisper is still up after its hold and fade")
end

----------------------------------------------------------------------
-- The same column
----------------------------------------------------------------------

do
	ns.db.msgFloatSide = "same"
	Floats.Show(_G.WiggleUIItemLink("Aegis"), 1)
	whisper("thanks for the run", "Jaina", "M1")
	check(Floats.Count() == 2 and Messages.Count() == 1,
		("the drops' column holds %d and %d of them are messages; it is two and one")
			:format(Floats.Count(), Messages.Count()))

	-- The drop holds a second and the whisper three, so the drop goes first and
	-- the whisper outlives it in the same column.
	beat(2.2)
	check(Floats.Count() == 1 and Messages.Count() == 1,
		"the whisper did not outlive the drop above it")
	beat(2.5)
	check(Floats.Count() == 0 and Messages.Count() == 0,
		("%d rows and %d messages are left"):format(Floats.Count(), Messages.Count()))
	ns.db.msgFloatSide = "opposite"
end

----------------------------------------------------------------------
-- The switches
----------------------------------------------------------------------

do
	fire("CHAT_MSG_PARTY", "pulling", _G.UnitName("player") .. "-Realm",
		nil, nil, nil, nil, nil, nil, nil, nil, nil, _G.UnitGUID("player"))
	check(Messages.Count() == 0, "your own party line floated")

	fire("CHAT_MSG_PARTY", "wait for mana", "Jaina", nil, nil, nil, nil, nil, nil, nil, nil, nil, "M1")
	fire("CHAT_MSG_SKILL", "Your skill in Swords has increased to 150.")
	fire("CHAT_MSG_SYSTEM", "Jaina has come online.")
	check(Messages.Count() == 3,
		("party, skill and system made %d messages, and it is three"):format(Messages.Count()))
	beat(10)

	for _, key in ipairs({ "msgFloatParty", "msgFloatSkill", "msgFloatSystem", "msgFloatWhisper" }) do
		ns.db[key] = false
	end
	fire("CHAT_MSG_PARTY", "wait for mana", "Jaina", nil, nil, nil, nil, nil, nil, nil, nil, nil, "M1")
	fire("CHAT_MSG_SKILL", "Your skill in Swords has increased to 151.")
	fire("CHAT_MSG_SYSTEM", "Jaina has gone offline.")
	whisper("hello?", "Jaina", "M1")
	check(Messages.Count() == 0,
		("%d messages floated with every switch off"):format(Messages.Count()))
	for _, key in ipairs({ "msgFloatParty", "msgFloatSkill", "msgFloatSystem", "msgFloatWhisper" }) do
		ns.db[key] = true
	end

	ns.db.msgFloat = false
	whisper("hello?", "Jaina", "M1")
	check(Messages.Count() == 0, "a whisper floated with the whole stream off")
	ns.db.msgFloat = true
end

----------------------------------------------------------------------
-- A long line
----------------------------------------------------------------------

do
	local long = ("the quick brown fox jumps over the lazy dog "):rep(12)
	check(Messages.Hold(long) == 30,
		("a %d character line holds %s seconds, and the ceiling is thirty")
			:format(#long, tostring(Messages.Hold(long))))
	check(Messages.Hold("hi") == 3, "a two letter line does not hold the three second floor")

	fire("CHAT_MSG_SYSTEM", long)
	beat(0.1)
	local frame
	for _, candidate in ipairs(H.frames) do
		if candidate.wuiWorn == "messages" and candidate:IsShown() then
			frame = candidate
		end
	end
	check(frame and not frame.face:IsShown() and not frame.name:IsShown(),
		"a system line was drawn with a picture or a name over it")
	if frame then
		local line = frame.text:FontSize() + 0
		check(frame:GetHeight() <= 3 * (line + 4) and frame:GetHeight() > 2 * line,
			("a long line laid its row out %s tall, which is not three lines of %d")
				:format(tostring(frame:GetHeight()), line))
	end
	-- The hold and two seconds for the slide out, off the ceiling rather than a
	-- number of its own, so the next section starts with an empty tween list.
	beat(Messages.Hold(long) + 2)
	check(Messages.Count() == 0 and Animations.Running() == 0,
		("%d messages and %d tweens are left"):format(Messages.Count(), Animations.Running()))
end

for key, value in pairs(held) do
	ns.db[key] = value
end
Floats.Apply()
H.chat.classByGuid.M1 = nil
