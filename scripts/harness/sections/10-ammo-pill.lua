-- The ammo pill on your own block
--
-- The shots left in the ranged slot, drawn in the portrait's bottom corner.
-- What is asserted is the rule ns.Ammo carries and the pill that draws it: a
-- bow and a gun count the ammo slot, a thrown weapon that stacks counts
-- itself, and a thrown weapon with durability, a wand and an empty slot draw
-- no pill at all. Under a hundred the number is red, and a bow with nothing in
-- the ammo slot is a red zero rather than no pill.
--
-- What this cannot prove is that the client files a bow under subclass 2 and
-- hands no link for the ammo slot. Both are read off Narcissus and TitanAmmo
-- on this client, and the fixture answers what they read.

local H = ...
local ns, check, fire = H.ns, H.check, H.fire
local ITEMS, itemLink, worn, shots = H.ITEMS, H.itemLink, H.worn, H.shots

local RANGED = 18
local SHORT, PLENTY = ns.Unit.Color.text.short, ns.Unit.Color.text.value

-- The arrow is the merchant's fixture, which is already in the item table and
-- stays there. These five are this section's and come out again at the foot.
local FIXTURES = {
	["Worn Longbow"] = { id = 9101, classId = 2, subClassId = 2, equip = "INVTYPE_RANGED" },
	["Rusted Gun"] = { id = 9102, classId = 2, subClassId = 3, equip = "INVTYPE_RANGEDRIGHT" },
	["Balanced Throwing Axe"] = { id = 9104, classId = 2, subClassId = 16, equip = "INVTYPE_THROWN" },
	["Keen Throwing Knife"] = { id = 9105, classId = 2, subClassId = 16, equip = "INVTYPE_THROWN", stack = 200 },
	["Ember Wand"] = { id = 9106, classId = 2, subClassId = 19, equip = "INVTYPE_RANGEDRIGHT" },
}
for name, item in pairs(FIXTURES) do
	check(ITEMS[name] == nil, name .. " is already an item fixture and this section would overwrite it")
	ITEMS[name] = item
end

local player, target = ns.FrameSkin.Entry("player"), ns.FrameSkin.Entry("target")
local skinPass = H.tick("skin")

-- What the client says when the ranged or ammo slot changes, then the pass
-- that draws it.
local function wear(weapon, ammo, ammoCount, stack)
	worn[RANGED] = weapon and itemLink(weapon) or nil
	shots.ammo, shots.ammoCount, shots.ranged = ammo, ammoCount or 0, stack or 1
	fire("UNIT_INVENTORY_CHANGED", "player")
	skinPass:Beat(0.25)
end

local pill = player and player.ammo
check(pill ~= nil, "your own block carries no ammo pill")
check(target == nil or target.ammo == nil, "the target block carries an ammo pill, and the count is yours")

if pill then
	local function reads(text, tint, what)
		check(pill:IsShown(), what .. ": no pill")
		check(pill.text:GetText() == text,
			("%s: the pill says %s and should say %s"):format(what, tostring(pill.text:GetText()), text))
		local r, g, b = pill.text:GetTextColor()
		check(r == tint[1] and g == tint[2] and b == tint[3],
			what .. ": the number is the wrong colour")
	end

	check(not pill:IsShown(), "the pill is up with nothing in the ranged slot")

	wear("Worn Longbow")
	reads("0", SHORT, "a bow with an empty ammo slot")

	wear("Worn Longbow", "Sharp Arrow", 1200)
	reads("1200", PLENTY, "a bow and twelve hundred arrows")

	-- A shot spends an arrow out of a bag, and the bag is what the client says
	-- moved.
	shots.ammoCount = 40
	fire("BAG_UPDATE", 3)
	skinPass:Beat(0.25)
	reads("40", SHORT, "forty arrows left")

	wear("Rusted Gun", "Sharp Arrow", 12000)
	reads("9999", PLENTY, "a gun and more shots than the pill has digits for")

	wear("Balanced Throwing Axe")
	check(not pill:IsShown(), "a thrown weapon that does not stack drew a pill, and it never runs out")

	wear("Keen Throwing Knife", nil, 0, 150)
	reads("150", PLENTY, "a stack of a hundred and fifty throwing knives")

	wear("Ember Wand")
	check(not pill:IsShown(), "a wand drew an ammo pill")

	local px = player.pixel
	for _, side in ipairs({ { "wide", pill:GetWidth() }, { "tall", pill:GetHeight() } }) do
		local pixels = side[2] / px
		local whole = math.floor(pixels + 0.5)
		check(math.abs(pixels - whole) < 1e-6 and whole > 0 and whole % 2 == 0,
			("the pill is %.4f pixels %s, not an even whole number"):format(pixels, side[1]))
	end
	local point, anchor = pill:GetPoint(1)
	check(point == "BOTTOMRIGHT" and anchor == player.portrait,
		("the pill hangs off %s of %s and belongs in the portrait's bottom corner on the gauge side")
			:format(tostring(point), tostring(anchor)))

	wear(nil)
	check(not pill:IsShown(), "the ranged slot emptied and the pill stayed up")
end

for name in pairs(FIXTURES) do
	ITEMS[name] = nil
end
