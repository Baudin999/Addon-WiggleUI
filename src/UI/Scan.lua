local ADDON, ns = ...

local UI = ns.UI

--------------------------------------------------------------------------
-- The client's own tooltip text, read out as data
--
-- An item's stats, an action slot's rank and cost, a debuff's description: all
-- of it is computed inside the game and there is no API that hands any of it
-- over. The one supported way to read it is to point a tooltip of your own at
-- the thing, let the client fill it in, and read the font strings back. That is
-- what this file does, and it is the only file in the addon that names
-- GameTooltip.
--
-- **That is the whole reason it exists.** Before this, six files each held their
-- own version of the same conversation with the client, and each one drew its
-- answer in Blizzard's parchment while everything beside it drew in the addon's
-- chrome. A hovered action square raised a gold-bordered scroll; the cooldown
-- square eight pixels below it raised a flat black box. Reading the text out as
-- data is what lets both be drawn the same way.
--
-- **A kind, not a method.** A caller asks for `action` or `debuff` and never
-- names a client function, because which function answers a question is exactly
-- the thing that differs between the two clients this addon ships for. A kind
-- this client has no setter for answers nil, and the caller draws whatever it
-- knew on its own.
--
-- **Nothing here is cached.** A scan happens when a tooltip opens, which is a
-- moment, and an item's text can change between two of those moments: a
-- requirement you now meet, a charge you have spent, a cooldown running. A
-- cache would buy a stale tooltip in exchange for nothing anybody can measure.
--------------------------------------------------------------------------

local Scan = {}
UI.Scan = Scan

-- The scanner's name is load bearing. A GameTooltip's lines are reachable only
-- as globals built from the frame's own name, so a nameless one has text on it
-- that nothing can read.
local NAME = "WarriorKitTooltipScan"

-- What each kind asks the client, and how many arguments it passes.
--
-- The count is here rather than left to varargs so a caller that passes the
-- wrong number is refused rather than handed to the client, where the failure
-- is a Lua error inside a C function with no useful traceback. It costs one
-- comparison per hover.
--
-- `item` is a hyperlink, which is the shape everything in this addon carries an
-- item as: a loot row, a mail attachment and a chat link are all one string.
-- `inventory` is a worn slot number and is here for one caller, the weapon
-- enchant square on the buff row, because a temporary enchant answers to the
-- hand it is on rather than to an aura index.
--
-- `bag` is a bag number and a slot, and it is the same item as `item` asked
-- about from where it is lying rather than by name. A link carries no history:
-- the client reading one has no way to know whose bag it came out of, so it
-- says what the item does to whoever picks it up and writes "Binds when picked
-- up" over a sword that bound to you in a raid three months ago. Asked about
-- the slot it is in, the same client writes "Soulbound", because now it can see
-- that the binding already happened. Only a caller that knows the slot can ask
-- this way, which is the bags and nothing else: a loot row, a merchant shelf
-- and a link in chat are all items nobody has picked up yet, and on those the
-- warning is the truth.
--
-- `unit` is a token: player, target, mouseover, nameplate3. It is the only kind
-- here whose subject is not something this addon drew, and the one where the
-- client's text is the whole answer rather than a supplement to it. What the
-- game writes for a unit is the name, the level and classification tag, the
-- faction, the guild and on a player the class: five lines the addon has no
-- other way to word, half of them localised, and all of them already right.
--
-- `spell` is an id and is the only kind here whose subject is not on you and
-- not in a slot. Every other setter asks about a thing at a place: this action
-- slot, this aura index, this hand. A buff you are missing is at no place at
-- all, which is exactly the question the nag row has to ask, and the id is the
-- only handle there is on a spell nobody has cast.
--
-- SetSpellByID landed in Wrath. On the older client this kind answers nil like
-- any other question the client will not take, and the caller draws the name it
-- knew on its own.
--
-- `talent` is two values whose meaning moved: a tab and an index on every
-- client up to the anniversary build, and the talent's own id with a false
-- after it on that one. Talents/Read.lua asks both ways once and keeps the
-- one that wrote the talent's name on its first line, which is why this entry
-- says nothing about what the two values are.
--
-- `craft` is a row of the craft window, and only while that window is open. It
-- is here for beast training, whose rows are pet abilities with no link and no
-- id: SetCraftSpell is what Blizzard_CraftUI/TBC hovers its own icon with.
--
-- `pet` is a slot on the pet bar, one to ten, which is a numbering of its own
-- and not an action slot. SetPetAction is what Blizzard's own pet button hovers
-- with in Blizzard_ActionBar/Shared/PetActionBar.lua.
local KINDS = {
	item      = { method = "SetHyperlink",     args = 1 },
	bag       = { method = "SetBagItem",       args = 2 },
	action    = { method = "SetAction",        args = 1 },
	pet       = { method = "SetPetAction",     args = 1 },
	spell     = { method = "SetSpellByID",     args = 1 },
	buff      = { method = "SetUnitBuff",      args = 2 },
	debuff    = { method = "SetUnitDebuff",    args = 2 },
	inventory = { method = "SetInventoryItem", args = 2 },
	unit      = { method = "SetUnit",          args = 1 },
	talent    = { method = "SetTalent",        args = 2 },
	craft     = { method = "SetCraftSpell",    args = 1 },
}

