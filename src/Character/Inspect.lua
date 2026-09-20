local ADDON, ns = ...

local Inspect = {}
ns.Inspect = Inspect

--------------------------------------------------------------------------
-- Whose sheet the second window is showing
--
-- One person at a time, held as a unit token and the GUID that token was
-- pointing at when it was picked, and the conversation with the server that
-- fills it in.
--
-- **This is not Unit/Spec.lua's inspect and the two must not be confused.**
-- That one is opportunistic: it walks whoever is on a meter row, asks about
-- anyone it has no icon for, gives up on anyone out of range for a minute, and
-- hands the inspect straight back the moment the three tree totals have been
-- read, because all it wants is one icon per person. Its queue exists so that
-- fifteen rows do not each ask.
--
-- This one is a person asking about a person. There is no queue, no retry gap
-- and nothing opportunistic: a player pointed at somebody and wants that
-- somebody's gear on the screen. So it asks immediately, it asks again when the
-- window is opened on them, and it holds the inspect rather than clearing it,
-- because the client keeps one set of inspect tables and answers the talent
-- calls about whoever was last asked for. Clearing would empty the talents tab
-- under the reader.
--
-- The two do share the client, which is the one thing that can go wrong between
-- them: an inspect the meter starts lands INSPECT_READY for a GUID this file
-- did not ask about, and one this file starts lands one the meter did not.
-- Both ends compare the GUID the event carries against the one they asked
-- about, which is what the event carries it for.
--
-- **The token is held and the GUID is what is checked.** "target" is a slot
-- rather than a person: inspect your tank, tab to a boss, and the window would
-- redraw as the boss without anything having said so. So the GUID is taken at
-- the moment the person is picked and compared on every event that could have
-- moved the token underneath it. Where they no longer match, the window says
-- who it was showing and closes, which is what Blizzard's own inspect frame
-- does and for the same reason.
--
-- **Nothing here is on a ticker.** The gear of somebody you are inspecting
-- changes when the server says it did, which is UNIT_INVENTORY_CHANGED on their
-- unit, and the window repaints on that. A window nobody has open is not
-- repainted at all.
--------------------------------------------------------------------------

-- CheckInteractDistance's inspect index, which is about twenty eight yards.
-- The same number Unit/Spec.lua uses and for the same reason: it is the range
-- the server will answer an inspect at.
local INSPECT_RANGE = 1

-- How long a request waits before this file stops calling itself pending.
--
-- There is no event for an inspect the client decided not to answer. The
-- subject walks out of range, or zones, and INSPECT_READY simply never comes.
-- Without an expiry the window would say "waiting for the server" for the rest
-- of the session. Five seconds is Unit/Spec.lua's number and it is generous:
-- an inspect that is going to be answered is answered inside one.
local TIMEOUT = 5

-- Who the window is about, and what they were when they were picked. All four
-- move together and are wiped together, so a token here is a name here.
local unit, guid, name, askedAt

-- The four calls, taken into locals the way Unit/Spec.lua takes the same ones.
--
-- Not because anything here is on a ticker, which is Spec's reason, but because
-- none of the four is on the addon's list of names an installed addon calls
-- unguarded and every one of them is missing from the older client outright.
-- A name reached through _G is a name this file has to ask about before it
-- calls, and asking is what the four guards below do.
local CanInspect = _G.CanInspect
local NotifyInspect = _G.NotifyInspect
local ClearInspectPlayer = _G.ClearInspectPlayer
local CheckInteractDistance = _G.CheckInteractDistance

--------------------------------------------------------------------------
-- Picking somebody
--------------------------------------------------------------------------

-- Whether this unit can be inspected at all, and why not where it cannot.
--
-- Every one of these is a refusal the server would make silently, and a window
-- that opened on a blank sheet because the subject was thirty yards away would
-- read as the feature being broken. CanInspect is the client's own answer and
-- is asked last, because the four above it are the ones worth a sentence.
function Inspect.Free(who)
	if not who or not UnitExists(who) then
		return false, "there is nobody there to inspect."
	end
	if not UnitIsPlayer(who) then
		return false, "only another player has a character sheet."
	end
	if UnitIsUnit(who, "player") then
		return false, "that is you. Press C for your own sheet."
	end
	if type(CheckInteractDistance) == "function"
		and not CheckInteractDistance(who, INSPECT_RANGE) then
		return false, ("%s is too far away to inspect."):format(UnitName(who) or "they")
	end
	if type(CanInspect) ~= "function" or not CanInspect(who, false) then
		return false, ("the server will not let you inspect %s.")
			:format(UnitName(who) or "them")
	end
	return true
end

-- The request itself, made every time rather than throttled.
--
-- Somebody typed the word or clicked the menu entry, so the answer they want is
-- the current one. The client throttles inspection on its own and a second ask
-- inside its window is simply not answered, which costs a repaint that draws
-- what was already there.
local function Notify()
	if type(NotifyInspect) ~= "function" or not unit then
		return false
	end
	askedAt = GetTime()
	NotifyInspect(unit)
	return true
