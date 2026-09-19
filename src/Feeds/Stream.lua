local ADDON, ns = ...

local Stream = {}
ns.Stream = Stream

local UI = ns.UI
local C = UI.Color

--------------------------------------------------------------------------
-- A feed, put on the screen
--
-- UI/Feed.lua draws a column of things that happened and knows nothing else:
-- not where it sits, not whether it is switched on, not how big the player
-- asked for it. This is the seam between that widget and the addon around it.
-- One frame on UIParent, on the pixel grid, movable while the addon is
-- unlocked, with one feed filling it and a block of settings behind it.
--
-- It exists because there are two of these and there will be more. The loot
-- stream and the combat log differ in what they capture and in what a row says;
-- they do not differ in any of the twelve things below, and two copies of
-- twelve things is two places to fix a drag that saves the wrong anchor.
--
-- **Settings are found by name, not passed in.** A stream is built with a
-- prefix and every setting it reads is that prefix and a word: lootFeed,
-- lootFeedRows, lootFeedWidth. The names are resolved once here rather than
-- concatenated at each read, so nothing builds a string to look a setting up,
-- and Feature.lua registers exactly the eight keys this file will ask for.
--
-- **On and shown are two settings, not one.** They were one, called after the
-- prefix, and it meant the only way to get a feed off the screen was to stop it
-- recording: hide it and it stopped collecting, so what came back when you
-- wanted it again was an empty column. Hiding a feed and switching it off are
-- different requests and now they are different keys. `lootFeed` is whether it
-- collects, which is what the capture files read before they do any work, and
-- `lootFeedShown` is whether you can see it. Off implies hidden, because a
-- frozen list left on screen reads as a bug rather than as a setting.
--
-- **Locked is the normal state.** Unlocked draws an outline and a name above
-- it, which is Meter/Window.lua's trade and is here for the same reason: a feed
-- that has nothing in it yet is otherwise a piece of empty screen you have to
-- find from memory.
--------------------------------------------------------------------------

-- The ten settings a stream owns beyond the one named after its prefix, as
-- the words that follow it. Named here so Feeds/Feature.lua registers the same
-- list this file reads and neither can drift without the other failing to find
-- a key.
--
-- The last three arrived together and are all one subject: how much of a
-- window a feed is. Icon is the size of the picture on a row and therefore the
-- height of the row. Header is the word over the column. Edge is the hairline
-- round the whole thing.
local KEYS = {
	"Rows", "Width", "Zoom", "Alpha", "Mouse", "Shown", "Point",
	"Icon", "Header", "Edge",
}

--------------------------------------------------------------------------
-- The header's right end
--
-- A stream may hand in what the right end of the feed's header says instead of
-- the feed's count, and what a hover of it slides out from behind the feed.
-- The loot feed does, with the purse: the session's takings in the heading
-- gold, and the ledger on a panel. A stream given neither has the count there,
-- as it always had.
--
-- Nothing here beats. The figure is written when the stream's owner says it
-- moved, which for the purse is a change of money.
--------------------------------------------------------------------------

local Instance = {}
Instance.__index = Instance

local streams = {}

--------------------------------------------------------------------------
-- Building
--
-- spec.prefix    the setting that switches it collecting, and the stem of the
--                other seven
-- spec.name      the global the frame is made under, so a stream that has
--                wandered off the screen can be found from a macro
-- spec.title     the word over the column, and the name shown while unlocked
-- spec.empty     what stands where the rows would be before anything happens
-- spec.note      how wide the dim middle column is, in units, and nothing for a
--                stream whose rows are a name and a number
-- spec.onTooltip function(entry), answering the table UI/Tooltip.lua renders
-- spec.removable whether the row under the cursor carries a cross that takes
--                it out of the feed
-- spec.watch     the delete list, see UI/Feed.lua's opts.watch
-- spec.held      how many entries the stream keeps, see UI/Feed.lua's opts.held
-- spec.bar       whether the column has a scroll bar, see UI/Feed.lua's opts.bar
-- spec.aside     function(), answering what the header's right end says in
--                place of the count, or nil to leave the count there
-- spec.onAside   function(), the UI/Tip.lua subject the panel behind that
--                figure shows. See Feeds/Drawer.lua
--------------------------------------------------------------------------

