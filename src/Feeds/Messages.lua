local ADDON, ns = ...

local UI = ns.UI
local Float = ns.Ck.Float

local Messages = {}
ns.Messages = Messages

--------------------------------------------------------------------------
-- What was said, floated
--
-- Your party talking, somebody whispering you, a skill going up and whatever
-- the server announces, sliding in the way a drop does. The second caller of
-- ns.Ck.Float after Feeds/Floats.lua, and it borrows that file's lane rather
-- than describing one of its own.
--
-- **Borrowed, and mirrored.** On the same side the rows go into the drops'
-- column, one under the other with the loot. On the opposite side, which is
-- the default, they get a lane built from the drops' own spec with the side
-- flipped and nothing else changed: the target block is the player block
-- mirrored in the middle of the screen, and this is that for messages. Every
-- number on the loot float's page moves both, because a mirror with numbers of
-- its own is two settings that have to agree.
--
-- **A separate stream, not the chat window.** Chat/Feed.lua claims these same
-- events for the window and nothing here claims, filters or suppresses
-- anything. A line you see float past is still in the window, and the window
-- being hidden or under the pointer is exactly when this earns its place.
--
-- **Its own theme element.** The rows wear "messages" rather than the drops'
-- key, so immersive can take them away and leave nothing else changed. A
-- hidden element is asked about before a push rather than left to the veil,
-- because a veiled row still takes a slot and in a shared column that is a hole
-- between two drops.
--------------------------------------------------------------------------

local DEFAULTS = {
	msgFloat = true,
	-- "opposite" or "same", said of the side the drops come in from.
	msgFloatSide = "opposite",
	msgFloatParty = true,
	msgFloatWhisper = true,
	msgFloatSkill = true,
	-- All of CHAT_MSG_SYSTEM, unfiltered. Somebody coming online, an instance
	-- reset and a server restart are all system lines, and an allow-list of
	-- the client's format strings would be a list of what somebody remembered.
	msgFloatSystem = true,
	-- The least a message stays up for. A longer one stays longer, at the rate
	-- below, up to the ceiling below that.
	msgFloatHold = 3,
	msgFloatText = 16,
}

-- Fifteen characters a second is a slow read of a sentence you did not expect,
-- which is what a message crossing the screen is. The ceiling is so a pasted
-- paragraph does not sit on the screen for a quarter of a minute.
local READ_RATE = 15
local MOST_HOLD = 8

-- Three lines and cut. A fourth is a paragraph, and the window has it whole.
local MOST_LINES = 3

-- Which setting lets each event through, and the ChatTypeInfo key its text is
-- coloured by. `said` is a line somebody said, which has a name over it and
-- the class icon beside it; the rest are the client talking and have neither.
local KINDS = {
	CHAT_MSG_PARTY        = { key = "msgFloatParty", color = "PARTY", said = true },
	CHAT_MSG_PARTY_LEADER = { key = "msgFloatParty", color = "PARTY_LEADER", said = true },
	CHAT_MSG_WHISPER      = { key = "msgFloatWhisper", color = "WHISPER", said = true },
	CHAT_MSG_BN_WHISPER   = { key = "msgFloatWhisper", color = "BN_WHISPER", said = true },
	CHAT_MSG_SKILL        = { key = "msgFloatSkill", color = "SKILL" },
	CHAT_MSG_SYSTEM       = { key = "msgFloatSystem", color = "SYSTEM" },
}

local FLIP = { LEFT = "RIGHT", RIGHT = "LEFT" }

local pool = {}
local out = 0
local mirror, mirrored

--------------------------------------------------------------------------

