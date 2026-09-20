-- Somebody else's character sheet
--
-- The same gear page the six sections above this one measure, drawn for a unit
-- that is not the player. What is under test here is not the page, which those
-- sections already cover; it is the four things the page does differently when
-- it is somebody else's, and the conversation with the server that fills it.
--
-- **The four differences, and each one is a way this could ship wrong.**
--
-- No secure square. A secure button carries `/use <slot>` written at build and
-- the slot number in it is yours whoever the page is about, so a right click on
-- an inspect row would take your own chestpiece off. The attribute cannot be
-- rewritten in combat either, so "clear it when the subject changes" is not an
-- answer. The assertion is that the button carries no `type2` at all and that
-- the window holding it is not a secure window.
--
-- No durability, no countdown, no cooldown arc. All three are read off calls
-- that answer for the player and take no unit, so the failure is not a missing
-- mark: it is your own helmet's wear drawn under their helmet's name.
--
-- Four different badges. Item level and empty slots carry over; durability and
-- your miss chance cannot, and what replaces them is the enchant tally and the
-- gem tally. Those two are the whole argument for the feature, so both are
-- measured against a character deliberately built with one of each missing.
--
-- Two tabs instead of four. Everything the other four read is nil for a unit
-- that is not you.
--
-- **The empty state is a state and it is measured.** The server answers an
-- inspect when it feels like it, so there is a window between the request and
-- the reply where the client knows the unit and nothing about their gear. The
-- page draws twenty empty slots there and the footer says so, and that is
-- asserted before INSPECT_READY is fired rather than after.
--
-- **The player's own sheet is read back at the end.** Two panes now draw off
-- one Character/Worn.lua, and the failure this section exists to catch second
-- is a unit argument that leaked: the sheet reading the target's gear, or the
-- inspect page reading yours. So the sheet is opened after the inspect and its
-- four badges are checked against what client/13-character.lua put on the
-- player.
--
-- What this cannot prove: that the figure is the right person. SetUnit is
-- counted and the token it was handed is read back, and what the client would
-- actually draw is not something this stub knows.

local H = ...
local ns, check, fire = H.ns, H.check, H.fire
local inspect, theirs = H.inspect, H.theirs

local Inspect, Window, Sheet = ns.Inspect, ns.InspectWindow, ns.CharWindow

local slash = _G.SlashCmdList.WIGGLEUI

