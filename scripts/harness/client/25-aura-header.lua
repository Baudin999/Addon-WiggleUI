local H = ...

local own = H.own

--------------------------------------------------------------------------
-- SecureAuraHeaderTemplate
--
-- The client's secure aura header, as Blizzard_RestrictedAddOnEnvironment's
-- SecureGroupHeaders.lua writes it on the classic_anniversary branch, cut to
-- the attributes UI.Press.Cancels sets: one filter, the client's own index
-- order, a cap, the two weapon enchants at the head of the list, and the grid
-- the children are laid out in. Everything the addon's buttons do on a click
-- comes from the attributes this writes on them, and 14-secure.lua's
-- cancelaura reads them back, so a button that cancels the wrong buff fails
-- a section here the way it would in the game.
--
-- Hidden and deaf while hidden, like the template, and updated from the same
-- three doors: OnShow, UNIT_AURA on the player, and an attribute write while
-- shown. A child it was handed is used before one is built, which is the
-- whole of why UI.Press.Cancels builds them.
--
-- Shown is the header's own flag here where the client asks IsVisible. The
-- client fires OnShow on a header whose parent comes back, and this stub does
-- not carry visibility down a tree, so a header re-laid under a hidden block
-- would stay unlaid for the rest of the run. Asking the flag lands on the
-- state the client reaches once the block is back.
--
-- The weapon enchants are read off the stub's own fields rather than out of
-- GetWeaponEnchantInfo, because the client reads that call positionally and
-- 03-player.lua answers it in two shapes on purpose.
--------------------------------------------------------------------------

-- GetInventorySlotInfo("MainHandSlot") and ("SecondaryHandSlot").
local HANDS = { 16, 17 }

local function Update(header)
	if not header:IsShown() then
		return
	end
	local filter = header:GetAttribute("filter")
	local cap = tonumber(header:GetAttribute("maxAuraCount"))
	local buttons = {}
	local index = 1
	while (not cap or index <= cap) and _G.UnitAura("player", index, filter) do
		local button = header:GetAttribute("child" .. index)
		if not button then
			button = _G.CreateFrame("Button", nil, header, header:GetAttribute("template"))
			header.raw(header, "child" .. index, button)
		end
		button:ClearAllPoints()
		button:SetID(index)
		button:SetAttribute("index", index)
		button:SetAttribute("filter", filter)
		buttons[#buttons + 1] = button
		index = index + 1
	end
	local dead = header:GetAttribute("child" .. index)
	while dead do
		dead:Hide()
		index = index + 1
		dead = header:GetAttribute("child" .. index)
	end

	if tonumber(header:GetAttribute("includeWeapons")) == 1 then
		local has = { own.main, own.off }
		for hand = 2, 1, -1 do
			local enchant = header:GetAttribute("tempEnchant" .. hand)
			if enchant and has[hand] then
				enchant:ClearAllPoints()
				enchant:SetAttribute("target-slot", HANDS[hand])
				enchant:SetID(HANDS[hand])
				table.insert(buttons, 1, enchant)
			elseif enchant then
				enchant:Hide()
			end
		end
	end

	local point = header:GetAttribute("point") or "TOPRIGHT"
	local xOffset = tonumber(header:GetAttribute("xOffset")) or 0
	local yOffset = tonumber(header:GetAttribute("yOffset")) or 0
	local wrapX = tonumber(header:GetAttribute("wrapXOffset")) or 0
	local wrapY = tonumber(header:GetAttribute("wrapYOffset")) or 0
	local wrapAfter = tonumber(header:GetAttribute("wrapAfter"))
	if wrapAfter == 0 then
		wrapAfter = nil
	end
	-- Laid out, and then the header sized to what it laid out, which is the
	-- client's last step: the span of its buttons, or minWidth and minHeight
	-- when that is smaller or there are none.
	local minWidth = tonumber(header:GetAttribute("minWidth")) or 0
	local minHeight = tonumber(header:GetAttribute("minHeight")) or 0
	local left, right, top, bottom = math.huge, -math.huge, -math.huge, math.huge
	for at = 1, #buttons do
		local per = wrapAfter or at
		local tick, cycle = (at - 1) % per, math.floor((at - 1) / per)
		local button = buttons[at]
		button:SetPoint(point, header, cycle * wrapX + tick * xOffset,
			cycle * wrapY + tick * yOffset)
		button:Show()
		left = math.min(left, button:GetLeft() or math.huge)
		right = math.max(right, button:GetRight() or -math.huge)
		top = math.max(top, button:GetTop() or -math.huge)
		bottom = math.min(bottom, button:GetBottom() or math.huge)
	end
	if #buttons >= 1 then
		header:SetWidth(math.max(right - left, minWidth))
		header:SetHeight(math.max(top - bottom, minHeight))
	else
		header:SetWidth(minWidth)
		header:SetHeight(minHeight)
	end
end

local function Header(header)
	header.shown = false
	header.scripts.OnShow = function(self)
		self:RegisterUnitEvent("UNIT_AURA", "player")
		Update(self)
	end
	header.scripts.OnEvent = function(self, event, unit)
		if event == "UNIT_AURA" and unit == "player" then
			Update(self)
		end
	end
	local write = header.SetAttribute
	header.raw = write
	header.SetAttribute = function(self, name, value)
		write(self, name, value)
		if self:IsShown() then
			Update(self)
		end
	end
end

local made = _G.CreateFrame
_G.CreateFrame = function(kind, name, parent, template)
	local frame = made(kind, name, parent, template)
	if template == "SecureAuraHeaderTemplate" then
		Header(frame)
	end
	return frame
end
