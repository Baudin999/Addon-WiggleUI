local ADDON, ns = ...

local Trace = {}
ns.PetTrace = Trace

--------------------------------------------------------------------------
-- What a press on a pet ability did
--
-- Off, and worth nothing until it is on. `/wk talents trace` turns it on, and
-- every hover and press on the pet's page then says in chat what the client was
-- asked and what it answered.
--
-- **It exists because the page has been wrong three times and each time the
-- symptom was the same word: nothing.** A row the page judged unteachable, a
-- click that landed on the row instead of the secure button, a press that
-- reached Blizzard's create button while it was disabled, and a DoCraft the
-- client refused all look identical from a chair. The lines tell them apart:
--
--   hover     whether the secure button went over the row, and if not, why
--   click     a press that landed on the row itself, and what the mouse is on
--   press     the selection and the create button before and after the pick
--   after     whether Blizzard's create button ran its OnClick, which is the
--             only caller of DoCraft
--   events    BLOCKED, FORBIDDEN and the client's red error line, as they come
--
-- **Nothing here is allowed to break a press.** The hook on the create button
-- runs after Blizzard's own OnClick, every read is a plain answer rather than a
-- write, and the whole file is a no-op while it is off. The switch is not
-- saved: a trace left on across a login is a chat frame nobody can read.
--------------------------------------------------------------------------

local on = false

-- Whether the hook is on Blizzard's create button, and whether that button ran
-- its OnClick since the last press began.
local hooked, reached = false, false

local EVENTS = {
	"ADDON_ACTION_BLOCKED",
	"ADDON_ACTION_FORBIDDEN",
	"UI_ERROR_MESSAGE",
	"CRAFT_UPDATE",
	"UNIT_PET_TRAINING_POINTS",
}

local function Say(line)
	ns.Print("pet " .. line)
end

-- A frame by its name, or by its parent's where it has none of its own.
local function Name(frame)
	if type(frame) ~= "table" or type(frame.GetName) ~= "function" then
		return "nothing"
	end
	local name = frame:GetName()
	if name then
		return name
	end
	local parent = frame:GetParent()
	local above = parent and parent:GetName()
	return above and ("unnamed on " .. above) or "unnamed"
end

local function Selection()
	local ok, index = pcall(GetCraftSelectionIndex)
	return ok and tostring(index) or "unreadable"
end

-- Blizzard's create button, in the two facts a click on it needs.
local function Create()
	local button = ns.CraftCreateButton()
	if not button then
		return "create button absent"
	end
	return ("create button %s and %s"):format(button:IsEnabled() and "enabled" or "disabled",
		button:IsVisible() and "visible" or "not visible")
end

-- After Blizzard's OnClick, never in place of it. Put on the first time the
-- trace can see the button, because Blizzard_CraftUI loads on demand.
local function Hook()
	if hooked then
		return
	end
	local button = ns.CraftCreateButton()
	if not button or type(button.HookScript) ~= "function" then
		return
	end
	hooked = pcall(button.HookScript, button, "OnClick", function()
		reached = true
		if on then
			Say(("CraftCreateButton ran its OnClick, DoCraft on selection %s"):format(Selection()))
		end
	end)
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnEvent", function(_, event, first, second)
	Say(("%s %s %s"):format(event, tostring(first), tostring(second)))
end)

--------------------------------------------------------------------------
-- The lines
--------------------------------------------------------------------------

-- A hover, with the page's reading of the row and what came of it.
function Trace.Hover(row, petLevel, left, armed, why)
	if not on then
		return
	end
	Hook()
	Say(("hover %s %s, row %s: pet level %d of %d, points %d of %d; %s"):format(
		tostring(row.name), tostring(row.rank), tostring(row.index),
		petLevel, row.level or 0, left, row.cost or 0,
		armed and why or ("no secure button, " .. why)))
end

-- A press the row itself took, which means the secure button was not under it.
function Trace.Missed(row, teach)
	if not on then
		return
	end
	Say(("click on %s landed on the row, not the secure button: secure button %s, the mouse is on %s"):format(
		tostring(row.name), teach:IsShown() and "shown" or "hidden", Name(ns.MouseFocus())))
end

-- The secure button's PreClick, before the pick and after it.
function Trace.Press(row, teach, phase)
	if not on then
		return
	end
	Hook()
	if phase == "before" then
		reached = false
	end
	Say(("press %s on %s: selection %s, %s, clickbutton %s"):format(phase,
		row and tostring(row.name) or "no row", Selection(), Create(),
		Name(teach:GetAttribute("clickbutton"))))
end

-- The secure button's PostClick.
function Trace.After(row)
	if not on then
		return
	end
	Say(("after the press on %s: %s"):format(row and tostring(row.name) or "no row",
		reached and "Blizzard's button ran"
			or "Blizzard's button never ran, so DoCraft was not called"))
end

--------------------------------------------------------------------------
-- The switch
--------------------------------------------------------------------------

function Trace.Set(value)
	on = value and true or false
	if on then
		Hook()
		for index = 1, #EVENTS do
			pcall(watcher.RegisterEvent, watcher, EVENTS[index])
		end
	else
		watcher:UnregisterAllEvents()
	end
	return on
end

function Trace.On()
	return on
end

-- What the trace can see before anything is pressed.
function Trace.Describe()
	if not on then
		return "off"
	end
	return ("on; beast training %s, selection %s, %s"):format(
		ns.TalentTraining.Open() and "open" or "shut", Selection(), Create())
end
