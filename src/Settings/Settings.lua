local ADDON, ns = ...

local Settings = {}
ns.Settings = Settings

local UI = ns.UI

--------------------------------------------------------------------------
-- The settings that belong to no feature
--
-- Two of them: how big the addon's own windows are, and where a hover's box
-- opens. Both are questions about the whole addon rather than about any part
-- of it, which is why neither lives in a feature folder. The first is most of
-- this file and is described below; the second is further down, next to the
-- three calls it needs.
--
-- How big the addon's own windows are
--
-- Every other size in this addon is a count of physical pixels, decided once by
-- whoever drew the thing and true on every monitor. That is the right default
-- and it is the wrong answer for one question, which is how big a window should
-- look to the person reading it. A 544 pixel panel is comfortable on a 1080p
-- monitor at arm's length and postage stamp sized on a 27 inch 4K one, and no
-- measurement the addon can take tells the two apart, because the difference is
-- the distance from the screen to your eyes.
--
-- So this is a preference and not a calculation. UI/Window.lua already picks a
-- whole step off the screen height, which handles the 4K case badly but not
-- wrongly; this multiplies that step by whatever the player dragged the slider
-- to. The two compose: on a screen that has already doubled everything, half
-- size lands back on the design size and every edge is exact again.
--
-- **Tenths, and the grid.** The stops are 0.5 through 3 in tenths, twenty six
-- of them. A stop keeps the grid when the size times the screen's own step
-- comes out whole, because one unit is then a whole number of pixels and a
-- hairline is a hairline. On a screen that contributes 1 those are 1x, 2x and
-- 3x; on one that contributes 2 every half step is exact, which is the
-- composition doing what it was meant to. The rest are soft: at 1.4x on a 1080p
-- screen a one pixel edge is asked for at 1.4 pixels and the renderer lays down
-- a blur.
--
-- The step used to be a quarter here and a whole number on anything you read
-- mid fight, on the argument that the addon should not let you pay for a soft
-- hairline on a health bar. That argument is about one stop being better than
-- another and it was being made by putting the other stops out of reach. Every
-- part of the addon runs on the same tenth now, and Settings.Describe is what
-- says which stop you are on and what it costs, per screen, rather than a rule
-- deciding it for you.
--
-- **What it covers.** Every screen this addon draws, each on its own number.
-- There was one number for all of them and it was wrong for the reason the chat
-- window worked out first: shrinking a map to sit beside a quest log shrank the
-- quest log with it. What is left here is the two the UI layer draws for
-- nobody, the hover box and the confirm box, because a part has to own a
-- setting and neither of those belongs to one.
--------------------------------------------------------------------------

-- The range, the stops, the clamp and the label all live in UI/Widgets.lua now,
-- beside the control that offers them, because they stopped being this file's
-- private answer the moment every part of the addon took the same one. Aliased
-- rather than called through: this file quotes all four a dozen times and the
-- slash word quotes the range.
Settings.LOW, Settings.HIGH, Settings.STEP = UI.ZOOM_LOW, UI.ZOOM_HIGH, UI.ZOOM_STEP
Settings.Snap = UI.ZoomSnap
Settings.Label = UI.ZoomLabel

-- Push the saved value into the UI layer, which relays out every open window.
-- Called at ADDON_LOADED so the panel is built at the right size rather than
-- built at the design size and resized a moment later.
function Settings.Apply()
	Settings.ApplyPlaces()
	UI.Tooltip.SetShade(ns.db.tipShade)
	UI.Tooltip.SetLinger(ns.db.tipLinger)
	UI.Tooltip.SetFont(ns.db.tipFont)
	ns.Compare.SetEnabled(ns.db.tipCompare)
	Settings.ApplyAnchor()
	Settings.LockAnchor()
	UI.Tooltip.SetZoom(Settings.Snap(ns.db.tipZoom))
	UI.SetGeneral(Settings.Snap(ns.db.generalSize))
	return UI.SetSize(Settings.Snap(ns.db.dialogZoom))
end

-- The size of everything at once, which every screen's own number multiplies.
-- The setup asks it; the zoom page carries it over every other row.
function Settings.SetGeneral(scale)
	ns.db.generalSize = Settings.Snap(scale)
	UI.SetGeneral(ns.db.generalSize)
	return ns.db.generalSize
end

