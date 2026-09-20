local ADDON, ns = ...

local UI = ns.UI
local Press = {}
UI.Press = Press

--------------------------------------------------------------------------
-- Secure buttons, and the edge each one fires on
--
-- Every button in this addon that makes a protected call is built here, and
-- every button registers its clicks here. check.sh holds every other file to
-- that: nothing outside this file names RegisterForClicks,
-- SecureActionButtonTemplate, SecureAuraHeaderTemplate or useOnKeyDown, and
-- nothing outside UI/ names SecureHandlerClickTemplate.
--
-- The reason is one bug, shipped three times. A secure action button does not
-- act on the edge it registered for. It asks its own `useOnKeyDown` attribute,
-- falls back to the player's ActionButtonUseKeyDown setting where the button
-- does not answer, and on the other edge does nothing whatever its attributes
-- say. That setting is on by default on the Anniversary client. So a button
-- registered for the release against an unset attribute draws, hovers, binds,
-- reads back as bound, and does nothing: the cloned action bars went dark under
-- their keys, the hover keys cast nothing, and the gear squares could not take
-- a sharpening stone. Each fix was the same two lines in a different file, and
-- the next file wrote them again from memory or did not.
--
-- So the two settings are one argument here and cannot disagree. `edge` is
-- "up" or "down"; the registration and the attribute are both written from it.
-- Registering both edges against one attribute is not offered, because it
-- hides which edge is live and buys nothing: the client dispatches one of them.
--
-- A mouse press is the one exception the client makes, and it only matters to
-- a button the cursor can reach. The secure half treats a real mouse click as
-- a release whatever the attribute says, so a button meant for the mouse is
-- "up", and "down" is for a button only a key binding ever presses.
--
-- Keys are the second shape. A key bound with SetOverrideBindingClick onto a
-- SecureHandlerClickTemplate button runs the button's snippet on every edge
-- the button registered, with no attribute to consult at all. One edge is one
-- run; both edges is two runs, which is the right answer only for a key whose
-- snippet reads the edge and does something different on each.
--------------------------------------------------------------------------

local ACTION = "SecureActionButtonTemplate"
local HANDLER = "SecureHandlerClickTemplate"
local AURAS = "SecureAuraHeaderTemplate"

-- The registration for one edge, for every mouse button named or for all of
-- them. Built into a list the caller's varargs fill, because RegisterForClicks
-- takes its names loose. What it registers is what the button keeps from the
-- camera, see Press.Keep at the foot of this file.
local function Register(button, edge, ...)
	button.wuiEdge = edge
	local suffix = edge == "down" and "Down" or "Up"
	local count = select("#", ...)
	if count == 0 then
		button:RegisterForClicks("Any" .. suffix)
		Press.Keep(button)
		return
	end
	local names = {}
	for index = 1, count do
		names[index] = select(index, ...) .. suffix
	end
	button:RegisterForClicks(unpack(names))
	Press.Keep(button, ...)
end

-- A secure action button that fires on `edge`, for the mouse buttons named
-- after it or for all of them. `name` may be nil. Everything else about the
-- button, its size, its art and its attributes, is the caller's.
function Press.Button(parent, name, edge, ...)
	assert(edge == "up" or edge == "down", "Press.Button: edge is \"up\" or \"down\"")
	local button = CreateFrame("Button", name, parent, ACTION)
	Register(button, edge, ...)
	button:SetAttribute("useOnKeyDown", edge == "down")
	return button
end

-- A named button a key is bound to with SetOverrideBindingClick, running the
-- snippet the caller writes into `_onclick`. "down" for a key that acts once
-- per press, "both" for a key whose snippet reads the edge it was handed and
-- does one thing on the press and another on the release.
function Press.Key(name, edge)
	assert(edge == "down" or edge == "both", "Press.Key: edge is \"down\" or \"both\"")
	local key = CreateFrame("Button", name, UIParent, HANDLER)
	key.wuiEdge = edge
	if edge == "both" then
		key:RegisterForClicks("AnyDown", "AnyUp")
	else
		key:RegisterForClicks("AnyDown")
	end
	return key
end

