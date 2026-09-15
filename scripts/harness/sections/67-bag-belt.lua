-- The bags you wear
--
-- Four squares along the foot of the bag window, and four claims about them.
-- They sit under the piles and not over them. A square draws the bag worn in
-- its slot and how many slots it holds. A press or a drop with an item in hand
-- gives it to that bag's slot, not to the first bag with room, which is what
-- the window's own drop does and is the difference worth catching. And a press
-- or a drag with nothing in hand picks that bag up.
--
-- PutItemInBag and ContainerIDToInventoryID are the stubs 66-bag-drop.lua
-- already drives. PickupBagFromSlot has none, so it is stood up here, counted
-- rather than performed, and taken down at the foot.

local H = ...
local ns, check = H.ns, H.check
local CARRIED, refill, refillQuests = H.CARRIED, H.refill, H.refillQuests
local worn, itemLink = H.worn, H.itemLink

local Window, Belt, Grid = ns.BagsWindow, ns.BagsBelt, ns.BagsGrid

----------------------------------------------------------------------
-- The scene: three full bags and a fourth with three empty slots, the
-- one 66-bag-drop.lua starts from, and something worn in the first bag
-- slot. Nothing here reads what kind of item it is.
----------------------------------------------------------------------

refill()
refillQuests()
CARRIED[3] = { false, false, false }

local lifted = {}
_G.PickupBagFromSlot = function(id)
	lifted[#lifted + 1] = id
end

local firstSlot = _G.ContainerIDToInventoryID(1)
worn[firstSlot] = itemLink("Lionheart Helm")

Window.Show()
Window.Refresh()

local squares = Belt.Squares()
for bag = 1, 4 do
	check(squares[bag] ~= nil and squares[bag]:IsShown(),
		("the belt has no square for bag %d"):format(bag))
end

-- Under the piles. Every grid square that is up ends above the belt's top edge.
local top = squares[1]:GetTop()
for _, square in ipairs(Grid.Squares()) do
	if square:IsShown() then
		check(square:GetBottom() >= top,
			("bag square %d hangs over the belt"):format(square.index))
	end
end

check(squares[1].art:IsShown(), "the worn bag's square draws no picture")
check(squares[1].tally:GetText() == tostring(#CARRIED[1]),
	("the first bag holds %d slots and its square says %s")
		:format(#CARRIED[1], tostring(squares[1].tally:GetText())))
check(not squares[2].art:IsShown(), "an empty bag slot draws a picture")

-- An item in hand pressed onto the fourth square. A hole in the first bag is
-- where the window's own drop would put it, so landing there is the wrong aim.
CARRIED[1][2] = false
local carried = CARRIED[0][1]
_G.PickupContainerItem(0, 1)
H.mouse.On(squares[3])
check(_G.GetCursorInfo() == nil, "a press on a bag square left the item in hand")
check(CARRIED[3][1] == carried,
	("the press landed in the wrong bag: the fourth holds %s"):format(tostring(CARRIED[3][1])))
check(CARRIED[1][2] == false, "the press went to the first bag with room, not the bag it was aimed at")

-- The same through a drop.
carried = CARRIED[0][2]
_G.PickupContainerItem(0, 2)
H.mouse.Give(squares[3])
check(CARRIED[3][2] == carried, "a drop on a bag square did not land in that bag")

-- Nothing in hand: a press lifts the bag, and so does a drag.
H.mouse.On(squares[2])
check(lifted[1] == _G.ContainerIDToInventoryID(2),
	("a press on the second square lifted slot %s"):format(tostring(lifted[1])))
local took, dragging = H.mouse.Grab(H.mouse.Point(squares[4]))
H.mouse.Drop()
check(took == squares[4] and dragging, "a drag on the fourth square did not start")
check(lifted[2] == _G.ContainerIDToInventoryID(4),
	("a drag on the fourth square lifted slot %s"):format(tostring(lifted[2])))

print("belt   four squares under the piles; an item pressed and dropped lands in the bag aimed at; a press and a drag lift the bag")

Window.Hide()
_G.ClearCursor()
_G.PickupBagFromSlot = nil
worn[firstSlot] = nil
CARRIED[3] = nil
refill()
