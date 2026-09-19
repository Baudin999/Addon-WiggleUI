-- The veil, the reveal and the palette
--
-- Three things a theme stands on, and each fails silently on the screen.
--
-- The veil takes a frame's parent, and a frame that comes out of that at a
-- different level is a unit frame drawn under the one it was raised over. So
-- the level and the strata are read either side of the reparent.
--
-- The reveal has one case the catcher cannot answer on its own: the pointer
-- leaving the catcher for one of the frame's own buttons, which fires OnLeave
-- with the pointer still inside the frame. A reveal that faded there would be a
-- bar that vanished the moment you reached for a square on it. So the pointer
-- is put on a child, the recheck is run, and the frame has to still be up; then
-- the pointer goes off the frame and the recheck has to put it down and stop.
--
-- The palette is copied into UI.Color's tables at load. Dark is the default,
-- so every palette colour has to read dark's numbers here, and each has to be
-- the table UI.Color held before the load, which is the table a part took.

local H = ...
local ns, check = H.ns, H.check
local UI = ns.UI
local mouse = H.mouse

--------------------------------------------------------------------------
-- The veil
--------------------------------------------------------------------------

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetSize(100, 40)
frame:SetPoint("CENTER", UIParent, "CENTER")
frame:SetFrameStrata("HIGH")
frame:SetFrameLevel(7)
local child = CreateFrame("Button", nil, frame)
child:SetSize(20, 20)
child:SetPoint("LEFT", frame, "LEFT", 10, 0)
child:EnableMouse(true)

local veil = UI.Veil(frame)
check(veil ~= nil, "the veil refused a frame that is not protected, out of combat")
check(frame:GetParent() == veil, "the veiled frame is not under its veil")
check(veil:GetParent() == UIParent, "the veil did not take the frame's old parent")
check(frame:GetFrameStrata() == "HIGH", "the veil moved the frame off its strata")
check(frame:GetFrameLevel() == 7,
	("the veil moved the frame from level 7 to %d"):format(frame:GetFrameLevel()))
check(UI.Veil(frame) == veil, "a second call made a second veil")

--------------------------------------------------------------------------
-- The reveal
--------------------------------------------------------------------------

local catcher = UI.Reveal(frame, 0)
check(veil:GetAlpha() == 0, "a revealed frame does not rest at the alpha it was given")

local function over(target)
	local x, y = mouse.Point(target)
	mouse.Place(x, y)
end

over(frame)
mouse.Deliver(catcher, "OnEnter")
check(veil:GetAlpha() == 1, "the pointer on the frame did not bring it up")

over(child)
mouse.Deliver(catcher, "OnLeave")
local tick = UI.Ticking("reveal", catcher)
check(tick ~= nil, "the pointer onto a child did not arm the recheck")
if tick then
	tick:Beat(1)
	check(veil:GetAlpha() == 1, "the frame went down with the pointer on one of its own buttons")

	mouse.Place(mouse.Point(frame, -400, 400))
	tick:Beat(1)
	check(veil:GetAlpha() == 0, "the pointer off the frame did not put it back down")
	check(not tick:Running(), "the recheck kept running with nothing revealed")
end

frame:Hide()

--------------------------------------------------------------------------
-- The palette
--------------------------------------------------------------------------

check(ns.db.palette == "dark", "the harness loaded with a palette other than dark")
for key, color in pairs(ns.Palettes.dark) do
	if key ~= "unit" then
		local drawn = UI.Color[key]
		check(drawn ~= color, ("UI.Color.%s is dark's own table, so painting it would lose dark"):format(key))
		for index = 1, 4 do
			check(drawn[index] == color[index],
				("UI.Color.%s[%d] reads %s and dark says %s")
					:format(key, index, tostring(drawn[index]), tostring(color[index])))
		end
	end
end

-- The unit table reaches the bars. The cast bar, the experience rail and the
-- swing timer each held a colour no palette could reach, so each is read here
-- through the table its part took at file scope, a palette is painted, and the
-- same table has to have moved. The fills are shaped after the paint, so a
-- fill is held to the ceiling rather than to the palette's numbers; the swing
-- bars carry no text and are not shaped, so they are held to the numbers.
local Color = ns.Unit.Color
local held = {
	backdrop   = Color.backdrop,
	seam       = Color.seam,
	iron       = Color.frame.idle,
	cast       = Color.cast.open,
	experience = Color.progress.experience,
	rested     = Color.progress.rested,
	swingMain  = Color.swing.main,
	swingOff   = Color.swing.off,
}
local shapedKeys = { cast = true, experience = true, rested = true }
for key in pairs(ns.Palettes.dark.unit) do
	check(held[key], ("the palette's unit colour %s is not read by any bar this section knows"):format(key))
end

local function Painted(name)
	Color.Paint(ns.Palettes[name].unit)
	for key, color in pairs(ns.Palettes[name].unit) do
		local drawn = held[key]
		check(drawn ~= color, ("Unit.Color's %s is %s's own table"):format(key, name))
		if shapedKeys[key] then
			check(Color.Luma(drawn) <= Color.fillCeiling + 1e-9,
				("%s's %s is over the fill ceiling after the paint"):format(name, key))
		else
			for index = 1, 4 do
				check(drawn[index] == color[index],
					("%s's %s[%d] reads %s and the palette says %s")
						:format(name, key, index, tostring(drawn[index]), tostring(color[index])))
			end
		end
	end
end

Painted("forest")
Painted("dark")

for _, element in ipairs(ns.Themes.ELEMENTS) do
	check(ns.Theme.Mode(element.key) == "show",
		("informational does not leave %s as drawn"):format(element.label))
end
