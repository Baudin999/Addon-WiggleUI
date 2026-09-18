local ADDON, ns = ...

local Cast = {}
ns.HoverCast = Cast

--------------------------------------------------------------------------
-- The button every hover key presses
--
-- One secure button carrying one macro per binding, and one override binding
-- per key pointing at it.
--
-- One button rather than twelve. A secure button looks its action up under
-- `<modifiers>type<click>`, so the click name is the whole of what tells the
-- button which binding fired. SetOverrideBindingClick takes that name as its
-- last argument, which is what Marking/Keys.lua already uses it for: it hands
-- the mark's id over and reads it back out of the OnClick. The same mechanism,
-- one layer more secure.
--
-- The name has two halves and both of them shipped wrong, one after the other.
--
-- The `*` in front is the modifier. The prefix is read off the keyboard at the
-- moment of the press, so a binding on ALT-BUTTON3 arrives looking for
-- `alt-type...`, and every key worth putting a mouseover spell on carries a
-- modifier. `*` is the wildcard the client falls back to when the modified name
-- holds nothing, which is why UnitFrames/Group.lua writes its click actions the
-- same way.
--
-- The dash behind it is the click name, and it is the one that was still wrong
-- after the modifier was fixed. The client turns the name a click arrives under
-- into an attribute suffix, and it only has five names it answers with a bare
-- number: LeftButton is `1`, RightButton is `2`, and so on to Button5. Every
-- other name is answered with a dash in front of it. So a click handed over as
-- `1` is not the button one at all, it is a name of its own, and the suffix the
-- client goes looking for is `-1`. The attributes were under `*type1`, the press
-- asked for `*type-1`, and the key bound, read back correctly, arrived at the
-- button and cast nothing.
--
-- Clique is where the shape came from. Every name it hands the binding layer is
-- a word rather than a number, and every attribute it writes for one carries the
-- dash: `type-cliquebuttonshiftF`. Buttons/Bars.lua is the same rule seen from
-- the other side, and is why its keys have always worked: it hands over the
-- literal `LeftButton`, which is one of the five, and reads `type1`.
--
-- So the click is called `wk<index>` and the attribute is `*type-wk<index>`.
--
-- What sits under that name is macro text, and the argument for text rather
-- than attributes is under "What one binding writes on the button" below.
--
-- Nothing here runs on a ticker and nothing here is rewritten in a fight. Apply
-- is called at login, when a binding changes, and when combat drops on a change
-- combat refused.
--------------------------------------------------------------------------

local BUTTON_NAME = "WarriorKitHoverButton"
Cast.BUTTON_NAME = BUTTON_NAME

-- No size and no anchor, the shape Marking/Keys.lua uses and Clique uses for its
-- own global button. It is never meant to be hit by a real cursor and a frame
-- with no size cannot be. It is left shown, because a click delivered by the
-- binding system is only proven to arrive on a shown frame.
--
-- The bare `type` is never set. A stray click that arrives with no name on it
-- finds nothing and does nothing, which is the right answer for a button whose
-- only real callers name themselves.
--
-- The press, which is what a key that casts should feel like and what Clique
-- ships on its own global button. UI/Press.lua writes the registration and the
-- attribute to agree; both edges registered against an unset attribute was the
-- shape this file shipped, and the keys cast nothing.
local button = ns.UI.Press.Button(UIParent, BUTTON_NAME, "down")

--------------------------------------------------------------------------
-- What one binding is called
--
-- The click name and the attribute names are one decision, so they are made
-- once and here, above everything that writes either of them. The reasoning is
-- in the header; this is the shape of it.
--------------------------------------------------------------------------

-- The name one binding's click arrives under, and what the binding layer stores.
-- A word rather than a number, for the reason in the header.
local function Name(index)
	return "wk" .. index
end

-- The tail of every attribute that answers a click called `name`. The dash is
-- the client's own and not this file's punctuation: it is what a click name that
-- is not one of the five real mouse buttons is turned into a suffix by.
local function Tail(name)
	return "-" .. name
end

--------------------------------------------------------------------------
-- The debug log
--
-- Off by default and silent when off. It is here because this feature fails in
-- three places that all look the same from a chair: the key was never put on
-- the binding layer, the key was put there and the client is not delivering it,
-- or the press arrives and the conditional discards it. One of those is a
-- client that will not take the key, one is a client that takes it and lies,
-- and one is a filter set to `an enemy` on a healing spell. Nothing about the
-- three is distinguishable from the outside, and the third is by far the most
-- common.
--
-- So the log says one line where the binding is written, one line where the
-- press arrives, and one line for the verdict. A press with no `arrived` line
-- is the second case; a press with one and a verdict of nothing is the third.
--------------------------------------------------------------------------