-- The confirm box's own size. The hover box's is beside the rest of the hover
-- settings below, because that is where a player looking for it will be.
function Settings.Set(scale)
	ns.db.dialogZoom = Settings.Snap(scale)
	Settings.Apply()
	return ns.db.dialogZoom
end

function Settings.SetTipZoom(scale)
	ns.db.tipZoom = Settings.Snap(scale)
	UI.Tooltip.SetZoom(ns.db.tipZoom)
	return ns.db.tipZoom
end

--------------------------------------------------------------------------
-- What a hover's box does
--
-- The other settings that belong to no feature. Every hover in the addon opens
-- the same box, so where it goes, how long it stays and how big it reads are
-- four answers for the whole addon and not the loot feed's business or the
-- action bar's.
--
-- **Where.** Docked is the corner the client keeps its own tooltip in, and it
-- is the default: a box beside the row under the cursor covers the next row,
-- and everything in this addon you can hover sits over the middle of the
-- screen. Beside is the other shipped answer and it is not a fallback; on a
-- very wide monitor the corner is a long way from what you are reading. The
-- third is a marker you drag with the frames unlocked, which is the only one of
-- the three that can put the box where you actually look.
--
-- **How long.** A second after the pointer leaves. Every hoverable thing in
-- this addon is small and most of them sit in a column, so a box that vanished
-- on the frame you crossed a row is a box you cannot finish reading.
--
-- **How big.** Twelve pixels, which is the addon's body size, and a number
-- rather than a constant because how big a sentence has to be to be read in
-- half a second is a fact about a monitor and a pair of eyes.
--
-- Every one of them is pushed into UI/Tooltip.lua rather than read out of
-- there, the same way the size is: that layer is not allowed to know the name
-- of a setting.
--------------------------------------------------------------------------

-- The marker the anchor placement hangs off.
--
-- Small, because it marks a corner rather than showing a box: which corner of
-- the tooltip lands on it is decided from which quarter of the screen it is in,
-- so a rectangle the size of a tooltip would be a promise about a shape that
-- changes with every hover. It carries a rim and a name while the frames are
-- unlocked, which is what UI.Placeable draws for a frame with no chrome, and it
-- is invisible and mouse-blind the rest of the time.
local MARKER = 40
local marker, markerPlace

local function Marker()
	if marker then
		return marker
	end
	marker = CreateFrame("Frame", "WarriorKitTooltipAnchor", UIParent)
	-- Over the options window, which is DIALOG: the Tooltips page shows the
	-- marker so you can drag it, and one drawn under the page is one you
	-- cannot reach wherever the page covers it.
	marker:SetFrameStrata("FULLSCREEN_DIALOG")
	UI.Adopt(marker, 1)
	marker:SetSize(MARKER, MARKER / 2)
	markerPlace = UI.Placeable(marker, {
		name = "WarriorKit tooltip",
		moved = function(anchor)
			ns.db.tipPoint = anchor
			Settings.ApplyAnchor()
		end,
	})
	return marker
end

-- Where the marker sits, put back on it. Its own function because three callers
-- want it: the first build, a drag that has just written a new anchor, and the
-- reset.
function Settings.ApplyAnchor()
	local frame = Marker()
	local point = ns.db.tipPoint
	frame:ClearAllPoints()
	frame:SetPoint(point[1], UIParent, point[3], point[4], point[5])
	UI.Tooltip.SetAnchor(frame)
	return frame
end

-- The frames were locked or unlocked, or the Tooltips page came up or went.
-- A marker you cannot see is a marker you cannot drag, and the page that asks
-- where the box goes is where you are looking when you want to move it, so the
-- page shows it as well as the unlock does.
local paging = false

function Settings.LockAnchor()
	Marker()
	markerPlace:Lock(not ns.db.locked or paging)
end

function Settings.ShowAnchor(on)
	paging = on and true or false
	Settings.LockAnchor()
end

function Settings.ResetAnchor()
	ns.db.tipPoint = ns.DefaultCopy("tipPoint")
	Settings.ApplyAnchor()
end

-- The marker itself, for scripts/harness.lua. Handed out for the reason every
-- other placeable frame in the addon hands its own out: "the box opened on the
-- marker" is a claim about two rectangles and there is no making it from
-- outside without one of them.
function Settings.AnchorFrame()
	return Marker()
end

--------------------------------------------------------------------------

