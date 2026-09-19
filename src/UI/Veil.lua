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
-- while it is revealed and the pointer has left the catcher for one of the
-- frame's own children, which is the one case the catcher's own OnLeave cannot
-- answer. A frame nobody is pointing at runs nothing.
local RECHECK = 0.2

function UI.Veiled(frame)
	return frame.wkVeil
end

-- The frame's veil, made on the first call and handed back on every one after.
-- Nil while a fight refuses the reparent.
function UI.Veil(frame)
	if frame.wkVeil then
		return frame.wkVeil
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
	frame.wkVeil = veil
	return veil
end

--------------------------------------------------------------------------
-- The reveal
--
-- The veil rests at `rest` and goes to full while the pointer is over the frame.
-- The pointer is found by a catcher, a child of the frame the size of it that
-- takes the hover and passes every click through (UI.HoverOnly), sitting at the
-- frame's own level so the frame's buttons are above it and keep their tooltips.
--
-- Moving from the catcher onto one of those buttons fires the catcher's OnLeave
-- with the pointer still inside the frame. That is the case the recheck is for:
-- it asks the rectangle rather than the catcher, and stops itself the moment
-- the answer is no. SetAlpha is not a protected write, so this answers in a
-- fight on a secure bar the same as out of one.
--------------------------------------------------------------------------

local function Rest(catcher)
	local veil, rest = catcher.wkRevealVeil, catcher.wkRevealRest
	if veil:GetAlpha() ~= rest then
		veil:SetAlpha(rest)
	end
	if catcher.wkRevealTick then
		catcher.wkRevealTick:Stop()
	end
end

local function Recheck(_, catcher)
	if catcher.wkRevealFrame:IsVisible() and catcher.wkRevealFrame:IsMouseOver() then
		return
	end
	Rest(catcher)
end

local function Enter(catcher)
	catcher.wkRevealVeil:SetAlpha(1)
end

local function Leave(catcher)
	if not catcher.wkRevealFrame:IsMouseOver() then
		Rest(catcher)
		return
	end
	if catcher.wkRevealTick then
		catcher.wkRevealTick:Start()
	else
		catcher.wkRevealTick = UI.Ticker(catcher, RECHECK, "reveal", Recheck)
	end
end

-- The frame must already be veiled. Answers the catcher, so a caller that
-- lifts the reveal for a while (a frame being placed) can hide it.
function UI.Reveal(frame, rest)
	local veil = assert(frame.wkVeil, "UI.Reveal wants a frame UI.Veil has taken")
	local catcher = frame.wkReveal
	if not catcher then
		catcher = CreateFrame("Frame", nil, frame)
		catcher:SetAllPoints(frame)
		catcher:SetFrameLevel(frame:GetFrameLevel())
		UI.HoverOnly(catcher)
		catcher:SetScript("OnEnter", Enter)
		catcher:SetScript("OnLeave", Leave)
		catcher.wkRevealFrame = frame
		catcher.wkRevealVeil = veil
		frame.wkReveal = catcher
	end
	catcher.wkRevealRest = rest
	catcher:Show()
	Rest(catcher)
	return catcher
end