local tip
local built

-- Three states and all three are different. nil is that nothing has been
-- scanned, false is that the frame was made and answered nothing, true is that
-- it worked. Kept apart because "this client refused the frame" and "this item
-- has no text" have different fixes, and a probe that merged them would tell
-- the player the first when it meant the second.
local answered

-- Built once and remembered, because a client either carries
-- GameTooltipTemplate or it does not and the answer cannot change inside a
-- session. The alternative is a pcall on a CreateFrame on every hover.
local function Frame()
	if built ~= nil then
		return tip
	end

	built = false
	local made, frame = pcall(CreateFrame, "GameTooltip", NAME, UIParent, "GameTooltipTemplate")
	if made and frame and type(frame.NumLines) == "function" then
		tip, built = frame, true
	end
	return tip
end

-- One side of one line, as text and three colour components.
--
-- Nil for a line that is not there or came back empty, which is every right
-- hand side on most lines. The colour travels with the text rather than being
-- normalised away, because on an item that colour is information: the name is
-- the quality, the red line is the requirement you do not meet, the green is
-- the enchant.
--
-- `prefix` is whose lines: the scanner's by default, and the client's own
-- tooltip for a world object, which is the one box whose text nothing can ask
-- for a second time. See Scan.Theirs.
local function Side(index, side, prefix)
	local string = _G[(prefix or NAME) .. "Text" .. side .. index]
	if not string or type(string.GetText) ~= "function" then
		return nil
	end
	local body = string:GetText()
	if not body or body == "" then
		return nil
	end
	if type(string.GetTextColor) ~= "function" then
		return body
	end
	local r, g, b = string:GetTextColor()
	return body, r, g, b
end

-- Whether this client will answer at all, for a caller deciding what to draw
-- before it asks. A caller that simply asks and takes nil is doing the right
-- thing and does not need this.
function Scan.Ready(kind)
	local entry = KINDS[kind]
	if not entry then
		return false
	end
	local frame = Frame()
	return frame ~= nil and type(frame[entry.method]) == "function"
end

-- Ask the client, and hand back whether it took the question.
--
-- **Owned again on every ask, not once when the frame is made.** A GameTooltip
-- that hides drops its owner, and one with no owner takes every setter and
-- writes nothing. NumLines stays at nought, every hover in the addon falls back
-- to its title, the bags file every bound item as unbound, and it stays that way
-- until a reload. This frame is never shown on purpose, but the client hides it
-- on its own terms: UIParent going down takes it along, and a setter asked about
-- a slot whose item moved in the bag update a new item causes is the one that
-- was reported. ANCHOR_NONE because a frame anchored to the cursor would flash a
-- second tooltip on every hover. TitanRepair owns its scanner again before every
-- read on this client, for the same reason.
local function Ask(frame, entry, a, b)
	if type(frame.SetOwner) == "function" then
		frame:SetOwner(UIParent, "ANCHOR_NONE")
	end
	if type(frame.ClearLines) == "function" then
		frame:ClearLines()
	end
	-- A link somebody built by hand raises here rather than coming back empty,
	-- the same as it does in the chat log's hyperlink handler, so every setter
	-- goes through a pcall whatever it is.
	if entry.args == 2 then
		return pcall(frame[entry.method], frame, a, b)
	end
	return pcall(frame[entry.method], frame, a)
