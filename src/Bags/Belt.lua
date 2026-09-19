local ADDON, ns = ...

local UI = ns.UI
local C, M = UI.Color, UI.Metric

local Belt = {}
ns.BagsBelt = Belt

--------------------------------------------------------------------------
-- The bags you wear
--
-- Four squares along the foot of the bag window, one per bag on the belt. This
-- is the one place in the addon where a bag goes on or comes off.
-- Core/BlizzHide.lua takes the client's bag bar down and Bags/Blizzard.lua
-- takes the nine calls that bar opened bags through, so before this row a new
-- bag out of a quest reward had nowhere to go but into another bag.
--
-- **The backpack has no square.** It cannot be swapped or taken off, and a
-- square that does nothing when pressed is worse than no square.
--
-- **Both calls are the client's and neither is protected.** `PutItemInBag` is
-- what a drop on one of the client's own bag buttons makes and
-- `PickupBagFromSlot` is its drag. Baganator's bag row makes the same two calls
-- from its own insecure buttons on this client, which is what says an addon
-- may. The client decides the rest: a bag in hand swaps with the one worn
-- there, an item that is not a bag goes into that bag if it fits, and a bag
-- with anything in it refuses to come off onto a square in the grid.
--
-- **A press with nothing in hand picks the bag up**, where the client's own bag
-- button would open that one bag. There is one window for all five, so opening
-- a bag is not a thing this row can mean, and a press that lifts is what the
-- gear page does with what you wear (Character/Worn.lua). Picked up, a bag goes
-- down on another square here to trade places, or on an empty square in the
-- grid to come off.
--
-- **The number on a square is the bag's size**, in the corner a stack count
-- takes. The footer already counts the free slots in the ordinary bags; the number you
-- want while choosing which bag to replace is which one is smallest.
--
-- Nothing here listens for anything. A bag going on or coming off changes the
-- size of that container, which is a BAG_UPDATE, lifting one is an
-- ITEM_LOCK_CHANGED, and Window.lua redraws on both.
--------------------------------------------------------------------------

local SLOT, GAP = UI.SLOT, UI.SLOT_GAP

-- The four on the belt, by the bag numbers Bags.lua walks. Bag nought is the
-- backpack.
local FIRST, LAST = 1, 4

local bar
local squares = {}

--------------------------------------------------------------------------
-- The presses
--------------------------------------------------------------------------

-- What the box over a square says. Nothing for an empty slot, for the reason
-- Grid.lua gives its empty squares.
local function Subject(button)
	if not button.link then
		return nil
	end
	return { kind = "item", link = button.link, title = button.name }
end

local function Enter(button)
	UI.Tint(button.bg, C.control)
	ns.Tip.Settle(button, Subject(button), "bag", nil,
		(ns.db.bagHover or 0) / 1000)
end

local function Leave(button)
	UI.Tint(button.bg, C.sunken)
	ns.Tip.Close()
end

-- Whatever is in hand onto this bag's slot. Only an item: a spell or money on
-- the cursor is nothing a bag slot takes.
local function Put(button)
	if GetCursorInfo() ~= "item" then
		return false
	end
	return ns.PutInBagSlot(ns.BagSlot(button.bag))
end

-- The bag worn here onto the cursor.
local function Lift(button)
	return ns.PickupBagSlot(ns.BagSlot(button.bag))
end

-- A click is a drop with something in hand and a lift with nothing, so a bag
-- picked up off one square goes down on the next with two clicks.
local function Press(button)
	if GetCursorInfo() == nil then
		return Lift(button)
	end
	return Put(button)
end

--------------------------------------------------------------------------
-- Building and drawing
--------------------------------------------------------------------------

-- One square. Named for the reason Grid.lua names its squares: a square that
-- has landed somewhere wrong has to be findable from a macro.
local function Build(bag)
	local button = CreateFrame("Button", "WarriorKitBagBelt" .. bag, bar)
	button.bag = bag
	button:SetSize(SLOT, SLOT)
	UI.Dress(button, SLOT)
	UI.Press.Clicks(button, "up", "LeftButton")
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnClick", Press)
	button:SetScript("OnReceiveDrag", Put)
	button:SetScript("OnDragStart", Lift)
	button:SetScript("OnEnter", Enter)
	button:SetScript("OnLeave", Leave)
	return button
end

-- On whole pixels, for the reason Snap in Grid.lua gives, and anchored only
-- when the point or the side moved.
local function Place(button, x, side)
	if button.side ~= side then
		button.side = side
		button:SetSize(side, side)
		ns.EdgeSize(button.edges, ns.Pixel(button))
	end
	if button.x == x then
		return
	end
	button.x = x
	button:ClearAllPoints()
	button:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x, 0)
end

-- What is worn in one slot, drawn: its picture, its grade on the rim, how many
-- slots it holds, and dimmed while it is on the cursor.
local function Fill(button)
	local id = ns.BagSlot(button.bag)
	local link = id and GetInventoryItemLink("player", id) or nil
	local icon, quality
	button.link, button.name = link, nil
	if link then
		button.name, icon = ns.ItemInfo(link)
		quality = ns.ItemValue(link)
	end
	UI.SlotPaint(button, icon, link and ns.ContainerSlots(button.bag) or nil,
		quality, ns.InventoryLocked(id))
end

-- The row, made once. `where` is the window's content frame, the one the
-- merchant row and the grid's scroll view are placed in.
function Belt.Attach(where)
	if bar then
		return bar
	end
	bar = CreateFrame("Frame", nil, where)
	bar:SetPoint("BOTTOMLEFT", M.pad, M.pad)
	bar:SetPoint("BOTTOMRIGHT", -M.pad, M.pad)
	bar:SetHeight(SLOT)
	for bag = FIRST, LAST do
		squares[bag] = Build(bag)
	end
	return bar
end

-- How much of the window's height the row takes: one square and the air over
-- it. Nought before the row is made.
function Belt.Height()
	if not bar then
		return 0
	end
	return SLOT + M.rowGap
end

-- Every square, off what the client says is worn right now.
function Belt.Paint()
	if not bar then
		return false
	end
	local side = UI.Round(bar, SLOT)
	for bag = FIRST, LAST do
		local button = squares[bag]
		Place(button, UI.Round(bar, (bag - FIRST) * (SLOT + GAP)), side)
		Fill(button)
	end
	return true
end

-- The four squares, for the harness, which presses them.
function Belt.Squares()
	return squares
end
