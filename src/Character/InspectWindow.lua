local ADDON, ns = ...

local Window = {}
ns.InspectWindow = Window

local UI = ns.UI
local C, M = UI.Color, UI.Metric

--------------------------------------------------------------------------
-- Somebody else's character sheet
--
-- The same page, in a window that behaves the way every other window in this
-- addon behaves. Character/Paperdoll.lua draws it, `inspect` is the one thing
-- this hands it, and the head of that file says what the flag changes.
--
-- **This is an ordinary window and your own sheet is not, and the difference is
-- the whole reason the two are separate frames.** Your sheet carries twenty
-- secure buttons, because using what is in one of your slots is protected, and
-- that makes the window itself protected: showing it, hiding it, moving it and
-- sizing it are all refused in a fight, which is why it opens on a snippet
-- bound to the C key and has a title bar it cannot be dragged by.
--
-- None of that applies here. An inspect page has no secure buttons on it,
-- because `/use 5` written on a square drawn for somebody else's chest would
-- take your own chestpiece off. So this window has nothing protected inside it:
-- no snippet, no override binding, no combat refusal, and a title bar with a
-- cross on it like the other eleven. It also means it is built on first open
-- the way everything except the sheet is, and a player who never inspects
-- anybody pays for none of it.
--
-- **It opens over your own sheet rather than instead of it.** Two sheets on the
-- screen at once is the comparison: yours is pinned to the edge of the monitor
-- with no chrome, and this one is a window you drag next to it. Nothing is
-- hidden to make room, because deciding that for the player is how a window
-- ends up fighting the one it was meant to sit beside.
--
-- **Nothing is painted while it is shut.** The page walks twenty slots, reads
-- an enchant off each and asks the client about three talent trees, and doing
-- that to answer a window nobody has open is the waste this addon has a gate
-- for. Character/Inspect.lua's events all end in Refresh, which asks first.
--------------------------------------------------------------------------

local window, page, footer

--------------------------------------------------------------------------

-- The page asks how big it is worth drawing at and the window is made that
-- size, the same subtraction the sheet's own Fit makes. There is no lockdown
-- branch here and that is the point: nothing in this window is protected, so a
-- resize in the middle of a fight is an ordinary resize.
function Window.Fit()
	if not (window and page) then
		return false
	end
	local wide, tall = page:Natural()
	window:Resize(wide + M.pad * 2, tall + M.pad * 2 + window.foot + window.chrome)
	local width = window.width - M.pad * 2
	local under = window:Body() - M.pad * 2
	page.frame:SetSize(width, under)
	page:Resize(width, under)
	return true
end

local function Build()
	if window then
		return window
	end

	window = UI.Window({
		name = "WiggleUIInspect",
		title = "Inspect",
		-- The character sheet's own zoom, and one number for the two of them is
		-- the honest answer rather than a saving: this is that sheet drawn for
		-- somebody else, the two are read side by side, and a player who wants
		-- one of them larger wants both. Character/RepWindow.lua shares it for
		-- the same reason.
		zoom = function() return ns.Zoom("characterZoom") end,
		rescale = function(apply)
			apply()
			Window.Fit()
			Window.Refresh()
		end,
	})
	ns.Remember(window)

	page = ns.Paperdoll.New(window.content, {
		inspect = true,
		-- Asked on every repaint rather than handed over once, because the
		-- window is pointed at a second person without being rebuilt.
		unit = function() return ns.Inspect.Unit() end,
	})
	page.frame:SetPoint("TOPLEFT", M.pad, -M.pad)
	page.frame:Show()

	footer = UI.Label(window.footer, M.small, C.dim, "LEFT", UI.FLAT)
	UI.Wrap(footer, false)
	footer:SetPoint("LEFT")

	-- Painted and slid in whenever it comes up, by whatever route, which is the
	-- same pair the sheet hangs off its own OnShow and for the same reason: the
	-- page is what moves, and the window over it is what comes and goes.
	--
	-- Hooked and not set, both of them. UI/Window.lua puts its own scripts on
	-- both edges of every window it builds, the wash on the show and the
	-- dropdown and key capture cleanup on the hide, and a SetScript here would
	-- take one of those off without anything saying so.
	window.frame:HookScript("OnShow", function()
		Window.Paint()
		page:Arrive()
	end)

	-- And the inspect handed back whenever it goes down, by whatever route.
	--
	-- There are four: the cross on the title bar, the Escape key through
	-- UISpecialFrames, the slash word, and the subject walking away. Only the
	-- last two are this file's code, and the first two call Hide on the frame
	-- without going anywhere near it, so the one place that sees all four is
	-- the frame's own script. A window shut with the inspect still held would
	-- leave the client answering the talent calls about somebody nobody is
	-- looking at, which is what Unit/Spec.lua's icons then read.
	window.frame:HookScript("OnHide", function()
		ns.Inspect.Drop()
	end)

	Window.Fit()
	return window
end

--------------------------------------------------------------------------

-- The page, the title and the line along the bottom.
--
-- The title carries the name because this window is about a person and the
-- page's own head can be off the bottom of a short screen. It is the one window
-- in the addon whose title moves, and it moves for the same reason the mail
-- window's does not: there is one mail box and there is a different person
-- every time you open this.
function Window.Paint()
	if not window or not window:IsShown() then
		return false
	end
	local who = ns.Inspect.Name()
	window:Retitle(who and ("Inspecting %s"):format(who) or "Inspect")
	page:Paint()
	if ns.Inspect.Waiting() then
		footer:SetText("Waiting for the server to answer.")
	else
		footer:SetText(ns.Inspect.Describe() .. ".")
	end
	return true
end

function Window.Built()
	return window ~= nil
end

function Window.Shown()
	return window ~= nil and window:IsShown()
end

-- The pane, handed out rather than answered about, for the reason the sheet
-- hands its page over: what is worth checking is how many rows came out and
-- which of them drew a mark, and neither is a boolean this file could compute
-- without computing it the same way twice.
function Window.Pane()
	return page
end

-- Open on whoever Character/Inspect.lua has picked.
--
-- Told rather than asking, because picking somebody and showing their sheet are
-- one gesture and that file owns the first half. The page is told to look again
-- rather than merely repainted: a different person is twenty links changed at
-- once, and the page has to forget the last one's before it compares.
function Window.Open()
	Build()
	page:Look()
	if not window:IsShown() then
		window:Show()
	else
		Window.Paint()
	end
	return true
end

function Window.Hide()
	if not window then
		return false
	end
	window:Hide()
	return true
end

-- The slash word's way out. The inspect goes back to the client on the way
-- down, on the frame's own OnHide above, because the cross and the Escape key
-- never come through here.
function Window.Close()
	if not Window.Shown() then
		return false
	end
	return Window.Hide()
end

function Window.Toggle()
	if Window.Shown() then
		return Window.Close()
	end
	if not ns.Inspect.Unit() then
		return false
	end
	return Window.Open()
end

-- The server answered about the person this window is showing. The page reads
-- the client's own tables rather than anything the event carries, so there is
-- nothing to hand on: the repaint is the whole of it.
function Window.Arrived()
	return Window.Refresh()
end

function Window.Refresh()
	if Window.Shown() then
		return Window.Paint()
	end
	return false
end

function Window.Describe()
	if not ns.db.inspect then
		return "off"
	end
	if not window then
		return "not built yet"
	end
	if not Window.Shown() then
		return "closed"
	end
	return ("open on %s"):format(ns.Inspect.Name() or "nobody")
end
