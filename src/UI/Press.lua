local ADDON, ns = ...

local UI = ns.UI
local Press = {}
UI.Press = Press

--------------------------------------------------------------------------
-- Secure buttons, and the edge each one fires on
--
-- Every button in this addon that makes a protected call is built here, and
-- check.sh holds every other file to that: nothing outside this file names
-- SecureActionButtonTemplate or useOnKeyDown, and nothing outside UI/ names
-- SecureHandlerClickTemplate.
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

-- The registration for one edge, for every mouse button named or for all of
-- them. Built into a list the caller's varargs fill, because RegisterForClicks
-- takes its names loose.
local function Register(button, edge, ...)
	local suffix = edge == "down" and "Down" or "Up"
	local count = select("#", ...)
	if count == 0 then
		button:RegisterForClicks("Any" .. suffix)
		return
	end
	local names = {}
	for index = 1, count do
		names[index] = select(index, ...) .. suffix
	end
	button:RegisterForClicks(unpack(names))
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
	if edge == "both" then
		key:RegisterForClicks("AnyDown", "AnyUp")
	else
		key:RegisterForClicks("AnyDown")
	end
	return key
end

-- Which edge a secure action button fires on, worked out the way the client
-- works it out, and where the answer came from. The button's own attribute,
-- and the player's setting where the button does not answer. A button this
-- file built always answers; the client's own buttons do not.
function Press.Edge(button)
	local set = button and button.GetAttribute and button:GetAttribute("useOnKeyDown")
	if set ~= nil then
		return set and "down" or "up", "useOnKeyDown attribute"
	end
	local cvar = type(GetCVarBool) == "function" and GetCVarBool("ActionButtonUseKeyDown")
	return cvar and "down" or "up", "ActionButtonUseKeyDown setting"
end