local function Log(fmt, ...)
	if not (ns.db and ns.db.hoverDebug) then
		return
	end
	ns.Print("|cff808080hover|r " .. (select("#", ...) > 0 and fmt:format(...) or fmt))
end

-- PostClick, and installed only while the log is on. Both halves of that are the
-- repair for a mistake this file made and then spent four settings chasing.
--
-- It was a PreClick, set at load and left there, returning early when the log was
-- off. PreClick runs insecure Lua inside the click, before the secure handler,
-- and an insecure script in that path taints it, so the protected call at the end
-- is dropped. An early return does not help: the taint is the script running at
-- all, not what it does. So every press since the log was added arrived at the
-- button, read back perfectly, matched its conditional, and cast nothing, and the
-- log sat underneath saying the press was fine. The instrument was the fault.
--
-- PostClick runs after the secure handler has had its turn, so nothing written
-- here can take the cast away. It reports the same things one moment later.
--
-- Installed and cleared rather than left in place, because a debug hook that is
-- only inert when it returns early is not inert. With the log off there is no
-- script on this button at all and the click path is the client's own.
local function Trace(_, click, down)
	local index = tonumber(tostring(click):match("^wk(%d+)$") or "")
	local bind = index and ns.Hover.List()[index]
	Log("arrived on %s, down %s", tostring(click), tostring(down))
	if not bind then
		Log("  no binding at %s, so the button carries nothing for it", tostring(click))
		return
	end
	for line in (Cast.Macro(index) or "|cffff5555the button carries nothing under that name|r"):gmatch("[^\n]+") do
		Log("  %s", line)
	end
	Log("  %s", ns.Hover.Sight())
	Log("  %s", ns.Hover.Would(bind))

	-- The client's own reading of the same conditional, one form at a time. Every
	-- line saying matches, with no cast behind it, is what said the macro was
	-- never the problem.
	for _, form in ipairs(ns.Hover.Forms(bind)) do
		local knows = ns.Hover.Understands(form, bind.name)
		Log("  %s %s", form,
			knows == nil and "cannot be asked on this client"
				or (knows and "matches" or "|cffff5555does not match|r"))
	end
end

--------------------------------------------------------------------------
-- What one binding writes on the button
--
-- Macro text, under `*type-wk<index>` and `*macrotext-wk<index>`, and the text
-- is Hover.Macro's: the spell on the mouseover when the filter passes, and
-- otherwise a `/click` on whatever the key was pressing before this binding was
-- put on top of it. That second line is what lets a heal sit on a bar and on
-- this list under one key, and cast on yourself when nothing is under the
-- cursor.
--
-- This file shipped the other way round once, as `type` = spell with a `unit`
-- and the filter said as `helpbutton`, on the belief that macro text set by
-- insecure code and run off a keypress is what the secure system refuses. It is
-- not, and Charge/Icon.lua is the proof: its button has carried `type` = macro
-- and a `macrotext` written from Lua since the addon began, and its key has
-- always cast. What was refusing the press here was the PreClick script the
-- debug log below no longer installs, tainting the click before the secure
-- handler saw it. The attributes cast once the script was gone, and text would
-- have cast the same day.
--
-- Attributes cannot do what this needs, and the client's own SecureTemplates
-- says why in one line: a button whose `unit` does not exist drops the press
-- before it looks at what the click carries. `unit` = mouseover with nothing
-- under the cursor is that, so no key with a unit on it can fall through to the
-- bar, and `helpbutton` could only send a press on the wrong sort of unit to a
-- name holding nothing. A conditional says both halves: cast on this, or press
-- that. `nodead` comes back with it, which attributes had lost.
--
-- What the key was pressing is Buttons/Bars.lua's to say, because it is the
-- part that reads the binding set for a square and knows which square, and it
-- is asked on every apply rather than remembered, because a bar that comes up
-- after login changes the answer.
--------------------------------------------------------------------------

