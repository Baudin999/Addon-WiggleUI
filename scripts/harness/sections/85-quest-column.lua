-- The addon's own quest tracker
--
-- Four questions no amount of reading Quests/Column.lua will answer.
--
-- Does the scope move when you walk. The tracker is the quests the client filed
-- under the place you are standing in, and the whole of that is one string
-- compared against another. Both come off this client, so a comparison that had
-- drifted onto an area id, a map id or Questie's name for the zone would still
-- draw a column: it would draw the wrong one, in the one place a reader has no
-- way to check it, and only ever in a zone nobody wrote the fixture for.
--
-- Does a header that is not a place take everything off it. The client's log
-- header is a sort category rather than a zone, so standing somewhere no header
-- names has to leave an empty tracker rather than the last zone's quests, and
-- an empty tracker is hidden rather than drawn as a rectangle of shade.
--
-- Does the drawing follow the model. Column.Quests answering two quests and the
-- column drawing one is a whole class of bug that reads correctly from inside
-- the file, so the rows are counted off the frames rather than off the list.
--
-- And does a click reach the window. Clicking a row is Quests/Tracker.lua's
-- existing swap arriving from this addon's own frame instead of Questie's, and
-- the failure worth catching is the one that already shipped once: the gesture
-- going to Blizzard's log in the attic rather than to the window that is
-- actually on the screen.
--
-- Everything this moves is put back at the foot of the file: where you are
-- standing, the tracker switch, the lock, the pin on one quest and the whole of
-- the log.

local H = ...
local ns, check = H.ns, H.check
local quests, mouse = H.quests, H.mouse

local Column, Log = ns.QuestColumn, ns.QuestLog

local standing = quests.standing
local WAS_MAP = standing.map
local WAS_OFF = ns.db.questsTrackerOff
local WAS_LOCK = ns.db.locked
local WAS_TABS = ns.db.questsTabs
local WAS_OPEN = ns.QuestWindow.Shown()

-- Three places, and every one of them is a map id the client fixtures already
-- answer a name for. Two are zones the log has a header for and the third is
-- not, which is the case the scope exists to refuse.
local WESTFALL, ELWYNN, STORMWIND = 52, 37, 1453

----------------------------------------------------------------------
-- Reading the column off the screen
----------------------------------------------------------------------

ns.db.locked = true
ns.db.questsTrackerOff = true
standing.map = WESTFALL
check(Column.Apply(),
	"the tracker was switched on in Westfall and put nothing on the screen")

local frame = _G.WarriorKitQuestColumn
check(frame ~= nil, "the tracker is on the screen and has no name to find it by")

-- Everything on the tracker that is not the zone strip: the tally over the
-- rows and the stack under it.
--
-- Found rather than indexed, because the rim a placeable frame wears while it
-- is being dragged is a child too and which of them was made first is not a
-- fact worth writing a test against. The strip is skipped by name, which is the
-- one child of the tracker that has one.
local function trunk()
	for _, child in ipairs(frame.children) do
		if child ~= _G.WarriorKitQuestZones and #child.children > 0 then
			return child
		end
	end
	return nil
end

-- The stack's own frame, which is the one child of that with rows under it.
local function canvas()
	for _, child in ipairs(trunk().children) do
		if #child.children > 0 then
			return child
		end
	end
	return nil
end