-- The four answers in the order the dropdown lists them, each with the words
-- it is shown as.
Settings.PLACES = {
	{ value = UI.Tooltip.RIGHT, text = "bottom right" },
	{ value = UI.Tooltip.LEFT, text = "bottom left" },
	{ value = UI.Tooltip.ATTACHED, text = "attached" },
	{ value = UI.Tooltip.ANCHOR, text = "drag it yourself" },
}

function Settings.PlaceOptions()
	return Settings.PLACES
end

-- The saved key one type's answer lives under: tipPlaceBag, tipPlaceWorld.
-- A key per type rather than one table, so a type added next month gets its
-- default filled in by ns.Register like every other setting, and the reset
-- counts a moved type as one setting moved.
function Settings.PlaceKey(sort)
	return "tipPlace" .. sort:sub(1, 1):upper() .. sort:sub(2)
end

function Settings.Place(sort)
	return UI.Tooltip.Place(sort)
end

function Settings.SetPlace(sort, word)
	UI.Tooltip.SetPlace(sort, word)
	-- Read back rather than taken, because the box takes a word it does not
	-- know as that type's default and the account file is allowed to hold one.
	local key = Settings.PlaceKey(sort)
	ns.db[key] = UI.Tooltip.Place(sort)
	return ns.db[key]
end

-- Every type's saved answer pushed in, which is the load and the reset.
function Settings.ApplyPlaces()
	for _, each in ipairs(UI.Tooltip.TYPES) do
		UI.Tooltip.SetPlace(each.key, ns.db[Settings.PlaceKey(each.key)])
	end
end

-- The words a place is shown as, for the reading and the slash word.
function Settings.PlaceText(word)
	for _, each in ipairs(Settings.PLACES) do
		if each.value == word then
			return each.text
		end
	end
	return tostring(word)
end