-- Every name any binding has ever been given, cleared before the live ones go
-- back on. A binding taken off the list leaves its text behind otherwise, and
-- the key it was on is free again while the macro sits there waiting for a click
-- that will never come, which is the kind of leftover that only shows up when a
-- later binding lands on the same index.
local function Wipe()
	for index = 1, ns.Hover.MAX do
		local tail = Tail(Name(index))
		button:SetAttribute("*type" .. tail, nil)
		button:SetAttribute("*macrotext" .. tail, nil)
	end
end

local function Write(index, bind)
	local beneath
	local name, mouse, down = ns.Bars.Beneath(bind.key)
	if name then
		beneath = { name = name, button = mouse, down = down }
	end
	local tail = Tail(Name(index))
	button:SetAttribute("*type" .. tail, "macro")
	button:SetAttribute("*macrotext" .. tail, ns.Hover.Macro(bind, beneath))
end

-- The keys, one per binding, on the button above, each handing over the
-- binding's click name. Override bindings, never real ones, see UI/Bound.lua.
-- A spell and an item go up the same way: the difference is the verb in the
-- macro text Write puts on the button before the key goes on, and the key
-- fires the button on the press its registration answers, which UI/Press.lua
-- wrote from the one edge above.
local keys = ns.UI.Bound.Keys({
	button = button,
	name = BUTTON_NAME,
	wanted = function()
		return ns.db.hover
	end,
	list = function()
		local list = {}
		for index, bind in ipairs(ns.Hover.List()) do
			list[index] = { id = index, key = bind.key, click = Name(index), bind = bind }
		end
		return list
	end,
	clear = Wipe,
	put = function(one)
		Write(one.id, one.bind)
	end,
	told = function(one, taken, reads)
		if taken == nil then
			Log("|cffff5555%s is not a key this can bind|r", tostring(one.key))
		elseif not taken then
			Log("|cffff5555%s was refused by the client|r", one.key)
		else
			Log("%s is index %d, %s", one.key, one.id,
				reads == nil and "the readback could not be asked"
					or (reads and "the binding layer agrees" or "|cffff5555the binding layer does not have it|r"))
			for line in Cast.Macro(one.id):gmatch("[^\n]+") do
				Log("  %s", line)
			end
		end
	end,
	log = Log,
	idle = "mouseover casting is off, so no key is up",
	refused = "this client would not take a key for mouseover casting.",
	ignored = "this client accepted the mouseover keys and did not bind them.",
})

-- Returns false when combat deferred the work, so the caller can say so.
Cast.Apply = keys.Apply

-- Whether a key this file put up is actually holding. The panel draws a bound
-- key in the quiet grey when this comes back false, so a key the client refused
-- looks different from a key that is doing its job.
function Cast.Holding(index)
	return keys.Holds(index) ~= nil
end

-- Always reports what the binding layer says, never what this file meant to set.
function Cast.Describe()
	return keys.Trouble() or (keys.Active() and "the keys are up" or "no key is up")
end

-- What one binding is carrying, read back off the button rather than built again.
-- `/wk hover show` prints these, and a line that came from the same place the
-- press comes from is the only line worth printing. Nil where the button holds
-- nothing under that name.
function Cast.Macro(index)
	return button:GetAttribute("*macrotext" .. Tail(Name(index)))
end

--------------------------------------------------------------------------
-- Did the client do anything with it
--
-- The one question the two logs above cannot answer between them. PostClick says
-- the press reached the button; nothing on this side of the secure handler says
-- whether the macro ran, because a conditional that does not match and a
-- protected call that was discarded are both silent and look identical.
--
-- UNIT_SPELLCAST_SENT is the client answering. A press with a verdict of `casts`
-- and no `the client sent` line under it is the press being thrown away, which
-- is exactly the failure the click registration above was.
--
-- Registered only while the log is on, and it fires once per cast rather than on
-- a ticker, so it costs nothing either way.
--------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, unit, target, _, spell)
	if event == "UNIT_SPELLCAST_SENT" then
		if unit == "player" then
			Log("  the client sent %s at %s",
				ns.SpellName(spell) or tostring(spell), target or "nothing")
		end
		return
	end
	Cast.Apply()
	Cast.Watch()
end)

-- Called where the log is turned on and off, and once at login, because a log
-- that only starts watching at the next reload is a log that lies by omission.
function Cast.Watch()
	local on = ns.db and ns.db.hoverDebug
	button:SetScript("PostClick", on and Trace or nil)
	if on then
		events:RegisterEvent("UNIT_SPELLCAST_SENT")
	else
		events:UnregisterEvent("UNIT_SPELLCAST_SENT")
	end
end
