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

-- The unit table reaches the bars. The swing timer and every unit backdrop
-- held colours no palette could reach, so each is read here through the table
-- its part took at file scope, a palette is painted, and the same table has to
-- have moved. The rested pool is the accent and is shaped after the paint, so
-- it is held to the ceiling and to having moved. The cast bar and the
-- experience rail are the same on every palette and must not move at all.
local Color = ns.Unit.Color
local held = {
	backdrop  = Color.backdrop,
	seam      = Color.seam,
	iron      = Color.frame.idle,
	swingMain = Color.swing.main,
	swingOff  = Color.swing.off,
}
for key in pairs(ns.Palettes.dark.unit) do
	check(held[key], ("the palette's unit colour %s is not read by any bar this section knows"):format(key))
end

local function Copy(color)
	return { color[1], color[2], color[3] }
end

local function Same(a, b)
	return math.abs(a[1] - b[1]) < 1e-9 and math.abs(a[2] - b[2]) < 1e-9
		and math.abs(a[3] - b[3]) < 1e-9
end

local rested = Color.progress.rested
local fixed = { cast = Color.cast.open, experience = Color.progress.experience }
local before = { rested = Copy(rested) }
for key, color in pairs(fixed) do
	before[key] = Copy(color)
end

local function Painted(name)
	Color.Paint(ns.Palettes[name])
	for key, color in pairs(ns.Palettes[name].unit) do
		local drawn = held[key]
		check(drawn ~= color, ("Unit.Color's %s is %s's own table"):format(key, name))
		for index = 1, 4 do
			check(drawn[index] == color[index],
				("%s's %s[%d] reads %s and the palette says %s")
					:format(name, key, index, tostring(drawn[index]), tostring(color[index])))
		end
	end
	check(Color.Luma(rested) <= Color.fillCeiling + 1e-9,
		("%s's rested pool is over the fill ceiling after the paint"):format(name))
	for key, color in pairs(fixed) do
		check(Same(color, before[key]), ("painting %s moved the %s colour"):format(name, key))
	end
end

Painted("forest")
check(not Same(rested, before.rested), "painting forest left the rested pool on dark's accent")
Painted("dark")
check(Same(rested, before.rested), "painting dark back did not put the rested pool back")

for _, element in ipairs(ns.Themes.ELEMENTS) do
	check(ns.Theme.Mode(element.key) == "show",
		("informational does not leave %s as drawn"):format(element.label))
end
