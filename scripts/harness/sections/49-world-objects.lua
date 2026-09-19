-- A thing in the world that is not a creature
--
-- An ore vein, a herb, a chest. The client resolves no token for one and fires
-- no event, so 49-world-hover's whole mechanism never hears about it: no
-- UPDATE_MOUSEOVER_UNIT, no `mouseover`, nothing to scan. The client's own
-- tooltip is the only witness. It goes up with the vein's name in it and comes
-- down when the pointer leaves, and those two edges are all the addon has.
--
--   The box. The client's lines, read off its tooltip as it shows, drawn in
--   the addon's box at the pointer, colours and all.
--
--   The parchment, held at no alpha and never hidden, because its OnHide is
--   the only notice that the pointer left. Held only while ours is up, and
--   given back on every way out.
--
--   What is not a vein. A tooltip some frame owns, and one over anything but
--   the world, are somebody else's words and are left alone.
--
--   The sources. Quests/Drops.lua says what a quest wants from the thing, off
--   Questie's `o_` keys, and Character/Skills.lua puts your rank in the skill
--   the client's line names under it as a bar.

local H = ...
local ns, check = H.ns, H.check
local CHURN = H.CHURN

do
	local World, Box, Scan = ns.World, ns.UI.Tooltip, ns.UI.Scan
	local theirs = _G.GameTooltip

	-- The pointer over the world. The stub's hit test answers the frames the
	-- addon drew and WorldFrame is not one of them, so for the length of this
	-- section the client's answer is the one it gives in the game over open
	-- ground, and it is handed back at the end.
	local wasFocus = _G.GetMouseFocus
	local focus = _G.WorldFrame
	_G.GetMouseFocus = function()
		return focus
	end

	local function beside(label)
		for index = 1, Box.Lines() do
			local left, right = Box.Text(index)
			if left == label then
				return right, index
			end
		end
		return nil, nil
	end

	local function drawn()
		local lines = {}
		for index = 1, Box.Lines() do
			lines[index] = Box.Text(index) or ""
		end
		return table.concat(lines, " / ")
	end

	local RED = { 1, 0.13, 0.13 }
	local VEIN = { { "Copper Vein" }, { "Requires Mining", nil, RED } }

	World.Set(true)

	------------------------------------------------------------------
	-- A vein: our box, the client's words, the parchment held
	------------------------------------------------------------------

	H.blizzardObject(VEIN)
	check(Box.IsShown() and Box.Owner() == Box.CURSOR,
		"the client described a vein and the addon put up no box of its own")
	check(Box.Text(1) == "Copper Vein",
		"the vein's box does not open on the client's name for it: " .. drawn())
	check(Box.Text(2) == "Requires Mining",
		"the client's requirement line did not reach the box: " .. drawn())
	local _, read = Scan.Theirs()
	check(read and read[2] and read[2][2] == 1 and read[2][3] < 0.2,
		"the requirement lost its red, which is the client's whole answer to whether you can")
	check(Scan.Holding() and theirs:GetAlpha() == 0,
		"the parchment is still visible beside the addon's box, so the vein is described twice")
	check(theirs:IsShown(),
		"the parchment was hidden rather than held, and its hide is the only notice the pointer left")
	check(beside("Mining") == nil,
		"a skill the player does not have drew a bar: " .. drawn())

	------------------------------------------------------------------
	-- The pointer leaves
	------------------------------------------------------------------

	H.blizzardLeave()
	check(not H.tipSettle(), "the vein's box stayed up after the client took its own down")
	check(not Scan.Holding() and theirs:GetAlpha() == 1,
		"the parchment was left at no alpha, so every other addon's tooltip is now invisible")

	------------------------------------------------------------------
	-- The next vein without a hide in between
	--
	-- The client re-owns its tooltip to describe the next one, and re-owning
	-- hides it. The stub models that, so this is two hovers and two boxes.
	------------------------------------------------------------------

	H.blizzardObject(VEIN)
	H.blizzardObject({ { "Tin Vein" }, { "Requires Mining 65" } })
	check(Box.Text(1) == "Tin Vein", "the second vein's box still says the first: " .. drawn())
	check(Scan.Holding(), "the second vein's parchment is not held")

	------------------------------------------------------------------
	-- Taken over in place
	--
	-- Something writes into the client's tooltip while ours is up and never
	-- hides it. The sweep sees a name that is not the vein's and lets go.
	------------------------------------------------------------------

	_G.GameTooltipTextLeft1:SetText("Somebody Else's Line")
	World.Sweep(0.1)
	check(not Scan.Holding() and theirs:GetAlpha() == 1,
		"the client's tooltip changed subject under the addon and was left invisible")
	H.blizzardLeave()
	H.tipSettle()

	------------------------------------------------------------------
	-- What is not a vein
	------------------------------------------------------------------

	H.blizzardObject(VEIN, _G.WorldFrame)
	check(not Scan.Holding() and not (Box.IsShown() and Box.Owner() == Box.CURSOR),
		"a tooltip a frame owns was taken for a thing in the world")
	H.blizzardLeave()

	focus = nil
	H.blizzardObject(VEIN)
	check(not Scan.Holding(),
		"a screen-anchored tooltip with the pointer off the world was taken for a vein")
	H.blizzardLeave()
	focus = _G.WorldFrame

	World.Set(false)
	H.blizzardObject(VEIN)
	check(not Scan.Holding() and theirs:GetAlpha() == 1,
		"the world hover is off and the addon still held a vein's parchment down")
	H.blizzardLeave()
	World.Set(true)

	------------------------------------------------------------------
	-- Your skill in what it asks for
	------------------------------------------------------------------

	H.blizzardObject({ { "Elven Anvil" }, { "Requires Blacksmithing 275" } })
	local rank, at = beside("Blacksmithing")
	check(rank == "300 / 375",
		"the skill the client's line names is not in the box: " .. drawn())
	local bar = at and Box.Bar(at)
	check(bar and math.abs(bar - 0.8) < 0.001,
		"the skill line is not drawn as a bar: " .. tostring(bar))
	H.blizzardLeave()
	H.tipSettle()

	------------------------------------------------------------------
	-- What a quest wants from it
	------------------------------------------------------------------

	local loader = _G.QuestieLoader
	local tips = loader:ImportModule("QuestieTooltips")
	local player = loader:ImportModule("QuestiePlayer")
	local l10n = loader:ImportModule("l10n")
	local wasLookup, wasLog, wasNames = tips.lookupByKey, player.currentQuestlog, l10n.objectNameLookup

	local crate = { Index = 1, Type = "object", Description = "Supply Crate searched",
		Collected = 1, Needed = 4 }
	tips.lookupByKey = { ["o_501"] = { ["102 1"] = { questId = 102, objective = crate } } }
	player.currentQuestlog = { [102] = {} }
	l10n.objectNameLookup = { ["Supply Crate"] = { 501 } }
	ns.QuestDrops.Forget()

	H.blizzardObject({ { "Supply Crate" } })
	check(drawn():find("The Missing Diplomat", 1, true),
		"a crate a quest wants does not name the quest: " .. drawn())
	check(beside("Supply Crate searched") == "1/4",
		"the crate's objective does not carry its count: " .. drawn())
	H.blizzardLeave()
	H.tipSettle()

	player.currentQuestlog = {}
	ns.QuestDrops.Forget()
	H.blizzardObject({ { "Supply Crate" } })
	check(not drawn():find("The Missing Diplomat", 1, true),
		"a quest handed in is still named over its crate: " .. drawn())
	H.blizzardLeave()
	H.tipSettle()

	tips.lookupByKey, player.currentQuestlog, l10n.objectNameLookup = wasLookup, wasLog, wasNames
	ns.QuestDrops.Forget()

	------------------------------------------------------------------
	-- What the sweep costs over a vein
	------------------------------------------------------------------

	H.blizzardObject(VEIN)
	for _ = 1, 5 do
		World.Sweep(0.1)
	end
	collectgarbage("collect")
	collectgarbage("stop")
	local before = collectgarbage("count")
	for _ = 1, 50 do
		World.Sweep(0.1)
	end
	local churned = collectgarbage("count") - before
	collectgarbage("restart")
	check(churned < CHURN.world,
		("the world hover churned %.2f KB over 50 ticks on a vein, gate is %.2f")
			:format(churned, CHURN.world))
	check(Box.IsShown() and Scan.Holding(), "fifty ticks over a vein that never moved took the box down")

	H.blizzardLeave()
	H.tipSettle()
	_G.GetMouseFocus = wasFocus

	print(("world  a vein or a chest in the addon's box, the parchment held and given back; %.2f KB per 50 ticks")
		:format(churned))
end
