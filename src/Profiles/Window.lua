local ADDON, ns = ...

local Profiles = ns.Profiles
local UI = ns.UI
local C, M = UI.Color, UI.Metric

--------------------------------------------------------------------------
-- The string, in a box
--
-- The client has no clipboard call, so a profile leaves the game the way a
-- chat room does in Chat/Copy.lua: selected in an edit box that holds the
-- keyboard, waiting for Ctrl-C. Coming in is the same box, empty, waiting for
-- Ctrl-V, with a button under it.
--
-- One window for both, reused, for the reason UI/Ask.lua gives. Showing the
-- export puts back anything typed over it, so what you copy is always the
-- profile and never a stray key.
--------------------------------------------------------------------------

local FRAME_NAME = "WarriorKitProfileString"
local WIDTH, HEIGHT = 480, 320

-- Letters per line of an export. The reader drops line breaks, so the string
-- is broken up for the eye and for the height the field is told it has.
local WRAP = 56
local LINE = M.font + 2

local window, view, edit, action, note
local exported -- the export on show, or nil while the box takes a paste

local function Fit(text)
	local lines = 1
	for _ in text:gmatch("\n") do
		lines = lines + 1
	end
	lines = lines + math.floor(#text / WRAP)
	local height = math.max(lines * LINE + M.rowGap, view.frame:GetHeight() or 0)
	edit:SetHeight(height)
	view:Update(height)
end

local function Wrapped(text)
	local out = {}
	for at = 1, #text, WRAP do
		out[#out + 1] = text:sub(at, at + WRAP - 1)
	end
	return table.concat(out, "\n")
end

local function Press()
	if exported then
		window:Hide()
		return
	end
	local name, kept, dropped = Profiles.Import(edit:GetText())
	if not name then
		note:SetText(kept)
		return
	end
	Profiles.Use(name)
	ns.Print(("imported %q with %d setting%s%s. Reloading to wear it."):format(
		name, kept, kept == 1 and "" or "s",
		dropped > 0 and (", %d this version does not have"):format(dropped) or ""))
	ReloadUI()
end

local function BuildField()
	edit = CreateFrame("EditBox", nil, view.canvas)
	edit:SetMultiLine(true)
	edit:SetPoint("TOPLEFT")
	edit:SetPoint("TOPRIGHT")
	edit:SetFontObject(UI.Font(M.font, UI.FLAT))
	edit:SetTextColor(C.text[1], C.text[2], C.text[3])
	edit:SetAutoFocus(false)
	if type(edit.SetMaxLetters) == "function" then
		edit:SetMaxLetters(0)
	end
	edit:SetScript("OnTextChanged", function(self, userInput)
		if userInput and exported then
			self:SetText(exported)
		elseif userInput then
			note:SetText("")
			Fit(self:GetText())
		end
	end)
	edit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		window:Hide()
	end)
	edit:SetScript("OnEditFocusGained", function(self)
		UI.CloseDropdown()
		UI.StopCapture()
		UI.Typing(self)
	end)
	edit:SetScript("OnEditFocusLost", function()
		UI.StopTyping()
	end)
	edit:SetScript("OnHide", function(self)
		self:ClearFocus()
	end)
end

local function Build()
	if window then
		return window
	end
	window = UI.Window({ name = FRAME_NAME, title = "Profile", width = WIDTH, height = HEIGHT })

	view = UI.ScrollView(window.content)
	view.frame:SetPoint("TOPLEFT", M.pad, -M.pad)
	view:Resize(WIDTH - M.pad * 2, window:Body() - M.pad * 2)
	BuildField()

	action = UI.Button(window.footer, { label = "done", width = 150, height = M.row, onClick = Press })
	action:SetPoint("RIGHT", -M.pad, 0)
	note = UI.Label(window.footer, M.small, C.quiet, "LEFT", UI.FLAT)
	note:SetPoint("LEFT", M.pad, 0)
	note:SetPoint("RIGHT", action, "LEFT", -M.pad, 0)
	UI.Wrap(note, false)
	return window
end

local function Open(title, text, button, hint)
	Build()
	window:SetTitle(title)
	action.text:SetText(button)
	note:SetText(hint)
	edit:SetText(text)
	Fit(text)
	view:ScrollTo(0)
	window:Show()
	edit:SetFocus()
	return edit
end

-- The active profile, selected. Returns the field so the harness can read it.
function Profiles.ShowExport()
	exported = Wrapped(Profiles.Export())
	local field = Open(("Export %s"):format(Profiles.Active()), exported, "done",
		"Ctrl-C copies it")
	field:HighlightText()
	return field
end

function Profiles.ShowImport()
	exported = nil
	return Open("Import a profile", "", "import and wear it", "Ctrl-V pastes a string")
end

-- The import button, for the slash word and the harness.
Profiles.Press = Press

function Profiles.WindowShown()
	return window ~= nil and window:IsShown() and true or false
end