-- A secure action button a held key presses, acting on the release.
--
-- The one shape that registers both edges against one attribute, and it earns
-- the exception above by needing both runs of a snippet and only one action. A
-- header wraps its OnClick: the pre body sees the press and the release, and
-- the client's half acts on the release alone because `useOnKeyDown` is false.
-- That is 2.5.6 SecureActionButton_OnClick read straight: with the attribute
-- false the down edge is neither the click nor a held release, so it does
-- nothing, and the up edge is the click. An OPie ring is this button: the key
-- opens the ring, the release is the hardware event, and the pre body writes
-- the slice the cursor points at onto the button before the client reads it.
--
-- Answers "both" to Press.Edge, like Press.Key, because UI/Bound.lua asks for
-- an edge before it binds a key to anything.
function Press.Held(name)
	local button = CreateFrame("Button", name, UIParent, ACTION)
	button.wuiEdge = "both"
	button:RegisterForClicks("AnyDown", "AnyUp")
	button:SetAttribute("useOnKeyDown", false)
	return button
end

-- A button that is not secure, answering `edge` for the mouse buttons named or
-- for all of them. A plain button's OnClick runs on whatever it registered, so
-- there is no attribute to keep in step here. The call is here so that every
-- registration in the addon is one function, and which buttons a frame answers
-- is a question with one place to ask it. "up" for anything the cursor
-- presses, "down" for a key a binding presses that acts on the press.
function Press.Clicks(button, edge, ...)
	assert(edge == "up" or edge == "down", "Press.Clicks: edge is \"up\" or \"down\"")
	Register(button, edge, ...)
	return button
end

-- Which edge a button fires on, and where the answer came from. A button
-- this file built says what it registered, which is the only answer for a
-- plain button: it has no attribute, and the player's setting said "down" for
-- a Press.Clicks "up" button, so a `/click` sent from the hover macro onto one
-- arrived on the edge it drops. "both" answers "down", the half a single
-- `/click` can send. For anything else, the way the client works it out: the
-- button's own attribute, and the player's setting where it does not answer.
function Press.Edge(button)
	local built = button and button.wuiEdge
	if built then
		return built == "up" and "up" or "down", "UI.Press"
	end
	local set = button and button.GetAttribute and button:GetAttribute("useOnKeyDown")
	if set ~= nil then
		return set and "down" or "up", "useOnKeyDown attribute"
	end
	local cvar = type(GetCVarBool) == "function" and GetCVarBool("ActionButtonUseKeyDown")
	return cvar and "down" or "up", "ActionButtonUseKeyDown setting"
end

--------------------------------------------------------------------------
-- Cancelling your own buffs
--
-- A right click on a buff takes it off, and the call that does it is refused
-- to an addon in combat. The client's own buff frame makes it through
-- SecureAuraHeaderTemplate: a header that walks your auras from secure code
-- on every UNIT_AURA, hands each child button the index of the aura it stands
-- for, and lays the children out in a grid. The child's `type2` is
-- `cancelaura`, and the secure template cancels buff `index` on the player
-- when the right button is released over it. Nothing in that chain is Lua this
-- addon wrote, so it runs in combat.
--
-- Only the player. The client's cancelaura is written against "player" and
-- nothing else, and CancelUnitBuff answers any other unit by doing nothing.
--
-- The children are built here, out of combat, rather than left to the header.
-- A child the header builds itself is registered by its template for the
-- right button's press, and restricted code cannot re-register it, so it would
-- be the dead-click shape this file exists to stop. The header uses a child it
-- is handed before it builds one, so it is handed all of them: `count` buffs,
-- capped with maxAuraCount so it never reaches for a thirty-third, and the two
-- weapon enchants when `hands` is set, which cancelaura answers by the hand's
-- inventory slot.
--
-- Where the grid goes is the caller's: the header's point, xOffset,
-- wrapAfter and wrapYOffset attributes, and the children's size, all written
-- out of combat. Returns nil on a client with no such template.
--------------------------------------------------------------------------

local function Cancel(header)
	local button = Press.Button(header, nil, "up", "RightButton")
	button:SetAttribute("type2", "cancelaura")
	button:Hide()
	return button
end

function Press.Cancels(parent, name, filter, count, hands)
	local ok, header = pcall(CreateFrame, "Frame", name, parent, AURAS)
	if not ok or not header then
		return nil
	end
	header:SetAttribute("unit", "player")
	header:SetAttribute("filter", filter)
	header:SetAttribute("template", ACTION)
	header:SetAttribute("sortMethod", "INDEX")
	header:SetAttribute("maxAuraCount", count)
	local buttons = {}
	for index = 1, count do
		buttons[index] = Cancel(header)
		header:SetAttribute("child" .. index, buttons[index])
	end
	if hands then
		header:SetAttribute("includeWeapons", 1)
		for hand = 1, 2 do
			buttons[count + hand] = Cancel(header)
			header:SetAttribute("tempEnchant" .. hand, buttons[count + hand])
		end
	end
	return header, buttons