function Stream.New(spec)
	local stream = setmetatable({
		prefix = spec.prefix,
		name = spec.name,
		title = spec.title,
		empty = spec.empty,
		note = spec.note,
		onTooltip = spec.onTooltip,
		removable = spec.removable,
		watch = spec.watch,
		cap = spec.held,
		barred = spec.bar,
		aside = spec.aside,
		onAside = spec.onAside,
		keys = { on = spec.prefix },
	}, Instance)

	for _, word in ipairs(KEYS) do
		stream.keys[word:lower()] = spec.prefix .. word
	end

	streams[#streams + 1] = stream
	return stream
end

-- The defaults for one stream's seven shaped settings, merged by Feature.lua into
-- the table it registers. Written here rather than there so the file that reads
-- a setting is the file that says what it means.
--
-- Ten rows of a 29 pixel row is a column about the height of a chat window and
-- roughly a pull's worth of drops. 260 wide holds a 27 pixel icon, a fixed
-- number column and an item name that is not clipped to three words.
--
-- It was 220 and that was measured against a row of two columns. Three columns
-- need the width back and then some, and a loot feed narrower than the combat
-- feed sitting in the opposite corner reads as a mistake rather than as a
-- decision, so both moved.
--
-- `chrome` is whether this stream ships with a word over it and a line round
-- it. It is an argument rather than a constant because the two feeds answer it
-- differently and both answers are right: the loot feed's rows are an icon, a
-- name in the item's own colour and a count, and none of that needs the word
-- "Loot" written above it. A combat feed
-- is three columns of numbers and does.
function Stream.Defaults(prefix, point, chrome)
	return {
		[prefix] = true,
		[prefix .. "Rows"] = 10,
		[prefix .. "Width"] = 260,
		[prefix .. "Zoom"] = 1,
		-- Not the meter's zero. A meter is three columns of outlined text you
		-- read out of the corner of your eye during a pull; a feed is a list you
		-- lean in and read, with a scrollbar down one side, and a scrollbar over
		-- bare world is a control with nothing behind it. 70 is a surface you
		-- can read a grey item name on and still see the floor through.
		[prefix .. "Alpha"] = 70,
		[prefix .. "Mouse"] = true,
		-- Shown by default, and separate from the switch above it. A feed you
		-- have hidden goes on collecting, so bringing it back shows the last few
		-- hundred things that happened rather than a blank column; a feed you
		-- have switched off collects nothing and is hidden with it.
		[prefix .. "Shown"] = true,
		[prefix .. "Point"] = point,

		-- The picture on a row, and the row height that follows it. 27 is the
		-- size at which the client's own icon art draws one stored texel per
		-- screen pixel, which is why it is the default and why the panel says
		-- so when you move off it.
		[prefix .. "Icon"] = ns.UI.FEED_ICON,

		[prefix .. "Header"] = chrome and true or false,
		[prefix .. "Edge"] = chrome and true or false,
	}
end

-- When an entry happened, on the wall clock.
--
-- GetTime counts from when the client started, which is the right clock to
-- record on and an unreadable one to show, so the difference between then and
-- now is taken off the current time of day. Built on a hover rather than stored
-- on the entry, because Feed:Push runs on the path a raid drives and a hover is
-- a moment that can afford a string.
--
-- Here rather than in either capture file because both of them want it and the
-- second copy is the one that drifts.
function Stream.Clock(at)
	if not at then
		return "?"
	end
	return date("%H:%M:%S", time() - (GetTime() - at))
end

function Instance:Setting(word)
	return ns.db[self.keys[word]]
end

--------------------------------------------------------------------------
-- The figure and the panel behind it
--------------------------------------------------------------------------

-- The mouse frame over the figure and the drawer it opens, built once. A font
-- string takes no mouse, so the hover is a frame laid over the string the feed
-- hands back, and it follows the string as the string grows.
function Instance:BuildAside()
	local label = self.feed:Aside(nil)
	local hit = CreateFrame("Frame", nil, self.frame)
	self.hit = hit
	hit:SetPoint("TOPLEFT", label, "TOPLEFT", 0, 0)
	hit:SetPoint("BOTTOMRIGHT", label, "BOTTOMRIGHT", 0, 0)
	hit:Hide()

	if self.onAside then
		self.drawer = ns.Drawer.New(self.frame, self.feed.frame, self.onAside)
		hit:SetScript("OnEnter", function() self.drawer:Enter("figure") end)
		hit:SetScript("OnLeave", function() self.drawer:Leave("figure") end)
		UI.PassCamera(hit)
	end
	return true
end

-- What the right end says, written, and whether it is the owner's at all.
-- Guarded on the text, because a change of money that did not change the
-- figure is most of them.
local function WriteAside(stream)
	local text = stream.aside()
	if text == stream.asideAt then
		return text ~= nil
	end
	stream.asideAt = text
	stream.feed:Aside(text, C.heading)
	stream.hit:SetShown(text ~= nil)
	if not text and stream.drawer then
		stream.drawer:Shut()
	end
	return text ~= nil
end

-- The money moved. The figure is rewritten, and if it came or went the header
-- came or went with it, which is a new height for everything under it and is
-- Apply's to work out.
function Instance:Aside()
	if not (self.frame and self.aside) then
		return false
	end
	local was = self.asideAt ~= nil
	if WriteAside(self) ~= was then
		return self:Apply()
	end
	return true
end

-- The frame, the column and the figure, made the first time the part is switched
-- on and not before.
--
-- Both feeds were built at login whatever the switches said. The combat feed
-- ships off, and off meant a frame, a column of rows and a ring of entry tables
-- for a part the player has never turned on. A stream that is not collecting has
-- nothing to draw and nothing to hold, so it has nothing at all until the switch
-- moves.
--
-- The switch rather than whether you can see it, and the two are different
-- questions: a feed you have hidden goes on collecting, and the capture files
-- push into it. `on` is what they read before they do any work, so `on` is what
-- has to have built the column they are pushing into.
function Instance:Build()
	if self.frame then
		return false
	end
	if not self:Setting("on") then
		return false
	end

	local frame = CreateFrame("Frame", self.name, UIParent)
	self.frame = frame
	UI.Adopt(frame, self:Setting("zoom"))
	-- And it stands down while a screen window is up. UI/Hush.lua carries the
	-- whole of what that means; what it means here is that the character sheet
	-- is read against the world rather than against this row.
	UI.Hushable(frame)
	self.unit = UI.Unit(frame)

	-- Under the tooltip and above the world. A feed is furniture, the same as
	-- the chat window, and it must not sit over a dialog the client puts up.
	frame:SetFrameStrata("MEDIUM")
	-- The accent rather than the palette's edge, which is the one thing a feed
	-- wants differently from the other eleven placeable frames: it already has
	-- a hairline of its own round it all the time, so the rim that says it is
	-- being placed has to be a different colour from the one that is always
	-- there.
	self.place = UI.Placeable(frame, {
		name = self.title,
		edge = C.accent,
		moved = function(anchor)
			ns.db[self.keys.point] = anchor
		end,
	})
	ns.Theme.Wear("feeds", frame)

	-- No surface under the column. It had one, painted in the window colour at
	-- whatever the background slider said, and the loot feed shipped it at 15
	-- because a panel over open world was covering scenery to hold up text that
	-- did not need holding up. UI/Feed.lua paints a gradient under each row
	-- instead, the same slider says how strongly, and what the player gets back
	-- is the ground between one row and the next.
	self.edges = ns.Outline(frame, C.edge[1], C.edge[2], C.edge[3], C.edge[4])
	ns.EdgeSize(self.edges, ns.Pixel(frame))

	self.feed = UI.Feed(frame, {
		unit = self.unit,
		title = self.title,
		empty = self.empty,
		note = self.note,
		onTooltip = self.onTooltip,
		removable = self.removable,
		watch = self.watch,
		held = self.cap,
		bar = self.barred,
		-- The strip coming up for a delete list changes the frame's height, and
		-- Apply is the one place that works out what that height is.
		onLayout = function() self:Apply() end,
	})
	self.feed.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	-- Told here rather than left to Apply. Apply resizes before it shows, and a
	-- resize repaints, so a feed the player has hidden would draw its whole
	-- column once at every login for nobody.
	self.feed:Awake(self:Visible())

	if self.aside then
		self:BuildAside()
	end

	return true
end

--------------------------------------------------------------------------
-- Everything a setting can move
--
-- Called at login and again whenever a number in the panel changes, never from
-- a tick, because nothing in a feed is on a tick.
--------------------------------------------------------------------------

function Instance:Apply()
	if not self.frame then
		-- Nothing was built while the switch was off, so this is where the first
		-- press of it lands. A stream built here has never been placed, sized or
		-- dressed, and everything below is what does all three.
		if not self:Build() then
			return false
		end
	end

	local point = self:Setting("point")
	self.frame:ClearAllPoints()
	self.frame:SetPoint(point[1], UIParent, point[3], point[4], point[5])
	UI.Rezoom(self.frame, self:Setting("zoom"))

	-- What the column is dressed in, before what size it is. The strip over the
	-- rows is either there or not and everything below it is measured off that
	-- answer, so a resize that ran first would place every row against the last
	-- answer and then be told the new one. The figure on its right end is one of
	-- the things that holds it up, so it is written first of all.
	if self.aside then
		WriteAside(self)
	end
	self.feed:Chrome(self:Setting("header"))

	local width, height = self.feed:Resize(self:Setting("width"), self:Setting("rows"),
		self:Setting("icon"))
	self.frame:SetSize(width, height)

	-- The ground under the rows, and the edge that follows it and its own
	-- switch. At zero the player has asked for rows over the world with nothing
	-- painted under them at all, and a hairline rectangle round that is a window
	-- frame with no window in it; with the switch off they have asked for a feed
	-- with no line round it, which is what the loot feed ships as.
	local alpha = self:Setting("alpha") / 100
	local edged = (alpha > 0 and self:Setting("edge")) and 1 or 0
	self.feed:Wash(alpha)
	for index = 1, 4 do
		self.edges[index]:SetAlpha(edged)
	end

	self.feed:Mouse(self:Setting("mouse"))
	self:Lock()
	self:Show()
	return true
end

function Instance:Lock()
	if not self.frame then
		return false
	end
	local unlocked = not ns.db.locked
	self.place:Lock(unlocked)
	-- The figure lets go of the mouse while the feed is being placed, and when
	-- the feed takes none. It is on the top edge, which is where a hand reaches
	-- for a window, so a figure still taking the mouse is a corner of the frame
	-- you cannot drag by. Placeable does the frame's half; which children stand
	-- aside for it is this file's own business.
	if self.hit then
		self.hit:EnableMouse((not unlocked and self.drawer
			and self:Setting("mouse")) and true or false)
	end
	return true
end

-- On screen or not, and the feed told either way.
--
-- The frame being hidden is not on its own enough. UI/Feed.lua repaints every
-- drawn row on every arrival whether or not anybody can see the result, and a
-- hidden feed still collecting would do all of that drawing into nothing. It is
-- most of what a row costs: about four fifths of the work of putting a combat
-- log event on the screen is the repaint, so the same answer goes to the
-- widget, which stops painting and paints once when it comes back.
-- Whether anybody can see this, which is both settings and neither one on its
-- own. Off implies hidden: there is nothing to look at in a column nothing is
-- being written to, and a frozen list left on screen reads as a bug.
function Instance:Visible()
	return (self:Setting("on") and self:Setting("shown")) and true or false
end

function Instance:Show()
	if not self.frame then
		-- The switch just went on. Apply builds it, places it and ends by calling
		-- this again with a frame to show.
		if not self:Setting("on") then
			return false
		end
		return self:Apply()
	end
	local visible = self:Visible()
	self.frame:SetShown(visible)
	self.feed:Awake(visible)
	return true
end

function Instance:Reset(point)
	ns.db[self.keys.point] = point
	return self:Apply()
end

function Instance:Feed()
	return self.feed
end

-- The mouse frame over the header's figure and the drawer it opens, for
-- scripts/harness.lua. Handed out for the reason UI/Feed.lua hands out a row:
-- "a hover opens the panel" is a claim the harness has to be able to make, and
-- reaching into a stream's own fields to make it would be asserting this
-- file's spelling rather than its behaviour.
function Instance:Figure()
	return self.hit, self.drawer
end

function Instance:Describe()
	if not self:Setting("on") then
		return "off"
	end
	if not self.feed then
		return "not built yet"
	end
	local line = self.feed:Describe()
	if not self:Setting("shown") then
		line = line .. ", hidden but still collecting"
	end
	if not self:Setting("mouse") then
		line = line .. ", not taking the mouse, so no tooltips"
	end
	return line
end

--------------------------------------------------------------------------
-- Every stream at once
--
-- The three hooks Core walks the registry for are per feature rather than per
-- stream, so Feeds/Feature.lua calls these and never names either stream.
--------------------------------------------------------------------------

function Stream.Each(method, ...)
	for index = 1, #streams do
		local stream = streams[index]
		stream[method](stream, ...)
	end
end

-- Build answers nothing for a stream whose switch is off, and Apply then has
-- nothing to place. A session that never turns the combat feed on never makes
-- one.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	Stream.Each("Build")
	Stream.Each("Apply")
end)

-- A resolution change or a UI size change moves every number in a stream at
-- once, the same way it moves the meters.
UI.OnRescale(function()
	Stream.Each("Apply")
end)