-- What the column is drawing, top down, as one string per row on the screen.
--
-- Off the frames rather than off Column.Quests, which is the point: a scope
-- that answered correctly and a paint that drew last zone's rows would pass
-- every assertion made against the model.
local function drawn()
	local out = {}
	for _, row in ipairs(canvas().children) do
		if row.shown then
			for _, text in ipairs(row.regions) do
				if text.kind == "fontstring" and text.text ~= "" then
					out[#out + 1] = text.text
				end
			end
		end
	end
	return out
end

-- One row of the column by the string it is drawing, so a click can be aimed at
-- the quest it is meant for rather than at whichever frame the pool happens to
-- have put first.
local function row(said)
	for _, kid in ipairs(canvas().children) do
		if kid.shown then
			for _, text in ipairs(kid.regions) do
				if text.kind == "fontstring" and text.text == said then
					return kid
				end
			end
		end
	end
	return nil
end

-- A left click on one row, both edges, the way the client delivers one. The
-- down edge does nothing on a row registered for the up edge and it is sent
-- anyway, because a row that answered the wrong edge is the failure this pair
-- exists to catch.
local function press(target)
	target:Click("LeftButton", true)
	target:Click("LeftButton", false)
end

-- What the section saw, in the tracker's own words, so the handover line is the
-- reading a player would get rather than a number written out here.
local seen = {}

local function says(said)
	for _, line in ipairs(drawn()) do
		if line == said then
			return true
		end
	end
	return false
end

----------------------------------------------------------------------
-- The zone you are standing in
----------------------------------------------------------------------

-- Westfall holds one quest by the time this runs, because 47-quest-log
-- abandoned the other one, and that quest has two objectives. Three rows. The
-- count is the assertion: a tracker that drew the names and lost the objectives
-- is a tracker that says which quests you are on and nothing about what is left
-- of them.
check(#Column.Quests() == 1,
	("%d quests are on the tracker in Westfall, where the log has one")
		:format(#Column.Quests()))

-- The words have a rectangle to stand in.
--
-- A frame with no height is not drawn on this client and neither is anything
-- anchored inside it, and everything on this tracker that is not a zone tab
-- lives inside one frame: the tally and every row under it. That frame shipped
-- with a width and no height, which is a tracker drawing its zone tabs down
-- the left of an empty column, and every other assertion in this section
-- passed while it did. They are all made against the model and the pool, and
-- both were right. Section 89 sweeps this rule over the whole addon and cannot
-- reach here, because the foot of this file puts the tracker away again.
do
	local wide, tall = trunk():GetWidth(), trunk():GetHeight()
	check(wide > 0 and tall > 0,
		("the tracker's words stand in a frame measuring %.1f by %.1f")
			:format(wide, tall))
end
check(#drawn() == 3,
	("the column drew %d rows in Westfall, where one quest and two objectives is three")
		:format(#drawn()))
check(says("The Defias Brotherhood"),
	"the quest the client filed under Westfall is not on the tracker in Westfall")
check(says("Defias Trapper slain: 5/12") and says("Trapper's Rope: 3/3"),
	"a quest is on the tracker without the objectives it still wants")
check(not says("The Missing Diplomat"),
	"a quest filed under another zone is on the tracker in Westfall")

-- The reading the options page draws, which is the only place a player finds
-- out what the tracker thinks it is looking at.
check(Column.Describe() == "one quest, in Westfall",
	("the reading says %q"):format(Column.Describe()))
seen[#seen + 1] = ("%s over %d rows"):format(Column.Describe(), #drawn())

----------------------------------------------------------------------
-- How full the log is, over the quests
----------------------------------------------------------------------

-- The same reading the quest window puts in its title bar, off the same
-- Log.Full, and it is chrome rather than a row: it is anchored above the stack,
-- so nothing that counts the rows on this column has to subtract it and no
-- click can land on it.
do
	-- Found by walking for the one child with no rows under it, which is what
	-- "not a row" means here: the stack is the child that has children, and
	-- this is the other one.
	local line = nil
	for _, child in ipairs(trunk().children) do
		if #child.children == 0 then
			for _, region in ipairs(child.regions) do
				if region.kind == "fontstring" and region.text ~= "" then
					line = region.text
				end
			end
		end
	end
	check(line == "3/25 quests", ("the tracker's first line says %q"):format(tostring(line)))
	check(#drawn() == 3,
		("the tally landed among the rows: %d rows where three is right")
			:format(#drawn()))
end

----------------------------------------------------------------------
-- Walking somewhere else
----------------------------------------------------------------------

-- Nothing is told that you moved. ns.QuestHere holds its answer on the map id
-- and re-derives when the id moves, so a walk is the client answering a new
-- number and the tracker asking again on its next event.
standing.map = ELWYNN
check(Column.Refresh(), "walking into Elwynn Forest emptied the tracker")
check(says("The Missing Diplomat") and says("Wanted: Hogger"),
	"the two quests filed under Elwynn Forest are not on the tracker there")
check(not says("The Defias Brotherhood"),
	"a Westfall quest is still on the tracker after walking into Elwynn Forest")
check(#drawn() == 4,
	("the column drew %d rows in Elwynn Forest, where two quests and two objectives is four")
		:format(#drawn()))
seen[#seen + 1] = ("%s over %d rows"):format(Column.Describe(), #drawn())

----------------------------------------------------------------------
-- A header that is not a place
----------------------------------------------------------------------

-- Stormwind City. The client has a map of it and the log has no header for it,
-- which is the ordinary case for two thirds of the zones in the game and the
-- one that has to leave the tracker empty rather than showing the last zone.
standing.map = STORMWIND
check(Column.Refresh(),
	"the tracker went down in a city, taking the zone strip with it")
check(#Column.Quests() == 0,
	("%d quests are on the tracker in a zone the log has no header for")
		:format(#Column.Quests()))
check(#drawn() == 0,
	("%d rows are on the tracker in a zone the log has no header for")
		:format(#drawn()))
-- Up rather than down, and the zone strip is the whole reason. The old rule
-- was that a tracker with nothing on it is a rectangle of shade saying you are
-- not on a quest here; with tabs on it, taking it away in a city takes away
-- the control you use to look at anywhere else.
check(frame:IsShown(),
	"the tracker is down in a city, so there are no tabs to pick a zone with")
check(Column.Describe() == "nothing in your log is in Stormwind City",
	("the reading says %q"):format(Column.Describe()))
seen[#seen + 1] = Column.Describe()

----------------------------------------------------------------------
-- A header the client files under a subzone
----------------------------------------------------------------------

-- The first two levels of every character in the game. The client files the
-- starting quests under Northshire Valley, Coldridge Valley, Deathknell and the
-- rest; vanilla draws no map of any of them, so C_Map answers with the zone
-- above and the header and the map name never meet. A tracker that only
-- compared strings was blank there, which is how this was found.
--
-- The join is Questie's, so the assertion is about numbers: the header's own
-- area folded up through GetParentZoneId, against the area of the map you are
-- standing on. The zone beside it is still matched by name in the same pass,
-- because a level 2 human carries quests under both headers at once.
do
	-- 103 rather than an id of its own, because client/05-quests.lua is at its
	-- ceiling: it is the one quest in that fixture carrying a zoneOrSort, and
	-- the 9 on it is the area the client really files a human's first quests
	-- under. Questie's own subZoneToParentZone hangs 9 off Elwynn Forest and
	-- the stub in client/16-dungeons.lua copies that line.
	local rows = quests.rows
	rows[#rows + 1] = { header = "Northshire Valley" }
	rows[#rows + 1] = { id = 103, title = "A Rogue's Deal", level = 2 }

	standing.map = ELWYNN
	check(Column.Refresh(), "the tracker is empty standing in the starting zone")
	check(says("A Rogue's Deal"),
		"a quest filed under a subzone is off the tracker on the map above it")
	check(says("The Missing Diplomat"),
		"matching a subzone header took the zone's own quests off the tracker")
	check(#Column.Quests() == 3,
		("%d quests are on the tracker where the subzone and the zone hold three")
			:format(#Column.Quests()))
	-- The reading counts the subzone's quest as one that is in front of you
	-- rather than as one pinned somewhere else, which is what it is.
	check(Column.Describe() == "3 quests, in Elwynn Forest",
		("the reading says %q"):format(Column.Describe()))
	seen[#seen + 1] = ("%s over %d rows"):format(Column.Describe(), #drawn())

	-- And it is still a scope. Westfall is a zone of its own in the same table,
	-- so a fold that answered any area at all would drag Northshire along.
	standing.map = WESTFALL
	Column.Refresh()
	check(not says("A Rogue's Deal"),
		"a subzone quest followed you into a zone that is not above it")

	rows[#rows] = nil
	rows[#rows] = nil
end

standing.map = WESTFALL
Column.Refresh()

----------------------------------------------------------------------
-- The pin
----------------------------------------------------------------------

-- The mark is a gold bar down the left of the name, hidden on every other row.
-- Item 95 moved the pin off the client's watch list onto a store of this
-- addon's own and item 96 drew the group above the zones in the window; what is
-- asserted here is the one thing that does not change under either, which is
-- that the tracker reads a pin and draws it on the quest that carries it.
do
	-- Elwynn Forest, because it is the one zone here with two quests left in it
	-- and a mark is only worth anything against a row that does not carry one.
	-- Both pins are cleared first and handed back afterwards: what the sections
	-- above left pinned is their business, and a mark test that read it would
	-- pass or fail on somebody else's fixture.
	--
	-- Pinned through ns.QuestLog.Pin rather than through the client's watch
	-- list. Item 95 took the pin off that list, so a fixture that writes
	-- quests.watched writes somewhere nothing reads and the mark never lights.
	local wasHere, wasThere = Log.Pinned("q102"), Log.Pinned("q201")
	Log.Pin("q102", false)
	Log.Pin("q201", false)
	standing.map = ELWYNN
	Column.Refresh()

	check(row("The Missing Diplomat") ~= nil and row("Wanted: Hogger") ~= nil,
		"a quest on the tracker has no row of its own")
	check(not row("The Missing Diplomat").mark:IsShown(),
		"an unpinned quest is wearing the pin's mark")

	Log.Pin("q102", true)
	Column.Refresh()
	check(row("The Missing Diplomat").mark:IsShown(),
		"a pinned quest is not wearing the mark")
	check(not row("Wanted: Hogger").mark:IsShown(),
		"pinning one quest put the mark on the quest under it as well")
	check(not row("Speak to Baros Alexston").mark:IsShown(),
		"the mark went on the pinned quest's objectives as well as on its name")

	Log.Pin("q102", wasHere)
	Log.Pin("q201", wasThere)
	standing.map = WESTFALL
	Column.Refresh()
end

----------------------------------------------------------------------
-- Pinned, wherever you are standing
----------------------------------------------------------------------

-- The one exception to the scope, and the whole of what a pin buys. Everything
-- else comes off this column when you walk out of the zone, so a quest you want
-- in front of you in the next zone is a quest you pin.
--
-- Asserted from Westfall against a quest the client filed under Elwynn Forest,
-- and then from Stormwind City, which the log has no header for at all. The
-- second one is the case that fails first: a scope that reached the pins by
-- filtering the zone's own quests would draw nothing in a zone with no quests
-- in it, which is most of the zones a player pins a quest to walk through.
do
	local was = Log.Pinned("q102")
	standing.map = WESTFALL
	Column.Refresh()
	local alone = #drawn()
	check(not says("The Missing Diplomat"),
		"an unpinned Elwynn quest is on the tracker in Westfall before anything is pinned")

	Log.Pin("q102", true)
	check(Column.Refresh(), "a pinned quest emptied the tracker")
	check(says("The Missing Diplomat"),
		"a pinned quest from another zone is not on the tracker in Westfall")
	check(says("The Defias Brotherhood"),
		"the pinned quest took this zone's own quest off the tracker")
	check(#drawn() > alone,
		("the column drew %d rows pinned where it drew %d unpinned")
			:format(#drawn(), alone))

	-- The zone first and the pin under it. What is under your feet is what you
	-- can act on now, and five pins above it would push it off the top.
	check(drawn()[1] == "The Defias Brotherhood",
		("the tracker leads with %s rather than with the quest you are standing in")
			:format(tostring(drawn()[1])))
	check(row("The Missing Diplomat").mark:IsShown(),
		"the quest that is only on the tracker because it is pinned wears no mark")
	check(Column.Describe() == "one quest, in Westfall, and one pinned elsewhere",
		("the reading says %q"):format(Column.Describe()))

	-- Stormwind City, where the log has no header and the pin is the only row.
	standing.map = STORMWIND
	check(Column.Refresh(),
		"a pinned quest is not on the tracker where the log has no header for you")
	check(says("The Missing Diplomat"),
		"the pin is counted in a zone with no header and not drawn in it")
	check(frame:IsShown(),
		"the tracker is off the screen in a zone whose only row is a pinned quest")
	check(Column.Describe() == "nothing in your log is in Stormwind City, and one pinned elsewhere",
		("the reading says %q"):format(Column.Describe()))
	seen[#seen + 1] = Column.Describe()

	Log.Pin("q102", was)
	standing.map = WESTFALL
	Column.Refresh()
	check(not says("The Missing Diplomat"),
		"unpinning left the quest on the tracker in a zone it is not in")
	check(#drawn() == alone,
		("the tracker drew %d rows after the pin came off where it drew %d before it went on")
			:format(#drawn(), alone))
end

----------------------------------------------------------------------
-- The zone strip
--
-- Five questions the file cannot answer. Does the strip list the zones your log
-- has quests in rather than the zones the client has maps of. Does pressing one
-- draw that zone from anywhere. Does walking somewhere new take the choice back,
-- and does walking somewhere with no quests in it leave it alone.
--
-- Does it run the way the setting says. The strip lays across by default and
-- down when it is asked to, and the two are one object with one flag, so the
-- failure worth catching is a tab left over from the other direction: a label
-- turned once and then laid in a row is a zone name written up the side of a
-- domino, and neither the file nor a count of tabs can see it.
--
-- And is the label turned when it is a column, because a strip that fell back
-- to upright labels is fifteen pixels wide in the file and a hundred and ten on
-- the screen.
----------------------------------------------------------------------

do
	standing.map = WESTFALL
	Column.Refresh()

	local strip = _G.WarriorKitQuestZones
	check(strip ~= nil, "the zone strip is on the tracker and has no name to find it by")

	-- What is on the strip, as one string per tab, top down.
	local function tabs()
		local out = {}
		for _, button in ipairs(strip.children) do
			if button.shown then
				for _, region in ipairs(button.regions) do
					if region.kind == "fontstring" and region.text ~= "" then
						out[#out + 1] = region.text
					end
				end
			end
		end
		return out
	end

	local function tab(said)
		for _, button in ipairs(strip.children) do
			if button.shown then
				for _, region in ipairs(button.regions) do
					if region.kind == "fontstring" and region.text == said then
						return button, region
					end
				end
			end
		end
		return nil, nil
	end

	-- One tab per zone with quests under it, in the log's own order, and the
	-- count on it is what is still in your log there rather than what the zone
	-- ever held.
	check(#tabs() == 2,
		("%d tabs are on the strip where the log has quests in two zones")
			:format(#tabs()))
	check(tabs()[1] == "Elwynn Forest 2" and tabs()[2] == "Westfall 1",
		("the strip reads %s"):format(table.concat(tabs(), ", ")))

	-- Whether two rectangles are over one another, which is what the strip and
	-- the words must never be whichever way the strip runs. The words live in
	-- one frame and the strip is the tracker's other child, so this is the whole
	-- of the question: a strip that took no room off the column would pass every
	-- assertion above it and draw its tabs over the first two quests.
	local function overlaps(a, b)
		return a:GetLeft() < b:GetRight() and b:GetLeft() < a:GetRight()
			and a:GetBottom() < b:GetTop() and b:GetBottom() < a:GetTop()
	end

	-- Across, which is what it ships as. A row of upright tabs over the quests,
	-- each as wide as its own zone name, and the words pushed down under it.
	--
	-- The angle is read back off the label rather than assumed, in both
	-- directions and for the same reason: the tabs are pooled, so every one of
	-- them was made the other way round at some point in a session where the
	-- setting moved, and a label nobody turned back is invisible from the file.
	check(ns.db.questsTabs == "across",
		("the tracker's zone tabs ship as %q"):format(tostring(ns.db.questsTabs)))
	do
		local button, label = tab("Westfall 1")
		check(label:GetRotation() == 0,
			("a tab in a row is turned %s radians"):format(tostring(label:GetRotation())))
		check(button:GetWidth() > button:GetHeight(),
			("a zone tab is %d by %d, which is not one in a row")
				:format(button:GetWidth(), button:GetHeight()))
		check(strip:GetWidth() <= frame:GetWidth(),
			("the harmonica is %d wide over a tracker %d wide, so it hangs off the side")
				:format(strip:GetWidth(), frame:GetWidth()))
		check(not overlaps(strip, trunk()),
			"the tabs are drawn over the quests rather than above them")
	end

	-- Down, which is the other half of the setting, and the whole reason a
	-- turned strip is fifteen pixels wide.
	local wasWide = frame:GetWidth()
	ns.db.questsTabs = "down"
	check(Column.Apply(), "turning the zone strip on its side emptied the tracker")
	do
		local button, label = tab("Westfall 1")
		check(label:GetRotation() < 0,
			("the zone label is turned %s radians"):format(tostring(label:GetRotation())))
		check(button:GetHeight() > button:GetWidth(),
			("a zone tab is %d by %d, which is not a turned one")
				:format(button:GetWidth(), button:GetHeight()))
		check(strip:GetWidth() < 40,
			("the strip is %d wide, which is a rail rather than a strip")
				:format(strip:GetWidth()))
		check(frame:GetWidth() > wasWide,
			("the tracker is %d wide with a strip down its edge and was %d wide with a row over it")
				:format(frame:GetWidth(), wasWide))
		check(not overlaps(strip, trunk()),
			"the turned tabs are drawn over the quests rather than beside them")
	end

	-- And air on both sides of the turned label, off the line's own height
	-- rather than off the size the font was asked for. They are different
	-- numbers: a font asked for eleven draws a line of thirteen or more, the
	-- difference is the leading, and a tab sized on the asked number is a tab
	-- with less air than it was written to have and a label sitting against one
	-- edge of a strip that is fifteen pixels wide to begin with. Four is the
	-- floor rather than the six the strip asks for, because the line height is
	-- the client's answer and a client whose font leads differently is not a
	-- failure worth stopping a run for.
	do
		local button, label = tab("Westfall 1")
		check(button:GetWidth() - label:GetStringHeight() >= 8,
			("a zone tab is %.1f across a line of %.1f, which is %.1f of air a side")
				:format(button:GetWidth(), label:GetStringHeight(),
					(button:GetWidth() - label:GetStringHeight()) / 2))
	end

	-- And back to the harmonica, which is what the rest of this section reads.
	ns.db.questsTabs = "across"
	Column.Apply()

	-- Pressing one draws that zone from wherever you are standing, which is the
	-- whole feature: the quests in Elwynn, read in Westfall, without walking.
	check(not says("The Missing Diplomat"),
		"an Elwynn quest is on the tracker in Westfall before any tab is pressed")
	press(select(1, tab("Elwynn Forest 2")))
	check(says("The Missing Diplomat") and says("Wanted: Hogger"),
		"pressing the Elwynn tab did not put Elwynn's quests on the tracker")
	check(not says("The Defias Brotherhood"),
		"pressing a tab left the zone you are standing in on the tracker as well")
	check(Column.Describe() == "2 quests, in Elwynn Forest, which you picked",
		("the reading says %q"):format(Column.Describe()))
	seen[#seen + 1] = Column.Describe()

	-- Walking somewhere with no quests in it leaves the choice alone. Standing
	-- in a city reading Westfall is exactly what the strip is for.
	standing.map = STORMWIND
	Column.Refresh()
	check(says("The Missing Diplomat"),
		"walking into a city with no quests in it dropped the zone you picked")

	-- And walking into a zone that has quests takes it back, because that
	-- gesture means "I am here now".
	standing.map = WESTFALL
	Column.Refresh()
	check(says("The Defias Brotherhood") and not says("The Missing Diplomat"),
		"walking back into Westfall left the tracker on the zone picked before")
	check(Column.Describe() == "one quest, in Westfall",
		("the reading says %q"):format(Column.Describe()))
end

----------------------------------------------------------------------
-- Clicking a row
----------------------------------------------------------------------

-- The gesture, delivered as a press at a point rather than by reaching for the
-- handler, so the hit test has to agree that the row is the thing under the
-- pointer. The wash is a texture and the stack's frame takes no mouse, and both
-- of those are only true until somebody changes one.
do
	local reached = quests.Tracked()
	local defias = Log.Zones()[2].quests[1]

	-- The window goes away first, and that is the scene rather than a
	-- convenience: the tracker is what you click when the log is shut, and the
	-- log is a DIALOG across the right of the screen while it is open.
	ns.QuestWindow.Hide()
	ns.QuestWindow.Showing(Log.Zones()[1].quests[1].key)

	-- Two halves, and the press is not aimed at a point on the screen.
	--
	-- Which frame the client hands a press to is a fact about everything on the
	-- screen, and the fixtures put a cloned action bar over the corner this
	-- tracker ships in. That is a fact about the harness's scene rather than
	-- about the tracker, and a section that moved the frame until nothing was
	-- over it would be asserting where the other fixtures stand.
	--
	-- So the hit test is asked of the tracker alone, which is the question worth
	-- asking here: the wash is a texture, the stack's frame takes no mouse, and
	-- the row is what a press inside this column lands on. Both of those are
	-- true until somebody changes one. Then the press itself goes through
	-- Region:Click, which is the client's own call and runs the registration,
	-- the pass-through and both edges the way a real press does.
	local target = row("The Defias Brotherhood")
	local x, y = mouse.Point(target)
	check(mouse.Within(frame, x, y, "LeftButton") == target,
		"something in the tracker is over its own rows and eats the press")

	press(target)
	check(ns.QuestWindow.Shown(), "a click on the tracker did not open the quest log")
	check(ns.QuestWindow.Showing() == defias.key,
		("the tracker opened the window on %s rather than on the quest clicked")
			:format(tostring(ns.QuestWindow.Showing())))
	check(quests.Tracked() == reached,
		"the click reached Blizzard's quest log as well as this window")

	-- An objective row carries the quest above it, because the line saying how
	-- many trappers are left is a thing you point at when you mean that quest.
	ns.QuestWindow.Hide()
	ns.QuestWindow.Showing(Log.Zones()[1].quests[1].key)
	press(row("Trapper's Rope: 3/3"))
	check(ns.QuestWindow.Showing() == defias.key,
		"clicking an objective did not open the quest it belongs to")
end

----------------------------------------------------------------------
-- Unlocked, the rows stand aside
----------------------------------------------------------------------

-- A row that answered the pointer while the frame is being placed would swallow
-- the drag, which is the whole of what unlocking is for. Both directions,
-- because a lock that took the mouse away and never gave it back is a tracker
-- you can never click again.
do
	local target = row("The Defias Brotherhood")
	local x, y = mouse.Point(target)
	ns.db.locked = false
	Column.Lock()
	check(not target:IsMouseEnabled(),
		"the rows still answer the pointer while the frame is unlocked")
	check(mouse.Within(frame, x, y, "LeftButton") ~= target,
		"a press aimed at a row of an unlocked tracker still lands on the row")

	ns.db.locked = true
	Column.Lock()
	check(target:IsMouseEnabled(), "locking the frame again left the rows inert")
end

----------------------------------------------------------------------
-- An empty log
----------------------------------------------------------------------

-- Every row taken out of the client's log and put back. The tracker has to go
-- away rather than keep drawing what it had, which is the state a fresh
-- character is in and the state five minutes after handing the last one in.
do
	local rows = quests.rows
	local held = {}
	for at = 1, #rows do
		held[at] = rows[at]
	end
	for at = #rows, 1, -1 do
		rows[at] = nil
	end

	check(Column.Refresh() == false, "an empty log still put quests on the tracker")
	check(#drawn() == 0, ("%d rows are drawn off an empty log"):format(#drawn()))
	check(not frame:IsShown(), "the tracker is on the screen with an empty log")
	check(Column.Describe() == "nothing in your log is in Westfall",
		("the reading says %q"):format(Column.Describe()))

	for at = 1, #held do
		rows[at] = held[at]
	end
	Column.Refresh()
	check(#Column.Quests() == 1, "the log did not come back the way it was found")
end

----------------------------------------------------------------------
-- The switch
----------------------------------------------------------------------

-- One switch and one tracker. The box that takes Questie's tracker off the
-- screen is the box that puts this one up, so unticking it has to take this one
-- away rather than leave two trackers with no rule about which is which.
ns.db.questsTrackerOff = false
check(Column.Apply() == false, "the tracker is on with the switch off")
check(not frame:IsShown(), "unticking the switch left the tracker on the screen")
check(Column.Describe() == "off, and Questie's tracker has the screen",
	("the reading says %q"):format(Column.Describe()))
check(Column.Refresh() == false, "a redraw put a switched-off tracker back up")

----------------------------------------------------------------------

ns.db.questsTrackerOff = WAS_OFF
ns.db.locked = WAS_LOCK
ns.db.questsTabs = WAS_TABS
standing.map = WAS_MAP
Column.Apply()
if WAS_OPEN then
	ns.QuestWindow.Show()
else
	ns.QuestWindow.Hide()
end

print(("tracker %s; and with the switch unticked, %s")
	:format(table.concat(seen, "; "), Column.Describe()))