end

--------------------------------------------------------------------------
-- Which buttons a frame keeps, and which go to the camera
--
-- A mouse enabled frame swallows every button that lands on it, and the right
-- button drag that turns the camera is one of those. Everything in this addon
-- you can hover sits over the middle of the screen, which is exactly where that
-- drag starts, so a tooltip bought at the price of a camera that will not turn
-- is a bad trade made silently.
--
-- The buttons a frame answers and the buttons it hands on are one decision,
-- and it used to be written in two places that did not read each other. A row
-- registered the right button in one call and passed it to the camera in the
-- next, and a button passed through never reaches the frame's scripts: the
-- mail window's rows and slots, the meter's rows and the dungeon log's rows
-- each drew a right click they could not receive, and the action squares, the
-- bag squares, the list rows and the unit frames each carried a paragraph on
-- why they skipped the pass. So what Register writes is what the frame keeps,
-- Press.Keep says it for a frame that reads the button in OnMouseUp, and
-- UI.PassCamera hands over only what is left. Either may be called first.
--
-- There are two shapes of the pass and the client answers only one of them.
--
-- **A frame that answers a click and wants the other buttons back** is
-- UI.PassCamera, and SetPassThroughButtons is the only call that does it. That
-- one arrived in 10.1.5 and this client is 2.5.6: nothing on disk calls it
-- outside a retail path, and Questie's map library stubs it to a no-op for a
-- retail bug. So it is probed, and on the live client the probe fails and a
-- right drag begun on such a frame still stops there. Those frames are buttons
-- inside windows and none of them is large.
--
-- **A frame whose whole answer is the hover** is UI.HoverOnly, and that one the
-- client does have. Motion and clicks are separate flags: turn the clicks off
-- and every button that lands on the frame falls through to the world, while
-- OnEnter and OnLeave still fire. SetMouseClickEnabled arrived in 9.0 and was
-- backported; OPie ships `## Interface: 20506` and calls it unguarded on a
-- slider thumb it hangs OnEnter on, which is the same frame in the same shape.
--
-- The difference is worth the two functions because the character sheet is the
-- size of the monitor. Nineteen gear rows, four readings and a column of stats
-- answer nothing but the hover, and passed through SetPassThroughButtons alone
-- they were most of a screen the camera would not turn in.
--------------------------------------------------------------------------

local CAMERA = { "RightButton", "MiddleButton" }

-- The camera's buttons this frame does not keep, handed on. A frame that keeps
-- all of them and never passed any is not written to at all, because the unit
-- frames are secure buttons and nothing is gained by touching one.
local function Pass(owner)
	if type(owner.SetPassThroughButtons) ~= "function" then
		return false
	end
	local keeps, pass = owner.wuiKeeps, {}
	for index = 1, #CAMERA do
		local name = CAMERA[index]
		if not (keeps and (keeps.Any or keeps[name])) then
			pass[#pass + 1] = name
		end
	end
	if #pass == 0 and not owner.wuiPassed then
		return true
	end
	owner.wuiPassed = #pass > 0
	return pcall(owner.SetPassThroughButtons, owner, unpack(pass))
end

-- The mouse buttons a frame answers, named, or all of them with none named.
-- Replaces what it kept before, because a registration replaces the one before
-- it. Press.Clicks and Press.Button say it for the buttons they register; a
-- frame that reads the button in OnMouseUp says it here.
function Press.Keep(frame, ...)
	local keeps = {}
	local count = select("#", ...)
	if count == 0 then
		keeps.Any = true
	end
	for index = 1, count do
		keeps[select(index, ...)] = true
	end
	frame.wuiKeeps = keeps
	if frame.wuiPasses then
		Pass(frame)
	end
	return frame
end

function UI.PassCamera(owner)
	owner.wuiPasses = true
	return Pass(owner)
end

-- The mouse for the hover and nothing else. EnableMouse first because that is
-- what turns motion on, then the clicks off, because a frame with no clicks and
-- no motion is a frame with no mouse at all.
--
-- Falls back to handing the camera its two buttons where the client has no
-- click flag, which is the most a caller could have asked for before this
-- existed.
function UI.HoverOnly(owner)
	owner:EnableMouse(true)
	if type(owner.SetMouseClickEnabled) == "function"
		and pcall(owner.SetMouseClickEnabled, owner, false) then
		return true
	end
	return UI.PassCamera(owner)
end
