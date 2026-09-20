local ADDON, ns = ...

local UI = ns.UI
local C, M = UI.Color, UI.Metric

--------------------------------------------------------------------------
-- What do you want to call it
--
-- One line typed before a thing is made. An ad hoc bar is the first of them:
-- the plus on the tab strip used to make `Bar 3` and leave you to find the
-- name field and type over what it had invented, so the first thing the page
-- did was name the bar for you and the second was ask you to correct it.
--
-- It is the third window of its kind, after UI/Ask.lua's yes and no and
-- UI/Amount.lua's how many, and it is here for the reason both of those are
-- here: the question has the same shape everywhere it is asked. What is this
-- called, a field, and a button that makes it.
--
-- **Nothing is made until it is answered.** The caller hands over what to do
-- with the name and does nothing itself, so a window closed with the cross or
-- with Escape leaves the list exactly as it was. That is the whole point of
-- asking first: a bar on the strip is a bar somebody called something.
--
-- **An empty field is refused rather than filled in.** The window stays up and
-- the line under the field says it needs a name. A default typed in for you is
-- how the old plus behaved, and a window that asks a question and then answers
-- it itself is worse than no window.
--
-- **One window, reused**, for the reason UI/Ask.lua gives: this client cannot
-- destroy a frame, so a window made per question is a window leaked per
-- question, and two of these cannot be on the screen at once.
--------------------------------------------------------------------------

local WIDTH = 300

-- The window, and what it is asking about right now. `asked` is nil whenever
-- nothing is on the screen, which is what makes UI.Naming answerable and what
-- stops a stale callback firing after the window was closed some other way.
local window, asked = nil, nil

local function Close()
	asked = nil
	if window then
		window:Hide()
	end
end

local function Typed()
	local text = window.field.edit:GetText() or ""
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function Build()
	if window then
		return window
	end

	window = UI.Window({
		name = "WiggleUIName",
		title = "",
		width = WIDTH,
		height = M.title + M.footer + M.pad * 2 + M.control + M.rowGap + M.row,
		-- Over every other window in the addon, for the reason UI/Ask.lua sits
		-- there: this one is opened off a control in the settings window, which
		-- is on DIALOG, and a question that opens behind the window that asked
		-- it is a question nobody answers.
		strata = "FULLSCREEN_DIALOG",
	})

	-- Enter is the accept rather than a commit, because the field is the whole
	-- of what this window collects and there is nothing to commit it to until
	-- the window is answered.
	window.field = UI.Field(window.content, {
		width = WIDTH - M.pad * 2,
		max = 24,
		onEnter = function(typed) UI.Called(typed) end,
	})
	window.field:SetPoint("TOPLEFT", M.pad, -M.pad)

	window.note = UI.Label(window.content, M.small, C.quiet, "LEFT", UI.FLAT)
	window.note:SetPoint("TOPLEFT", window.field, "BOTTOMLEFT", 0, -M.rowGap)
	window.note:SetWidth(WIDTH - M.pad * 2)
	UI.Wrap(window.note, true)

	window.accept = UI.Button(window.footer, {
		label = "make it",
		width = 92,
		tone = C.accent,
		onClick = function() UI.Called(Typed()) end,
	})
	window.accept:SetPoint("RIGHT", 0, 0)

	window.refuse = UI.Button(window.footer, {
		label = "cancel",
		width = 76,
		onClick = function() UI.Called(nil) end,
	})
	window.refuse:SetPoint("RIGHT", window.accept, "LEFT", -M.rowGap, 0)

	-- Escape, the close box and anything else that takes the window off the
	-- screen are the same answer, and it is no. Hung on the frame rather than
	-- on the method for the reason UI/Ask.lua hangs its own there.
	window.frame:HookScript("OnHide", function()
		asked = nil
	end)
	return window
end

--------------------------------------------------------------------------

-- Ask for a name.
--
--   title     what the window is called
--   note      the quiet line under the field
--   accept    the word on the button that makes the thing
--   text      what the field starts with, which is usually nothing
--   onAccept  handed the name, and called only when one was given
--
-- Answers the title, so a caller can say what it asked without keeping a copy.
function UI.Name(opts)
	Build()
	asked = opts.title or ""

	window:SetTitle(asked)
	window.wants = opts.note or ""
	window.note:SetText(window.wants)
	window.note:SetTextColor(C.quiet[1], C.quiet[2], C.quiet[3])
	window.accept.text:SetText(opts.accept or "make it")
	window.onAccept = opts.onAccept
	window.field.edit:SetText(opts.text or "")
	window:Show()
	-- The keyboard goes to the field as the window comes up. It is the one
	-- control on it, and a window you have to click before you can type into it
	-- is a click nobody can explain.
	window.field.edit:SetFocus()
	return asked
end

-- The title of the question on the screen now, or nil. Public for the reason
-- UI.Asking is: a part that put one up has to be able to tell whether it has
-- been dealt with, and it is the only way a test can see the window without
-- naming its frames.
function UI.Naming()
	return asked
end

-- Answer it. A name accepts, nil closes it with nothing done, and a name that
-- is nothing but spaces is refused: the window stays up and says what it wants.
-- Answers whether the window is off the screen, which is not the same as
-- whether anything was made.
function UI.Called(name)
	if not asked then
		return false
	end
	if name ~= nil then
		local text = (tostring(name):gsub("^%s+", ""):gsub("%s+$", ""))
		if text == "" then
			window.note:SetText("it needs a name.")
			window.note:SetTextColor(C.danger[1], C.danger[2], C.danger[3])
			return false
		end
		local accept = window.onAccept
		Close()
		if accept then
			accept(text)
		end
		return true
	end
	Close()
	return true
end