local heard = {}
local chat = _G.DEFAULT_CHAT_FRAME.AddMessage
_G.DEFAULT_CHAT_FRAME.AddMessage = function(_, text)
	heard[#heard + 1] = tostring(text)
end

local function say(input)
	heard = {}
	slash(input)
end

local function said(what)
	for index = 1, #heard do
		if heard[index]:find(what, 1, true) then
			return true
		end
	end
	return false
end

-- One square off the inspect page, by the inventory slot it is drawn for.
local function square(slot)
	for _, box in ipairs(Window.Pane().squares) do
		if box.entry.slot == slot then
			return box
		end
	end
	return nil
end

-- What one badge on a page is reading, by the word under it.
local function badge(pane, word)
	for index, one in ipairs(pane.head.badges) do
		if one.label:GetText() == word then
			return pane.head.badges[index].value:GetText()
		end
	end
	return nil
end

local function row(groups, title, label)
	for _, group in ipairs(groups) do
		if group.title == title then
			for _, one in ipairs(group.rows) do
				if one.label == label then
					return one
				end
			end
		end
	end
	return nil
end

-- The server answering about whoever was asked. Both halves, because the
-- client does both: the inventory calls start answering, and the event names
-- the GUID it answered about.
local function answer(unit)
	inspect.answered = true
	fire("INSPECT_READY", _G.UnitGUID(unit or "target"))
end

----------------------------------------------------------------------
-- Nothing until somebody asks
----------------------------------------------------------------------

check(Window.Built() == false, "the inspect window was built before anybody asked for one")
check(Inspect.Unit() == nil, "somebody was being inspected at login")
check(Window.Refresh() == false, "a window that does not exist refreshed")

----------------------------------------------------------------------
-- The four refusals
--
-- Every one of these is a reason the server would refuse silently, and the
-- point of the file that holds them is that the player is told which.
----------------------------------------------------------------------

do
	-- Nothing targeted, which is the commonest way the word is typed wrong. The
	-- target is taken away for the length of this block and put back at the foot
	-- of it, because every block under this one is about him.
	local was = H.guids.target
	H.guids.target = nil
	say("inspect")
	check(said("nobody there"), "inspecting with no target said nothing about it")
	check(Window.Built() == false, "a refused inspect built the window anyway")
	H.guids.target = was

	-- A mob, which the client will let you target and will not discuss.
	local ok, why = Inspect.Free("nameplate1")
	check(ok == false, ("inspecting a mob was allowed and said %q"):format(tostring(why)))

	-- Yourself. The client would answer this happily and the answer is your own
	-- sheet drawn in a second window, which is the one refusal here that is a
	-- judgement rather than a server rule.
	--
	-- The player's GUID is put back for the length of the question and taken
	-- away again. client/09-group.lua writes it when a section sets a group and
	-- wipes it again when that section takes the group down, so by here the stub
	-- has a player nobody can look up, which the real client never does; and
	-- every section below this one was written against the stub as it stands.
	local mineGuid = H.guids.player
	H.guids.player = mineGuid or "Player-4-00000001"
	local mine, why2 = Inspect.Free("player")
	check(mine == false and why2:find("Press C", 1, true),
		("inspecting yourself said %q"):format(tostring(why2)))
	H.guids.player = mineGuid
end

----------------------------------------------------------------------
-- Asked, and not answered yet
----------------------------------------------------------------------

do
	inspect.asked, inspect.answered = nil, false
	check(Inspect.Look("target"), "a target the server allows would not be inspected")
	check(inspect.asked == "target",
		("the inspect went to %s"):format(tostring(inspect.asked)))
	check(Window.Shown(), "the window did not come up on a successful inspect")
	check(Window.Describe() == "open on Lightsworn",
		("the window describes itself as %q"):format(Window.Describe()))

	check(Inspect.Waiting(), "the window did not know it was waiting for the server")
	local pane = Window.Pane()
	check(#pane.squares == 20,
		("%d slots were drawn and the client has twenty"):format(#pane.squares))
	local filled = 0
	for _, box in ipairs(pane.squares) do
		if box.icon:IsShown() then
			filled = filled + 1
		end
	end
	check(filled == 0,
		("%d slots drew an icon before the server had said anything"):format(filled))
	check(badge(pane, "item level") == "none",
		("the item level badge read %q before the server answered")
			:format(tostring(badge(pane, "item level"))))
end

----------------------------------------------------------------------
-- The server answers
----------------------------------------------------------------------

do
	answer("target")
	local pane = Window.Pane()
	check(not Inspect.Waiting(), "the window still says it is waiting after the answer")

	local filled = 0
	for _, box in ipairs(pane.squares) do
		if box.icon:IsShown() then
			filled = filled + 1
		end
	end
	check(filled == 4,
		("%d of their slots drew an icon and four are filled"):format(filled))

	-- 115, 105, 120 and 124 over four pieces. The off hand is not counted as
	-- empty because the two hander in the main hand is what fills it, which is
	-- the one rule in Worn.Level that is about the character rather than the
	-- slot and the one most likely to be lost when a unit is threaded through.
	check(badge(pane, "item level") == "116.0",
		("their item level read %q and four pieces average 116")
			:format(tostring(badge(pane, "item level"))))
	check(badge(pane, "empty") == "12",
		("%s slots read as empty; sixteen count and four are filled")
			:format(tostring(badge(pane, "empty"))))

	-- Four of their slots take an enchant and one carries one. The cloak's is
	-- seeded here rather than in the client, because an enchant's name only
	-- exists in a tooltip and what the client carries is the id in the link.
	H.tooltips.item[theirs[15]] = { { "Cloak of the Righteous" },
		{ "Enchanted: Greater Agility" } }
	Window.Refresh()
	check(badge(pane, "enchants") == "1/4",
		("their enchants read %q and one of four enchantable slots is done")
			:format(tostring(badge(pane, "enchants"))))
	check(badge(pane, "gems") == "0/1",
		("their gems read %q and the helmet has one empty hole")
			:format(tostring(badge(pane, "gems"))))

	check(_G.UnitName("target") == "Lightsworn"
		and ns.Theirs.Line("target"):find("The Silver Hand", 1, true) ~= nil,
		("the line under their name is %q and has no guild in it")
			:format(ns.Theirs.Line("target")))
end

----------------------------------------------------------------------
-- The three marks an inspect page does not draw
----------------------------------------------------------------------

do
	local pane = Window.Pane()
	local wear, arcs, oil = 0, 0, 0
	for _, box in ipairs(pane.squares) do
		if box.wear:IsShown() then
			wear = wear + 1
		end
		if box.arc then
			arcs = arcs + 1
		end
		if box.oil then
			oil = oil + 1
		end
	end
	check(wear == 0,
		("%d of their rows drew a durability line, and the client answers durability for you alone")
			:format(wear))
	check(arcs == 0,
		("%d cooldown arcs were built on a page whose slots are not yours"):format(arcs))
	check(oil == 0, ("%d of their weapons counted down a stone of yours"):format(oil))
	check(#pane.cooling == 0,
		("the trinket sweep took %d of their squares"):format(#pane.cooling))
end

----------------------------------------------------------------------
-- Nothing on the page is protected
----------------------------------------------------------------------

do
	local pane = Window.Pane()
	local armed = 0
	for _, box in ipairs(pane.squares) do
		if box.button:GetAttribute("type2") or box.button:GetAttribute("target-slot") then
			armed = armed + 1
		end
	end
	check(armed == 0,
		("%d inspect squares carry a use attribute, and every one of them would spend a slot of yours")
			:format(armed))

	-- Shift over a piece links it, which is the one thing the square does
	-- answer and is what the client's own inspect frame answers with.
	local before = #H.linked
	square(5).button:Click("LeftButton")
	check(#H.linked == before + 1 and H.linked[#H.linked] == theirs[5],
		("a click on their chest linked %s"):format(tostring(H.linked[#H.linked])))

	-- And an empty slot links nothing rather than linking nil.
	before = #H.linked
	square(7).button:Click("LeftButton")
	check(#H.linked == before, "a click on an empty inspect slot linked something")
end

----------------------------------------------------------------------
-- The column
----------------------------------------------------------------------

do
	local pane = Window.Pane()
	check(#pane.tabs.buttons == 2,
		("the inspect column carries %d tabs and two of the four are answerable")
			:format(#pane.tabs.buttons))

	local gear = ns.Theirs.Gear("target")
	local cloak = row(gear, "What is enchanted", "back")
	check(cloak and cloak.value == "Greater Agility",
		("their cloak's enchant read %q"):format(cloak and cloak.value or "nothing"))
	local chest = row(gear, "What is enchanted", "chest")
	check(chest and chest.value == "nothing on it",
		("their bare chest read %q rather than saying it is bare")
			:format(chest and chest.value or "nothing"))
	local helm = row(gear, "What is socketed", "head")
	check(helm and helm.value == "0 of 1",
		("their helmet's sockets read %q"):format(helm and helm.value or "nothing"))

	-- A paladin's trees, set here rather than taken from the client stub.
	-- 39-party-raid.lua puts a druid's in the inspect tables to drive a role
	-- and leaves them there, which is correct for that section and would make
	-- this one read a druid's spec off a paladin.
	--
	-- What is actually under test is the flag: the client keeps one set of
	-- inspect tables, the player is a warrior, and a reader that dropped the
	-- flag would come back with Arms rather than with any of these.
	H.talentTrees.inspect = {
		{ name = "Holy", icon = "Interface\\Icons\\Spell_Holy_HolyBolt", points = 8 },
		{ name = "Protection", icon = "Interface\\Icons\\Spell_Holy_DevotionAura", points = 43 },
		{ name = "Retribution", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", points = 0 },
	}
	local talents = ns.Theirs.Talents("target")
	local spec = row(talents, "Talents", "spec")
	check(spec and spec.value == "Protection",
		("their spec read %q and forty-three of their fifty-one points are in Protection")
			:format(spec and spec.value or "nothing"))
	local tree = row(talents, "Talents", "Holy")
	check(tree and tree.value == "8",
		("their first tree read %q"):format(tree and tree.value or "nothing"))
	check(spec.note == "51 points spent.",
		("the spec row says %q"):format(tostring(spec.note)))
end

----------------------------------------------------------------------
-- It opens and shuts in a fight
--
-- This is the assertion the whole no-secure-square arrangement exists for and
-- it is the one that would have failed on the first pull. Your own sheet needs
-- a snippet on a key to come up mid fight, because a window holding a
-- protected frame is protected itself; a page with no secure button on it is
-- an ordinary window and the client refuses none of this.
----------------------------------------------------------------------

do
	local real = _G.InCombatLockdown
	_G.InCombatLockdown = function() return true end

	Window.Close()
	check(not Window.Shown(), "the window would not close in a fight")
	check(Inspect.Look("target"), "an inspect was refused in a fight")
	check(Window.Shown(), "the window would not open in a fight")
	answer("target")
	check(Window.Refresh(), "the window would not repaint in a fight")
	check(Window.Fit(), "the window would not lay itself out in a fight")

	_G.InCombatLockdown = real
end

----------------------------------------------------------------------
-- Their gear moves while you are looking at it
----------------------------------------------------------------------

do
	inspect.asked = nil
	fire("UNIT_INVENTORY_CHANGED", "target")
	check(inspect.asked == "target",
		"the server said their gear moved and nothing asked it again")

	-- And the same event about somebody else asks nothing. Every unit frame in
	-- the addon is listening for this one and most of them fire about the
	-- player.
	inspect.asked = nil
	fire("UNIT_INVENTORY_CHANGED", "player")
	check(inspect.asked == nil,
		"your own gear moving sent an inspect request about somebody else")
end

----------------------------------------------------------------------
-- The cross, and the Escape key
--
-- Neither comes through Window.Close: both call Hide on the frame itself, so
-- the hand-back has to hang off the frame's own script or it never runs.
----------------------------------------------------------------------

do
	check(Window.Shown(), "the window was already down before the cross was tried")
	_G.WiggleUIInspect:Hide()
	check(not Window.Shown(), "hiding the frame left the window reading as open")
	check(Inspect.Unit() == nil,
		"the window went down by its own frame and the inspect was left held")

	Inspect.Look("target")
	answer("target")
	check(Window.Shown(), "the window would not reopen after being hidden")
end

----------------------------------------------------------------------
-- They walk away
----------------------------------------------------------------------

do
	-- The token stays and the person behind it changes, which is what tabbing
	-- to something else does. Blizzard's own inspect frame closes on this and
	-- so does ours, because a window that redrew as whoever you tabbed to would
	-- be a window that lies without saying anything.
	H.guids.target = "Player-4-00000099"
	heard = {}
	fire("PLAYER_TARGET_CHANGED")
	check(not Window.Shown(), "the window stayed open on somebody who had gone")
	check(said("is gone"), "the window closed without saying whose sheet went")
	check(Inspect.Unit() == nil, "the subject was kept after the window closed")
	H.guids.target = "Player-4-00000042"
end

----------------------------------------------------------------------
-- Finding somebody by name
----------------------------------------------------------------------

do
	check(Inspect.Find("lightsworn") == "target",
		"a name typed in lower case did not resolve to the unit carrying it")
	check(Inspect.Find("Nobody At All") == nil, "a name nobody carries resolved to a unit")

	say("inspect Nobody At All")
	check(said("Nobody At All"), "the word said nothing about a name it could not place")
end

----------------------------------------------------------------------
-- The player's own sheet still reads the player
----------------------------------------------------------------------

do
	inspect.asked, inspect.answered = nil, false
	Inspect.Look("target")
	answer("target")

	Sheet.Show()
	local mine = Sheet.Pane()
	check(badge(mine, "item level") == "60.0",
		("your own sheet read %q while an inspect was open, and your four pieces are level 60")
			:format(tostring(badge(mine, "item level"))))
	check(badge(mine, "durability") ~= "none",
		"your own sheet lost its durability badge while an inspect was open")

	local helm
	for _, box in ipairs(mine.squares) do
		if box.entry.slot == 1 then
			helm = box
		end
	end
	check(helm.name:GetText() == "Lionheart Helm",
		("your own helmet row read %q"):format(tostring(helm.name:GetText())))
	check(helm.button:GetAttribute("type2") == "macro",
		"your own gear squares lost the secure half that uses what is in them")
	Sheet.Hide()
end

----------------------------------------------------------------------
-- Shut, and handed back
----------------------------------------------------------------------

do
	local pane = Window.Pane()
	-- Read before the close, because closing hands the inspect back and the
	-- client stops answering about them the moment it does.
	local reading = ns.Theirs.Describe("target")
	Window.Close()
	check(not Window.Shown(), "the window would not close")
	check(Inspect.Unit() == nil, "closing the window kept the inspect")
	check(inspect.asked == nil, "the inspect was never handed back to the client")
	check(Window.Paint() == false, "a shut inspect window painted on being asked directly")

	-- Through the client rather than by calling Refresh, because what is being
	-- checked is that the listener is on the event at all.
	fire("INSPECT_READY", "Player-4-00000042")
	check(not Window.Shown(), "an event opened a window nobody asked for")

	print(("inspect %d slots drawn for %s, and no secure square among them")
		:format(#pane.squares, reading))
end

_G.DEFAULT_CHAT_FRAME.AddMessage = chat