end

-- A unit token for a name typed at the slash word.
--
-- Your target first, because that is what "inspect Bob" means when Bob is who
-- you are looking at, and the group after it, so the word works off the raid
-- frames without targeting anybody. Case is ignored on the way in, because
-- nobody types a guild mate's name with the capital.
--
-- There is no third place to look. The client has no call that turns a name
-- into a unit for somebody who is neither your target nor in your group, and an
-- inspect needs a unit: a name alone is a person the server will not discuss.
function Inspect.Find(who)
	if type(who) ~= "string" or who == "" then
		return nil
	end
	local wanted = who:lower()
	if UnitExists("target") and (UnitName("target") or ""):lower() == wanted then
		return "target"
	end
	local roster = ns.Unit.Roster.Units()
	for index = 1, #roster do
		local token = roster[index]
		if (UnitName(token) or ""):lower() == wanted then
			return token
		end
	end
	return nil
end

-- Point the window at somebody. Refused with a sentence rather than silently,
-- because every reason it can be refused is one the player can act on.
function Inspect.Look(who)
	local free, why = Inspect.Free(who)
	if not free then
		ns.Print(why)
		return false
	end
	unit, guid, name = who, UnitGUID(who), UnitName(who)
	Notify()
	ns.InspectWindow.Open()
	return true
end

-- Ask again about whoever is already up.
--
-- Called when the server says their gear moved, which is the one event that
-- says the answer this window is drawing has gone stale. A repaint on its own
-- would not do: the inventory calls read the client's inspect tables, and those
-- are only refilled by another request being answered.
function Inspect.Again()
	if not unit then
		return false
	end
	if not Inspect.Free(unit) then
		return false
	end
	return Notify()
end

-- Forget them. The inspect is handed back here and nowhere else: while the
-- window is up the client's inspect tables are what the talents tab reads, so
-- clearing on the answer the way Unit/Spec.lua does would empty that tab under
-- the reader.
function Inspect.Drop()
	unit, guid, name, askedAt = nil, nil, nil, nil
	if type(ClearInspectPlayer) == "function" then
		pcall(ClearInspectPlayer)
	end
	return true
end

--------------------------------------------------------------------------
-- Reading it back
--------------------------------------------------------------------------

function Inspect.Unit()
	return unit
end

function Inspect.Name()
	return name
end

-- Whether the server has been asked and has not answered yet, which is the one
-- state the window has a sentence for. False again once the wait has run out,
-- because an answer that is never coming is not a wait.
function Inspect.Waiting()
	if not unit or not askedAt then
		return false
	end
	return (GetTime() - askedAt) < TIMEOUT
end

-- Whether the token still points at the person it was pointed at. Everything
-- that can move a token underneath this file asks, and the answer is what
-- decides whether the window stays open.
function Inspect.Held()
	if not unit or not guid then
		return false
	end
	if not UnitExists(unit) then
		return false
	end
	return UnitGUID(unit) == guid
end

function Inspect.Describe()
	if not unit then
		return "nobody"
	end
	if not Inspect.Held() then
		return ("%s, who has gone"):format(name or "somebody")
	end
	if Inspect.Waiting() then
		return ("%s, and the server has not answered yet"):format(name or "somebody")
	end
	return ns.Theirs.Describe(unit)
end

--------------------------------------------------------------------------
-- The client answering
--
-- Four events and one rule: nothing here does anything while the window is
-- shut, because a window nobody has open is a repaint with no reader.
--
-- INSPECT_READY is the answer and it names the GUID it answered about, which
-- may not be the one this file asked for: Unit/Spec.lua inspects whoever is on
-- a meter row and any other addon on the machine can ask as well.
--
-- PLAYER_TARGET_CHANGED and GROUP_ROSTER_UPDATE are the two ways a token stops
-- meaning the person it meant. Blizzard's own inspect frame closes on both and
-- this does the same, with a line saying whose sheet went, because a window
-- that emptied itself without a word reads as a bug.
--------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("INSPECT_READY")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("UNIT_INVENTORY_CHANGED")

local function Gone()
	if not unit or Inspect.Held() then
		return false
	end
	local who = name
	Inspect.Drop()
	if ns.InspectWindow.Shown() then
		ns.InspectWindow.Hide()
		ns.Print(("%s is gone, so their sheet closed."):format(who or "whoever it was"))
	end
	return true
end

events:SetScript("OnEvent", function(_, event, arg)
	if event == "INSPECT_READY" then
		if arg and guid and arg == guid then
			askedAt = nil
			ns.InspectWindow.Arrived()
		end
		return
	end
	if event == "UNIT_INVENTORY_CHANGED" then
		if unit and arg == unit and ns.InspectWindow.Shown() then
			-- Both, and in this order. The request is what makes the client's
			-- tables current and its answer comes back as INSPECT_READY, which
			-- repaints again; the repaint here is so the window is not showing
			-- the old reading for however long the server takes.
			Inspect.Again()
			ns.InspectWindow.Refresh()
		end
		return
	end
	Gone()
end)
