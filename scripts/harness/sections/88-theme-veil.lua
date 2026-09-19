-- The veil, the reveal and the palette
--
-- Three things a theme stands on, and each fails silently on the screen.
--
-- The veil takes a frame's parent, and a frame that comes out of that at a
-- different level is a unit frame drawn under the one it was raised over. So
-- the level and the strata are read either side of the reparent.
--
-- The reveal has to be the frame the pointer finds. A catcher under the
-- frame's own children was, on a window they fill edge to edge, a frame the
-- pointer never reached: the chat window stayed down in the exploration theme
-- however long you held the mouse on it. So at rest the catcher has to be what
-- the client says is under the pointer, even on a child built after the
-- reveal. Once the frame is up it has to let go, or every button and link on
-- the frame is behind it; the recheck then keeps the frame up with the pointer
-- on a child and puts it down, and stops, once the pointer is off.

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

-- Built after the reveal and raised over everything, the way the chat window
-- builds its rail and entry after Theme.Wear.
local late = CreateFrame("Button", nil, frame)
late:SetSize(20, 20)
late:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
late:SetFrameLevel(40)
late:EnableMouse(true)

over(frame)
check(mouse.At(mouse.Point(child)) == catcher,
	"at rest the pointer on a child finds the child, so the frame never comes up")

mouse.Deliver(catcher, "OnEnter")
check(veil:GetAlpha() == 1, "the pointer on the frame did not bring it up")
check(mouse.At(mouse.Point(child)) == child,
	"the frame came up and the catcher still covers its buttons")
check(not catcher:IsShown(),
	"the frame came up and the catcher is still there to take a press")

local tick = UI.Ticking("reveal", veil)
check(tick ~= nil, "the frame came up without arming the recheck")
if tick then
	over(child)
	tick:Beat(1)
	check(veil:GetAlpha() == 1, "the frame went down with the pointer on one of its own buttons")

	mouse.Place(mouse.Point(frame, -400, 400))
	tick:Beat(1)
	check(veil:GetAlpha() == 0, "the pointer off the frame did not put it back down")
	check(not tick:Running(), "the recheck kept running with nothing revealed")
end
check(mouse.At(mouse.Point(late)) == catcher,
	"back at rest the catcher is under a child built after the reveal")
local lateX, lateY = mouse.Point(late)
check(mouse.At(lateX, lateY, "LeftButton") == late,
	"the catcher at rest takes the click instead of passing it through")

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

-- The unit table reaches the bars. The cast bar, the experience rail, the
-- swing timer and every unit backdrop held colours no palette could reach, so
-- each is read here through the table its part took at file scope, a palette
-- is painted, and the same table has to have moved. The cast bar and the
-- experience rail share one table, and it and the rested pool, which is the
-- accent, are shaped after the paint, so both are held to the ceiling and to
-- having moved rather than to the palette's numbers.
local Color = ns.Unit.Color
local held = {
	backdrop  = Color.backdrop,
	seam      = Color.seam,
	iron      = Color.frame.idle,
	swingMain = Color.swing.main,
	swingOff  = Color.swing.off,
	bar       = Color.cast.open,
}
local shapedKeys = { bar = true }
check(Color.cast.open == Color.progress.experience,
	"the cast bar and the experience rail are not one colour")
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
local before = { rested = Copy(rested), bar = Copy(held.bar) }

local function Painted(name)
	Color.Paint(ns.Palettes[name])
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
	check(Color.Luma(rested) <= Color.fillCeiling + 1e-9,
		("%s's rested pool is over the fill ceiling after the paint"):format(name))
end

Painted("forest")
check(not Same(rested, before.rested), "painting forest left the rested pool on dark's accent")
check(not Same(held.bar, before.bar), "painting forest left the cast bar and experience rail on dark's")
Painted("dark")
check(Same(rested, before.rested), "painting dark back did not put the rested pool back")
check(Same(held.bar, before.bar), "painting dark back did not put the cast bar and experience rail back")

for _, element in ipairs(ns.Themes.ELEMENTS) do
	check(ns.Theme.Mode(element.key) == "show",
		("informational does not leave %s as drawn"):format(element.label))
end