end

-- The tooltip with this thing written into it, and how many lines it came to.
--
-- Nil for every way of not getting an answer, which the three readers below all
-- treat as one: a kind nobody declared, a client with no such setter, a caller
-- that passed nothing, and a link the setter raised on. Zero lines with a frame
-- is the other case and it is not the same one, so it comes back as a frame and
-- a count rather than as a second nil.
--
-- Here because there were three copies of it. Read, Has and Match ask the
-- client exactly the same question and differ only in what they do with the
-- answer, and the fourth copy is the one that would have drifted: the guard on
-- `b` is easy to leave out and reads as working, because a setter called with
-- one argument where it wanted two answers a tooltip about nothing rather than
-- raising.
local function Filled(kind, a, b)
	local entry = KINDS[kind]
	if not entry then
		return nil, 0
	end
	local frame = Frame()
	if not frame or type(frame[entry.method]) ~= "function" then
		return nil, 0
	end
	if a == nil or (entry.args == 2 and b == nil) then
		return nil, 0
	end
	if not Ask(frame, entry, a, b) then
		return nil, 0
	end

	local total = frame:NumLines() or 0
	answered = total >= 1
	return frame, total
end

-- The client's text for one thing, as an array of lines.
--
-- Each line is `{ left, lr, lg, lb, right, rr, rg, rb }`, which is the shape
-- UI/Tooltip.lua draws a line from, so nothing between here and the screen has
-- to reshape it. Nil rather than an empty table where there is no answer: an
-- empty array is a thing with no text, a nil is a question this client will not
-- take, and the caller falls back differently for each.
function Scan.Read(kind, a, b)
	local frame, total = Filled(kind, a, b)
	if not frame or total < 1 then
		return nil
	end

	local lines = {}
	for index = 1, total do
		local left, lr, lg, lb = Side(index, "Left")
		local right, rr, rg, rb = Side(index, "Right")
		if left or right then
			lines[#lines + 1] = { left, lr, lg, lb, right, rr, rg, rb }
		end
	end
	return lines
end

-- Whether the client wrote this exact line on the left of its tooltip.
--
-- The same conversation Scan.Read has and none of the table building. A caller
-- that wants one sentence out of a tooltip does not want an array of fifteen
-- lines with eight fields each, and the bag window asks this of every weapon
-- and every piece of armour you are carrying on every bag update. Read on
-- twenty squares five times a loot is fifteen hundred tables the collector then
-- has to walk; this allocates nothing at all.
--
-- Matched whole rather than by pattern, because what is being looked for is a
-- global the client already holds the localised text of. A substring match
-- would answer yes for "Binds when picked up" asked about "Soulbound" on a
-- language where one contains the other, and there is no way to tell from here
-- that it had.
--
-- Nil, false and true are three answers and the caller wants all three: nil is
-- a client that will not take the question, false is a tooltip with no such
-- line, and only true is the line being there.
function Scan.Has(kind, text, a, b)
	if type(text) ~= "string" then
		return nil
	end
	local frame, total = Filled(kind, a, b)
	if not frame then
		return nil
	end

	for index = 1, total do
		local string = _G[NAME .. "TextLeft" .. index]
		if string and type(string.GetText) == "function" and string:GetText() == text then
			return true
		end
	end
	return false
end

-- The first capture of the client's own line matching this pattern.
--
-- Between the two above and it is neither of them. Read hands back every line
-- as a table of eight fields, and a caller after one word out of an item's
-- tooltip throws away fourteen of those tables per item; Has answers yes or no
-- about a line whose whole text the caller already holds. An enchant is the
-- third shape: one line the client publishes the format of and nothing at all
-- about the half that format leaves blank, which is the only half worth
-- printing.
--
-- The pattern belongs to the caller because the format string does. The client
-- hands over ENCHANTED_TOOLTIP_LINE and its siblings in whatever language it is
-- running in, and a file here that built "Enchanted: (.+)" for itself would
-- read nothing at all on a German client and would say nothing about why.
--
-- Nil three ways and the caller cannot tell them apart, which is right: a
-- client that will not take the question, a tooltip with no such line, and a
-- line whose capture came back empty are one answer to a row that has nothing
-- to print.
function Scan.Match(kind, pattern, a, b)
	if type(pattern) ~= "string" then
		return nil
	end
	local frame, total = Filled(kind, a, b)
	if not frame then
		return nil
	end

	for index = 1, total do
		local string = _G[NAME .. "TextLeft" .. index]
		local body = string and type(string.GetText) == "function" and string:GetText()
		local found = body and body ~= "" and body:match(pattern)
		if found and found ~= "" then
			return found
		end
	end
	return nil
end

--------------------------------------------------------------------------
-- The sentence an item's Use line is still waiting for
--
-- A book that teaches a profession says what it is for in one line: "Use:
-- Teaches you advanced first aid, allowing a maximum of 375 first aid skill."
-- That line is not the item's. It is the spell's own sentence printed on the
-- item, and the client does not hold every spell's text at all times. It
-- fetches one when something asks for it, and until it lands the line is not on
-- the tooltip at all.
--
-- Nothing above can see that. A scan is a moment, the tooltip that comes back
-- has the name, the level and the requirement on it, and the only line missing
-- is the one the item exists for. So the reader has to ask a second question,
-- and it is asked here rather than in UI/Tip.lua because it is the same
-- question the rest of this file asks: what is the client able to say about
-- this thing right now.
--
-- **Why it is a book and not a potion.** A spell you have cast, or that sits on
-- a bar, is already on the machine and its line is there on the first hover.
-- What is missing is the spell nothing has ever asked for, which is exactly the
-- one an unlearned book teaches. That is why this went unnoticed while every
-- trinket and every flask read correctly.
--
-- The three calls are Syndicator's, in Search/CheckItem.lua, and it makes all
-- three on this client rather than only on the newer one: the item's spell id,
-- whether its text is here, and the ask for one that is not.
--------------------------------------------------------------------------

-- Whether the client is still fetching the spell behind this item's Use line,
-- and an ask for it where it is.
--
-- False for an item with no use effect at all, which is most of them, and false
-- on a client that will not take the question. Both are "nothing is coming",
-- and a caller that told them apart would only be waiting on a fetch nobody
-- ever started.
function Scan.Waiting(link)
	local _, id = ns.ItemSpell(link)
	if type(id) ~= "number" then
		return false
	end

	local space = _G.C_Spell
	local cached = type(space) == "table" and space.IsSpellDataCached
	if type(cached) ~= "function" then
		return false
	end
	local asked, here = pcall(cached, id)
	if not asked or here then
		return false
	end

	-- The ask, and nothing is done with the answer. It is a request rather than
	-- a read: the client says nothing back and fires SPELL_DATA_LOAD_RESULT when
	-- the text has landed, which is what UI/Tip.lua listens for.
	local fetch = space.RequestLoadSpellData
	if type(fetch) == "function" then
		pcall(fetch, id)
	end
	return true
end

--------------------------------------------------------------------------
-- Holding the client's own tooltip down
--
-- Every other hover in this addon is replaced by replacing the frame it lands
-- on. There is an OnEnter, the addon writes it, and Blizzard's tooltip is never
-- asked for. A creature in the world has no such frame: the cursor is over
-- WorldFrame, the client resolves `mouseover` and fills GameTooltip itself, and
-- there is nothing to overwrite. So the only way to have one box on screen
-- rather than two is to take the client's back down after it has gone up.
--
-- It is here because this is the file allowed to name GameTooltip, and that
-- rule is worth more than the convenience of putting the code beside the part
-- that asks for it. scripts/check.sh fails on the name anywhere else, comments
-- included.
--
-- **Narrow twice, and both narrowings are load bearing.** It is armed only
-- while the addon has a box of its own on screen, and it acts only on a tooltip
-- that answers a unit. GameTooltip is shared furniture: a quest reward, an item
-- somebody linked in chat, a bag slot, a merchant row and every other addon
-- installed all draw in it, and none of those is this addon's to take away.
--
-- What the two ways of being wrong cost is not the same, which is why the test
-- is the strict one rather than the thorough one.
--
--   too broad   a hover that is not a creature loses its tooltip whenever a mob
--               happens to be under the cursor as well. A linked item says
--               nothing, a quest reward says nothing, and nothing on screen
--               says why. That is a bug report nobody can reproduce.
--   too narrow  Blizzard's parchment stands beside the addon's box and the same
--               mob is described twice. Ugly for an evening, and nothing is
--               lost.
--
-- **The hook is never taken off.** HookScript chains under whatever the client
-- and every other addon already put there and there is no call to undo one, so
-- the flag below is what actually turns this on and off. Disarmed, the hook is
-- one comparison on a tooltip that was going to be shown anyway.
--------------------------------------------------------------------------

local suppressing = false
local hooked = false

-- Take it down if it is up and it is about a unit.
--
-- Called from the hook and again the moment suppression is armed, because the
-- client shows its tooltip and fires UPDATE_MOUSEOVER_UNIT in whichever order
-- it likes: the addon can hear about the mouseover after the parchment is
-- already on screen, and then no OnShow is coming.
local function Hush()
	if not suppressing then
		return
	end
	local theirs = GameTooltip
	if type(theirs) ~= "table" or type(theirs.GetUnit) ~= "function" then
		return
	end
	-- The name comes back first and is thrown away. A tooltip describing an
	-- item has a name too; only the second return says the subject is a unit.
	local _, unit = theirs:GetUnit()
	if unit == nil or type(theirs.Hide) ~= "function" then
		return
	end
	theirs:Hide()
end

-- Arm or disarm, and answer whether it is armed.
--
-- False on a client that will not take the hook at all, which is not the same
-- as being turned off: the caller is drawing its own box either way and has to
-- be able to tell the player they are about to see two.
function Scan.Suppress(on)
	suppressing = on and true or false
	if not suppressing then
		return false
	end

	if not hooked then
		if type(GameTooltip) ~= "table" or type(GameTooltip.HookScript) ~= "function"
			or not pcall(GameTooltip.HookScript, GameTooltip, "OnShow", Hush) then
			suppressing = false
			return false
		end
		hooked = true
	end

	Hush()
	return true
end

function Scan.Suppressing()
	return suppressing
end

--------------------------------------------------------------------------
-- A thing in the world that is not a creature
--
-- An ore vein, a herb, a chest, a mailbox, a fishing bobber. The client
-- describes each of these in GameTooltip and in nothing else: there is no token
-- for one, no event when the pointer finds one, and no setter a scanner of our
-- own could be pointed at. The unit hover above has UPDATE_MOUSEOVER_UNIT to
-- tell it a hover began and `mouseover` to ask about; an object has neither.
--
-- So the client's own tooltip is the only witness, and this is the half of it
-- that listens. World/World.lua is the half that decides, which is why the
-- hook hands over a boolean and nothing else: whether the box is about the
-- world is a question about the pointer, and this file only knows tooltips.
--
-- **Held at no alpha, never hidden.** The unit hover can take Blizzard's box
-- down because UnitExists("mouseover") says when the pointer leaves. Nothing
-- says that about an object except the client taking its own tooltip down, so
-- hiding it would throw away the one signal the addon's box has to close on.
-- Invisible, it goes on doing its job: it hides when the pointer leaves, and
-- OnHide is the close.
--
-- **Handed back at the first doubt.** GameTooltip is the furniture every other
-- addon draws in, and a box of theirs landing in a frame this file left at
-- nought is a tooltip that says nothing on screen. Every show that is not an
-- object puts the alpha back before anybody else's hook can read it, every hide
-- puts it back, and World.lua's sweep lets go the moment the subject changes
-- under it.
--------------------------------------------------------------------------

-- The client's own lines are globals built off this name, the same way the
-- scanner's are built off NAME.
local THEIRS = "GameTooltip"
local THEIRS_TITLE = "GameTooltipTextLeft1"

-- The three questions whose answer means a setter could have named the thing,
-- and so it is not loose.
local NAMED = { "GetUnit", "GetItem", "GetSpell" }

local watcher
local watched = false
local holding = false

-- Whether the client's tooltip is up about a thing that is none of the three
-- things a setter can name. Owned by UIParent, which is what the client's
-- default anchor for the world passes; a frame's tooltip is owned by the frame.
local function Loose(theirs)
	if type(theirs) ~= "table" or type(theirs.IsShown) ~= "function" or not theirs:IsShown() then
		return false
	end
	if type(theirs.GetOwner) ~= "function" or theirs:GetOwner() ~= UIParent then
		return false
	end
	for index = 1, #NAMED do
		local fn = theirs[NAMED[index]]
		if type(fn) == "function" then
			local _, about = fn(theirs)
			if about ~= nil then
				return false
			end
		end
	end
	return true
end

-- The alpha given back, and nothing else. Its own function because four
-- places let go and a fifth copy is the one that forgets.
local function Release()
	if not holding then
		return
	end
	holding = false
	local theirs = GameTooltip
	if type(theirs) == "table" and type(theirs.SetAlpha) == "function" then
		theirs:SetAlpha(1)
	end
end

local function Shown()
	Release()
	if watcher then
		watcher(true)
	end
end

local function Hidden()
	Release()
	if watcher then
		watcher(false)
	end
end

-- Hand in the one function that hears the client's tooltip go up and come
-- down, with true and false. One and not a list, for the reason Tip.SetCompare
-- takes one: two parts deciding what a world object gets are two boxes.
--
-- Answered as whether the hooks took. False on a client that refuses them, and
-- then the parchment is what the player sees, which is the right way to fail.
function Scan.Watch(fn)
	watcher = type(fn) == "function" and fn or nil
	if watched then
		return true
	end
	local theirs = GameTooltip
	if type(theirs) ~= "table" or type(theirs.HookScript) ~= "function" then
		return false
	end
	if not pcall(theirs.HookScript, theirs, "OnShow", Shown)
		or not pcall(theirs.HookScript, theirs, "OnHide", Hidden) then
		return false
	end
	watched = true
	return true
end

-- The client's lines about the loose thing it is showing, and the name first
-- among them, or nil where it is showing something else.
--
-- Read once, when the box opens. The lines come back in the shape Scan.Read
-- hands out, colour and all: "Requires Mining" is red on a vein you cannot
-- work, and that red is the client's whole answer to whether you can.
function Scan.Theirs()
	local theirs = GameTooltip
	if not Loose(theirs) or type(theirs.NumLines) ~= "function" then
		return nil
	end
	local lines = {}
	for index = 1, theirs:NumLines() or 0 do
		local left, lr, lg, lb = Side(index, "Left", THEIRS)
		local right, rr, rg, rb = Side(index, "Right", THEIRS)
		if left or right then
			lines[#lines + 1] = { left, lr, lg, lb, right, rr, rg, rb }
		end
	end
	if not lines[1] or not lines[1][1] then
		return nil
	end
	return lines[1][1], lines
end

-- The name on the client's tooltip while it is still about a loose thing, or
-- nil. What World.lua's sweep asks a few times a second, so it builds nothing:
-- a name that changed is the pointer on a different vein, and nil is the
-- tooltip gone or taken over by something a setter names.
function Scan.TheirName()
	local theirs = GameTooltip
	if not holding or type(theirs) ~= "table" or not theirs:IsShown()
		or theirs:GetOwner() ~= UIParent then
		return nil
	end
	local title = _G[THEIRS_TITLE]
	if not title or type(title.GetText) ~= "function" then
		return nil
	end
	return title:GetText()
end

-- Hold the client's box at nought, or let it go. Answered as whether it is
-- held, which is false on a client with no alpha to set and then both boxes
-- stand.
function Scan.Hold(on)
	if not on then
		Release()
		return false
	end
	local theirs = GameTooltip
	if type(theirs) ~= "table" or type(theirs.SetAlpha) ~= "function" then
		return false
	end
	if not holding then
		theirs:SetAlpha(0)
		holding = true
	end
	return true
end

function Scan.Holding()
	return holding
end

function Scan.Describe()
	if built == false then
		return "this client refused a tooltip of its own, so nothing computed inside the game can be read"
	end
	if answered == nil then
		return "nothing has been hovered yet"
	end
	if not answered then
		return "this client hands over no text, so a hover shows the name and nothing more"
	end
	return "reading the client's own text and drawing it in the addon's chrome"
end