local function Release(frame)
	out = out - 1
	pool[#pool + 1] = frame
end

-- The lane this message goes into.
--
-- The drops' own lane when the setting says the same side. Otherwise a lane
-- built from the drops' spec with the side flipped, kept for as long as the
-- drops keep theirs: Feeds/Floats.lua throws its lane away when a setting on
-- its page moves, and a different lane coming back from Floats.Lane is how this
-- file hears about it.
local function Lane()
	local drops = ns.Floats.Lane()
	if ns.db.msgFloatSide == "same" then
		return drops
	end
	if mirrored ~= drops then
		local spec = ns.Floats.Spec()
		spec.side = FLIP[spec.side]
		spec.onGone = Release
		mirror, mirrored = Float.Lane(spec), drops
	end
	return mirror
end

local function Build()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	-- The same face a drop has, rim and all, so a class icon beside a name
	-- reads as the same kind of thing as a sword beside its name.
	frame.face = CreateFrame("Frame", nil, frame)
	frame.face:SetPoint("TOPLEFT")
	frame.icon = UI.Icon(frame.face)
	frame.icon:SetAllPoints()
	local rim = UI.SlotEdge(nil)
	frame.face.edges = ns.Outline(frame.face, rim[1], rim[2], rim[3], 1, "OVERLAY")

	frame.name = UI.Label(frame, ns.db.lootFloatName, UI.Color.text, "LEFT", UI.SHADOW)
	frame.text = UI.Wrap(UI.Label(frame, ns.db.msgFloatText, UI.Color.text, "LEFT",
		UI.SHADOW), true)
	frame.text:SetJustifyV("TOP")
	frame.text:SetMaxLines(MOST_LINES)

	ns.Theme.Wear("messages", frame)
	return frame
end

-- Everything on a row, laid out for this message.
--
-- Per message rather than at Build, for the reason Feeds/Floats.lua dresses
-- its rows per drop: the frames are pooled, and one frame carries a whisper
-- with a class icon and then a system line without one.
--
-- The widths are set rather than left to the anchors, because the height is
-- measured off them in the same call and a string with no width yet is one
-- line tall.
local function Dress(frame, name, text, class, r, g, b)
	local db = ns.db
	local width, icon, gutter = db.lootFloatWidth, db.lootFloatIcon, UI.Metric.gutter
	frame:SetSize(width, icon)

	local left = 0
	if class then
		local texture, l, r2, t, b2 = ns.Unit.Spec.Icon(nil, class)
		frame.icon:SetTexture(texture)
		frame.icon:SetTexCoord(l, r2, t, b2)
		frame.face:SetSize(icon, icon)
		ns.EdgeSize(frame.face.edges, ns.Pixel(frame.face), icon, icon)
		frame.face:Show()
		left = icon + gutter
	else
		frame.face:Hide()
	end

	local inner = width - left
	local top = 0
	frame.name:ClearAllPoints()
	if name then
		frame.name:SetFontObject(UI.Font(db.lootFloatName, UI.SHADOW))
		frame.name:SetPoint("TOPLEFT", left, 0)
		frame.name:SetWidth(inner)
		frame.name:SetText(name)
		frame.name:Show()
		top = UI.TextHeight(frame.name, db.lootFloatName)
	else
		frame.name:Hide()
	end

	frame.text:ClearAllPoints()
	frame.text:SetFontObject(UI.Font(db.msgFloatText, UI.SHADOW))
	frame.text:SetPoint("TOPLEFT", left, -top)
	frame.text:SetWidth(inner)
	frame.text:SetText(text)
	frame.text:SetTextColor(r, g, b)
	local height = top + UI.TextHeight(frame.text, db.msgFloatText)

	if class and icon > height then
		height = icon
	end
	frame:SetHeight(height)
	return height
end

--------------------------------------------------------------------------

function Messages.Defaults()
	local copy = {}
	for key, value in pairs(DEFAULTS) do
		copy[key] = value
	end
	return copy
end

-- How long a message of this length holds.
function Messages.Hold(text)
	local hold = #text / READ_RATE
	if hold < ns.db.msgFloatHold then
		hold = ns.db.msgFloatHold
	end
	if hold > MOST_HOLD then
		hold = MOST_HOLD
	end
	return hold
end

-- One message, on screen. The name is nil for a line the client said, and the
-- class is nil wherever it cannot be read, which drops the picture and gives
-- the text the row.
function Messages.Show(name, text, class, colorKey)
	local frame = table.remove(pool) or Build()
	-- Up before it is measured, and invisible, which is where the lane starts
	-- it anyway. A hidden font string is not obliged to say how tall it is, and
	-- UI.TextHeight's floor would lay every message out one line high.
	frame:SetAlpha(0)
	frame:Show()
	local r, g, b = ns.ChatFeed.LineColor(colorKey)
	local height = Dress(frame, name, text, class, r, g, b)
	out = out + 1
	Lane():Push(frame, height, Messages.Hold(text), Release)
	return frame
end

-- The same eleven arguments Chat/Feed.lua names, of which three matter here.
function Messages.OnEvent(event, text, sender, _, _, _, _, _, _, _, _, _, guid)
	local kind = KINDS[event]
	local db = ns.db
	if not kind or not db.msgFloat or not db[kind.key] then
		return false
	end
	if type(text) ~= "string" or text == "" then
		return false
	end
	if ns.Theme.Mode("messages") == "hide" then
		return false
	end

	if not kind.said then
		Messages.Show(nil, text, nil, kind.color)
		return true
	end

	if type(sender) ~= "string" or sender == "" then
		return false
	end
	-- Your own party line comes back to you as an event like anyone's, and a
	-- float of what you just typed tells you nothing. The name as well as the
	-- GUID, because an event the client sent without one is still yours.
	local shown = sender:gsub("%-.*$", "")
	if (guid and guid == UnitGUID("player")) or shown == UnitName("player") then
		return false
	end

	local class = ns.ChatFeed.Class(guid)
	local name = ("|c%s%s|r"):format(ns.Unit.Color.ClassHex(class), shown)
	Messages.Show(name, text, class, kind.color)
	return true
end

-- How many of this file's rows are out, for the harness.
function Messages.Count()
	return out
end

local events = CreateFrame("Frame")
for event in pairs(KINDS) do
	events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, ...)
	Messages.OnEvent(event, ...)
end)
