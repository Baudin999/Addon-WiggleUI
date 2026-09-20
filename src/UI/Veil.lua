local ADDON, ns = ...

local UI = ns.UI

--------------------------------------------------------------------------
-- A frame the screen can take away, and a frame the mouse brings back
--
-- Two capabilities, and the theme is the first caller of both. A theme says a
-- frame is down, or drawn at a fifth of itself, or down until the pointer is on
-- it, and the part that built the frame keeps every Show, Hide and SetAlpha of
-- its own. Those two wants collide on one frame: a theme that set the frame's
-- alpha would be undone by the first part that fades its own frame out of
-- combat, and a theme that hid it would be undone by the first Show.
--
-- So the frame is handed a parent of its own, the veil, and the theme writes to
-- the veil. The client multiplies a frame's alpha by its parent's and draws
-- nothing under a hidden parent whatever the child says, so the part's writes
-- and the theme's never touch the same field. The part does not know the veil
-- is there.
--
-- The reparent is the only write to the frame, and it is made once. Strata and
-- level are read first and put back after, because SetParent reseats a frame's
-- level under its new parent and a part that raised its frame over another
-- would find it under it. The veil takes the old parent's place and its size,
-- so the frame's scale and its anchors mean what they meant.
--
-- A protected frame cannot change parent in a fight, so UI.Veil answers nil
-- there and the caller owes the pass. This layer does not know the name of
-- Core's lockdown queue, for the reason UI.Placeable does not know a setting's.
--------------------------------------------------------------------------

-- How often a revealed frame asks whether the pointer is still on it. Only
-- while it is revealed: the catcher has let go of the mouse by then, so the
-- rectangle is the one thing left to ask. A frame at rest runs nothing.
local RECHECK = 0.2

function UI.Veiled(frame)
	return frame.wuiVeil
end

-- The frame's veil, made on the first call and handed back on every one after.
-- Nil while a fight refuses the reparent.
function UI.Veil(frame)
	if frame.wuiVeil then
		return frame.wuiVeil
	end
	if frame:IsProtected() and InCombatLockdown() then
		return nil
	end
	local parent = frame:GetParent() or UIParent
	local strata, level = frame:GetFrameStrata(), frame:GetFrameLevel()

	local veil = CreateFrame("Frame", nil, parent)
	veil:SetAllPoints(parent)
	veil:SetFrameStrata(strata)
	veil:SetFrameLevel(math.max(0, level - 1))

	frame:SetParent(veil)
	frame:SetFrameStrata(strata)
	frame:SetFrameLevel(level)
	frame.wuiVeil = veil
	return veil
end

--------------------------------------------------------------------------
-- The reveal
--
-- The veil rests at `rest` and goes to full while the pointer is over the frame.
-- The pointer is found by a catcher, a child of the frame the size of it that
-- takes the hover and passes every click through (UI.HoverOnly).
--
-- While the frame rests the catcher sits over every one of the frame's own
-- children. Under them it was the one frame the pointer could not reach on a
-- window its children fill: the chat window is its rail, its lines and its
-- entry edge to edge, and in the exploration theme it never came up. Nothing
-- under it is visible at rest, so nothing is lost by covering it.
--
-- Once the frame is up the catcher is hidden, so the buttons, links and
-- scrolling under it answer as drawn, and the recheck asks the rectangle
-- whether the pointer is still inside. Hidden rather than told to let go of
-- the mouse: with its motion and clicks both off it still took the press on
-- the chat window's rooms on the live client. The recheck runs on the veil for
-- that reason, because a hidden frame runs no OnUpdate. It stops itself the
-- moment the answer is no and the catcher is shown again. SetAlpha, Show and
-- Hide on an insecure child are not protected writes, so this answers in a
-- fight on a secure bar the same as out of one.
--------------------------------------------------------------------------

-- The highest level among a frame's descendants, which is where the catcher
-- has to sit to be the frame the pointer finds. Walked on every rest rather
-- than once, because a part builds children after it hands the frame over:
-- the chat window builds its rail and its entry after Theme.Wear.
local function Top(top, ...)
	for index = 1, select("#", ...) do
		local child = select(index, ...)
		-- The catcher is a child too, and counting it would lift it a level
		-- on every rest.
		if not child.wuiRevealFrame then
			top = Top(math.max(top, child:GetFrameLevel()), child:GetChildren())
		end
	end
	return top
end

local function Rest(catcher)
	local veil, rest = catcher.wuiRevealVeil, catcher.wuiRevealRest
	if veil:GetAlpha() ~= rest then
		veil:SetAlpha(rest)
	end
	if catcher.wuiRevealTick then
		catcher.wuiRevealTick:Stop()
	end
	local frame = catcher.wuiRevealFrame
	local level = Top(frame:GetFrameLevel(), frame:GetChildren()) + 1
	if catcher:GetFrameLevel() ~= level then
		catcher:SetFrameLevel(level)
	end
	if not catcher:IsShown() then
		catcher:Show()
	end
end

local function Recheck(_, veil)
	local catcher = veil.wuiRevealCatcher
	if catcher.wuiRevealFrame:IsVisible() and catcher.wuiRevealFrame:IsMouseOver() then
		return
	end
	Rest(catcher)
end

local function Enter(catcher)
	catcher.wuiRevealVeil:SetAlpha(1)
	catcher:Hide()
	if catcher.wuiRevealTick then
		catcher.wuiRevealTick:Start()
	else
		catcher.wuiRevealTick = UI.Ticker(catcher.wuiRevealVeil, RECHECK, "reveal", Recheck)
	end
end

-- The frame must already be veiled. Answers the catcher, so a caller that
-- lifts the reveal for a while (a frame being placed) can take it away with
-- UI.Unreveal.
function UI.Reveal(frame, rest)
	local veil = assert(frame.wuiVeil, "UI.Reveal wants a frame UI.Veil has taken")
	local catcher = frame.wuiReveal
	if not catcher then
		catcher = CreateFrame("Frame", nil, frame)
		catcher:SetAllPoints(frame)
		UI.HoverOnly(catcher)
		catcher:SetScript("OnEnter", Enter)
		catcher.wuiRevealFrame = frame
		catcher.wuiRevealVeil = veil
		veil.wuiRevealCatcher = catcher
		frame.wuiReveal = catcher
	end
	catcher.wuiRevealRest = rest
	Rest(catcher)
	return catcher
end

-- The reveal lifted: the recheck stopped and the catcher gone, so a frame
-- being placed is not put back down by a pointer that wandered off it.
function UI.Unreveal(frame)
	local catcher = frame.wuiReveal
	if not catcher then
		return
	end
	if catcher.wuiRevealTick then
		catcher.wuiRevealTick:Stop()
	end
	catcher:Hide()
end
