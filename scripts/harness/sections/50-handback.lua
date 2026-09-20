-- The client's bottom bar, handed back and taken again
--
-- Core/Handback.lua is a control over five settings that four parts own, and
-- the thing that can break it is not the writing. It is a part whose entry
-- stops matching its own switch: `ours` reading one setting while `hand` writes
-- another, or a part deleted from a page and left signed into the registry. Both
-- of those pass every other gate in the repository, because the code is correct
-- and the wiring is not.
--
-- So this section drives the control rather than the settings. Set(true), then
-- every part reports Blizzard's and the frames the fixture carries are back on
-- the screen; Set(false), then every part reports ours and those frames are
-- gone again. Nothing below names a setting to make an assertion pass: the
-- booleans are read after the fact and compared with what the entries claimed.
--
-- Two round trips rather than one, because the second is the one that finds a
-- part that hands back and cannot take it again.
--
-- What the fixture cannot answer: the gryphons, the micro menu and the bag bar.
-- scripts/harness/client/ stands up bar 1's twelve buttons and the experience
-- bar and none of those three, which is the same division 43-blizzard-hide.lua
-- writes down for itself. Those entries are checked through `ours` and their own
-- settings; `/wui blizzard` on a live client is what answers for the frames.
--
-- Everything is put back the way it was found. Nine sections after this one read
-- the bars this one switches off.

local H = ...
local ns, check = H.ns, H.check

local Hand = ns.Handback

-- What the six settings were before this section touched them, so the sections
-- below get the screen they were written against. Read by name because that is
-- the only handle a restore has, and the names are asserted against the entries
-- below rather than trusted.
local KEYS = { "actionBars", "blizzArt", "hideBlizzMicroMenu",
	"hideBlizzBagBar", "hideBlizzXP", "progress" }

local held = {}
for _, key in ipairs(KEYS) do
	check(type(ns.db[key]) == "boolean",
		("handback restores %s and no boolean of that name is in the saved variables"):format(key))
	held[key] = ns.db[key]
end

----------------------------------------------------------------------
-- Who signed in
----------------------------------------------------------------------

local parts = Hand.Parts()
check(#parts == 5,
	("%d parts signed into the handback, and the bottom bar is five things")
		:format(#parts))
check(#Hand.Rows() == #parts, "the reading names a different number of parts than the walk")

----------------------------------------------------------------------
-- Blizzard's
----------------------------------------------------------------------

local complete = Hand.Set(true)
check(complete, "handing the bottom bar back was refused with no fight running")
check(Hand.Given(), "every part handed back and the control still says it did not")

for index = 1, #parts do
	check(parts[index].ours() == false,
		("%s says it is still ours after the whole bar was handed back")
			:format(parts[index].what))
end

check(_G.ActionButton1:IsVisible(),
	"the client's first action button is still off the screen with its bar handed back")
check(_G.MainMenuExpBar:IsVisible(),
	"the client's experience bar is still off the screen with it handed back")
check(ns.Bars.Count() == 0,
	("%d squares of ours are still up with the bars handed back"):format(ns.Bars.Count()))

local reading = Hand.Describe()
check(reading == "all of it Blizzard's own",
	("the reading says %q with the whole bar handed back"):format(reading))

----------------------------------------------------------------------
-- And ours again
----------------------------------------------------------------------

check(Hand.Set(false), "taking the bottom bar back was refused with no fight running")
check(Hand.Given() == false, "every part took its piece back and the control still says Blizzard's")

for index = 1, #parts do
	check(parts[index].ours(),
		("%s says it is Blizzard's after the whole bar was taken back")
			:format(parts[index].what))
end

check(_G.ActionButton1:IsVisible() == false,
	"the client's first action button is on the screen under ours")
check(_G.MainMenuExpBar:IsVisible() == false,
	"the client's experience bar is on the screen under our rails")
check(ns.Bars.Count() > 0, "the bars were taken back and nothing of ours is up")

-- The second round trip. A part that writes its setting on the way out and
-- reads a different one on the way back passes everything above and fails here.
Hand.Set(true)
check(Hand.Given(), "the second hand back left a part saying it is ours")
Hand.Set(false)
check(Hand.Given() == false, "the second take back left a part saying it is Blizzard's")

----------------------------------------------------------------------
-- Put back
----------------------------------------------------------------------

local moved = 0
for _, key in ipairs(KEYS) do
	if ns.db[key] ~= held[key] then
		ns.db[key] = held[key]
		moved = moved + 1
	end
end
ns.Bars.Apply()
ns.PetBar.Apply()
ns.Artwork.Apply()
ns.ProgressRails.Apply()
ns.BlizzHide.Apply()

check(_G.ActionButton1:IsVisible() == false,
	"the restore left the client's bar 1 on the screen for the sections below")

print(("hand   %d parts, %s; %d settings put back")
	:format(#parts, Hand.Describe(), moved))