-- One sentence per type, for the slash word: "bag item: attached".
function Settings.DescribePlaces()
	local lines = {}
	for _, each in ipairs(UI.Tooltip.TYPES) do
		lines[#lines + 1] = each.label .. ": " .. Settings.PlaceText(Settings.Place(each.key))
	end
	return lines
end

--------------------------------------------------------------------------

Settings.LINGER_STEP = 0.25

function Settings.Linger()
	return UI.Tooltip.Linger()
end

function Settings.SetLinger(seconds)
	UI.Tooltip.SetLinger(seconds)
	ns.db.tipLinger = UI.Tooltip.Linger()
	return ns.db.tipLinger
end

-- "1s", "0.5s", "off". Written the way Settings.Label is and for the same
-- reason: a lookup table of stops is a table that has to be kept in step with
-- the range UI/Tooltip.lua owns.
function Settings.LingerLabel(seconds)
	seconds = tonumber(seconds) or 0
	if seconds <= 0 then
		return "off"
	end
	local text = ("%.2f"):format(seconds)
	text = (text:gsub("0+$", ""))
	text = (text:gsub("%.$", ""))
	return text .. "s"
end

function Settings.DescribeLinger()
	local seconds = Settings.Linger()
	if seconds <= 0 then
		return "goes the instant you look away, which is what the client's own does"
	end
	return ("stays %s after you look away, and any other hover replaces it at once")
		:format(Settings.LingerLabel(seconds))
end

--------------------------------------------------------------------------

function Settings.TipFont()
	return UI.Tooltip.Font()
end

function Settings.SetTipFont(size)
	UI.Tooltip.SetFont(size)
	ns.db.tipFont = UI.Tooltip.Font()
	return ns.db.tipFont
end

-- How much darker than the palette the box's floor is, in percent.
function Settings.TipShade()
	return UI.Tooltip.Shade()
end

function Settings.SetTipShade(percent)
	UI.Tooltip.SetShade(percent)
	ns.db.tipShade = UI.Tooltip.Shade()
	return ns.db.tipShade
end

function Settings.DescribeTipFont()
	return ("%d px, and the title a pixel over it"):format(Settings.TipFont())
end

--------------------------------------------------------------------------

-- Whether a hover over gear opens what you are wearing beside it.
--
-- Here rather than in Character/, beside the other three answers about what a
-- hover's box does, because that is what it is: every item hover in the addon
-- gets it and none of them is the character sheet's. Character/Compare.lua is
-- the part that knows what a ring is; this is the part that knows the setting
-- is called tipCompare, and the two do not meet.

function Settings.Compare()
	return ns.Compare.Enabled()
end

function Settings.SetCompare(on)
	ns.db.tipCompare = on and true or false
	ns.Compare.SetEnabled(ns.db.tipCompare)
	return ns.db.tipCompare
end

-- The stops that keep the grid on this screen, as a phrase a note can drop into
-- a sentence. A stop is exact when the screen's own step times the size is
-- whole, so the answer depends on the monitor and cannot be a constant: at
-- screen zoom 1 it is the three whole sizes, at 2 it is every half step.
function Settings.Grid()
	local screen = UI.ScreenZoom()
	local names = {}
	local stop = Settings.LOW
	while stop <= Settings.HIGH + 1e-6 do
		if UI.Exact(screen * stop) then
			names[#names + 1] = Settings.Label(stop)
		end
		stop = stop + Settings.STEP
	end
	if #names == 0 then
		return "no stop on this screen"
	end
	if #names == 1 then
		return names[1]
	end
	return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end

-- What a window measures on this screen right now, in physical pixels. The
-- panel is the one worth quoting because it is the one you are looking at while
-- you drag a row, and it is UI.Windows[1] because Core/Panel.lua builds at
-- PLAYER_LOGIN and everything else in the addon builds its window on first use.
function Settings.Pixels()
	local window = UI.Windows[1]
	if not window then
		return nil
	end
	local zoom = window.zoom or 1
	return window.width * zoom, window.height * zoom
end

-- The short form, for the `?` in a zoom row's corner. Which stop this screen is
-- on and what that stop costs, and nothing else: the screen's own contribution
-- and the panel's measured size are facts about the window and the monitor, not
-- about this row, and the reading at the foot of the list says both once.
--
-- Its own function rather than a flag on Describe, because a hover box is read
-- in the half second before you move on and the two sentences are written for
-- different amounts of attention.
function Settings.DescribeStop(key)
	local chosen = Settings.Snap(ns.db[key])
	local zoom = UI.ScreenZoom() * chosen

	if not UI.Supported() then
		return ("%s, and this client has no SetIgnoreParentScale, so the size"
			.. " lands on whatever the UI scale leaves"):format(Settings.Label(chosen))
	end
	if UI.Exact(zoom) then
		return ("%s, and one unit is a whole number of pixels, so every edge is exact")
			:format(Settings.Label(chosen))
	end
	return ("%s, and one unit is %.2f pixels, so a hairline draws soft")
		:format(Settings.Label(chosen), zoom)
end

-- One sentence saying what one screen's size is doing, and it does not flatter
-- the setting. A stop that costs the grid says so, in the same terms UI.Describe
-- uses for the grid itself, because a control that hides its own cost is a
-- control you cannot make a decision with.
--
-- Takes a key rather than reading one, so the zoom page can put the sentence
-- under every row it draws. Left out, it answers for the panel you are reading
-- it in, which is what /wk status wants.
function Settings.Describe(key)
	local chosen = Settings.Snap(ns.db[key or "panelZoom"])
	local zoom = UI.ScreenZoom() * chosen
	local screen = UI.ScreenZoom()

	local edges
	if not UI.Supported() then
		edges = "this client has no SetIgnoreParentScale, so windows sit on the UI"
			.. " scale and the size is applied to whatever that leaves them at"
	elseif zoom == 1 then
		edges = "one unit is one pixel, so every edge is exact"
	elseif UI.Exact(zoom) then
		edges = ("one unit is a %dx%d block of pixels, so every edge is exact"):format(zoom, zoom)
	else
		edges = ("one unit is %.2f pixels, so a hairline draws soft"):format(zoom)
	end

	-- Only for the panel. Every other screen on the zoom page is a window that
	-- may not have been built yet, and a measurement of a frame that does not
	-- exist is a sentence with a hole in it.
	local measured = ""
	if not key or key == "panelZoom" then
		local width, height = Settings.Pixels()
		measured = width and (", panel %d x %d px"):format(width, height) or ""
	end

	if screen == 1 then
		return ("%s%s, %s"):format(Settings.Label(chosen), measured, edges)
	end
	return ("%s on a %d pixel screen the addon already zooms %dx%s, %s")
		:format(Settings.Label(chosen), UI.ScreenHeight(), screen, measured, edges)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON then
		return
	end
	-- Core's own ADDON_LOADED handler registered first and so ran first, which
	-- is what makes ns.db readable here. Nothing else in the addon depends on
	-- that ordering, so it is stated rather than assumed.
	Settings.Apply()
	self:UnregisterEvent("ADDON_LOADED")
end)
