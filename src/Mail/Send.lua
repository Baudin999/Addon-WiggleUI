local ADDON, ns = ...

local Send = {}
ns.MailSend = Send

--------------------------------------------------------------------------
-- Getting the letter out
--
-- Mail/Draft.lua says what is being sent and how many mails that divides into.
-- This is the conversation with the server: fill the client's own form, send
-- it, wait for the server to say it went, fill it again.
--
-- **Why it is a state machine and not a loop.** A mail is not sent when
-- SendMail returns. The attachments leave your bags, the server thinks about
-- it, and MAIL_SEND_SUCCESS arrives some time later with the form now empty. A
-- loop that filled the form three times in one frame would put thirty six items
-- into twelve slots and lose twenty four of them. So there is exactly one mail
-- in flight and the next one starts when the server has finished with the last.
--
-- **How an item gets onto the form.** UseContainerItem, with the send pane
-- flagged as showing. That is the same call that sells a grey at a merchant and
-- eats a bread roll anywhere else, and the flag is what decides which: this is
-- the shape Baganator/Transfers/AddToMail.lua uses on this exact client, and
-- SetSendMailShowing is what it sets first.
--
-- The pick-up-and-click route is the other way to do it, and it is worse here.
-- It puts an item on the cursor, which means a failure halfway leaves the
-- player holding a stack of ore in the middle of a window, and it needs the
-- attachment slot chosen by hand. UseContainerItem picks the first free slot
-- itself and never touches the cursor.
--
-- **Every slot is resolved again at send.** Draft holds a link and the bag slot
-- it was dropped from, and both are checked before anything moves: the slot has
-- to still hold that same link, and if it does not the bags are rescanned for
-- one that does. An item that has genuinely gone is counted and reported rather
-- than silently replaced by whatever is in that slot now, which is the failure
-- Comfort/Destroy.lua is built around and is worse here.
--
-- **Filling the form waits too, and that was the bug.** The fill used to be one
-- pass: walk the twelve, attach what is there, and anything whose bag slot was
-- locked at that instant was counted as gone and left behind. Mail two is
-- filled from inside the MAIL_SEND_SUCCESS handler, which is the one moment in
-- a send when the bags are certain to be mid-move, so the second mail of a
-- split reached a batch of locked slots, placed nothing, and stopped with
-- "nothing of that mail is still in your bags". The split worked everywhere
-- except in a game.
--
-- So a mail is filled over as many passes as it takes. Each pass asks for what
-- it can, the client's own lock and bag events bring the next one, and the mail
-- goes when the form holds the whole batch. An item that is genuinely gone is
-- counted once and never asked for again, and PATIENCE is what ends a wait on
-- something that will never come free.
--
-- **There is no timeout and that is deliberate.** A stalled send waits, the
-- window says which mail of how many it is waiting on, and there is a stop
-- button under it. The alternative is an OnUpdate, and an OnUpdate is a ticker
-- this addon would then have to defend forever, for a case that is a server not
-- answering. MAIL_FAILED and the mailbox closing both end it on their own.
--
-- **And a refusal has to be undoable.** A mail the server would not take has
-- left its attachments on the client's own form, and that form is parked off
-- the side of the screen: nothing on the screen says the twelve items are
-- there and no press in this window used to put them back. Send.Unload is that
-- press, and the window's clear button is where it is wired.
--------------------------------------------------------------------------

-- Nothing, one in flight, or finished. `done` counts mails the server has
-- confirmed, so "2 of 3" is a fact rather than a hope.
local running, at, done, total = false, 0, 0, 0
local missing, note = 0, ""

-- The mail being filled: its attachments, which of them have been asked for,
-- how many are never coming, and how many event passes in a row have moved
-- nothing. `filling` is false while the mail is with the server, which is the
-- half of the run no bag event has anything to say about.
local batch, asked, gone, idle = nil, {}, 0, 0
local filling = false

-- How many passes that move nothing this will sit through before it sends what
-- it has. Every pass is the client saying a lock or a bag changed, so four of
-- them with nothing moving is the bags having settled around an item that is
-- not going to come free.
local PATIENCE = 4

-- Made here rather than at the foot of the file, because a run turns two of its
-- events on and off and both ends of that are above the handler.
local events = CreateFrame("Frame")

--------------------------------------------------------------------------
-- The client's own form
--------------------------------------------------------------------------

-- Whether the attachment slot at this index is holding something. The itemID is
-- the second return and is the one that is nil for an empty slot; the name is
-- not, on an item the client has not cached.
local function Occupied(index)
	local ask = _G.GetSendMailItem
	if type(ask) ~= "function" then
		return nil
	end
	local ok, _, itemId = pcall(ask, index)
	if not ok then
		return nil
	end
	return itemId ~= nil
end

-- The first free attachment slot, or nil when the form is full. Nil is also
-- what a client with no GetSendMailItem answers, and a send that cannot see the
-- form is a send that must not start.
local function FreeSlot()
	for index = 1, ns.MailDraft.PerMail() do
		local held = Occupied(index)
		if held == nil then
			return nil
		end
		if not held then
			return index
		end
	end
	return nil
end

-- How many of the twelve are already taken. Anything at all here before the
-- first mail goes is the player's own half-built form in Blizzard's window, and
-- sending it would be sending something they did not put on ours.
local function Loaded()
	local count = 0
	for index = 1, ns.MailDraft.PerMail() do
		if Occupied(index) then
			count = count + 1
		end
	end
	return count
end

-- The flag that decides what UseContainerItem does. Raised before every fill,
-- which is what Baganator does.
--
-- It used to be raised and left, and that was defensible until a right click in
-- the bags meant something. With the flag up, a bag click the addon did not
-- catch attaches to the client's own form, and that form is parked off the side
-- of the screen: the item leaves your bags and lands on an invisible letter
-- nobody is going to send. So a run that has finished puts it back down. The
-- claim is only about the runs this file drives, which is the only thing it
-- knows anything about.
local function Showing(state)
	local tell = _G.SetSendMailShowing
	if type(tell) ~= "function" then
		return false
	end
	return pcall(tell, state)
end

--------------------------------------------------------------------------
-- Filling it in
--------------------------------------------------------------------------

-- Where this attachment is now, or nil. The slot it was dropped from first,
-- because that is nearly always still right and costs one lookup; a rescan
-- after, because a bag that moved is the ordinary case rather than the
-- exception.
local function Locate(entry)
	if ns.ContainerItemLink(entry.bag, entry.slot) == entry.link then
		return entry.bag, entry.slot
	end
	return ns.MailDraft.Slot(entry.link)
end

-- One attachment asked for. Three answers, and the middle one is the whole
-- reason this file has passes at all: nil is an item that is not in your bags
-- any more, false is one that is there and not free to move yet, and true is
-- one the client has been told to attach.
--
-- Whether it landed is not asked here. The form is counted instead, once a
-- pass, because a client that attaches a frame later would otherwise have every
-- item asked for twice: once on the pass that moved it and once on the pass
-- that found the slot still looking empty.
local function Offer(entry)
	local bag, slot = Locate(entry)
	if not bag then
		return nil
	end

	-- A locked slot is a move the server has not finished. Asking for it now
	-- would be asking the client to do two things with one stack, so it waits
	-- for the lock to clear and the next pass picks it up.
	local _, locked = ns.ContainerItem(bag, slot)
	if locked then
		return false
	end

	if not FreeSlot() then
		return false
	end
	if not ns.UseContainerItem(bag, slot) then
		return nil
	end
	return true
end

--------------------------------------------------------------------------
-- One mail
--------------------------------------------------------------------------

local function Stop(why)
	running, at, filling = false, 0, false
	batch = nil
	note = why or note
	Showing(false)
	events:UnregisterEvent("ITEM_LOCK_CHANGED")
	events:UnregisterEvent("BAG_UPDATE_DELAYED")
	return false
end

-- The form as it stands, handed to the server. `placed` is what the form is
-- carrying, which is what the run counted rather than what it hoped for.
local function Ship(placed)
	local Draft = ns.MailDraft
	local post = _G.SendMail
	if type(post) ~= "function" then
		return Stop("this client has no SendMail")
	end

	filling = false
	missing = missing + gone

	local money = Draft.MoneyOn(at)
	if money > 0 and type(_G.SetSendMailMoney) == "function" then
		pcall(_G.SetSendMailMoney, money)
	end

	if placed == 0 and money == 0 and Draft.Body() == "" then
		return Stop("nothing of that mail is still in your bags")
	end

	if not pcall(post, Draft.To(), Draft.SubjectFor(at), Draft.Body()) then
		return Stop("the client refused the send")
	end
	note = ("mail %d of %d is with the server"):format(at, total)
	return true
end

-- One pass over the mail being filled. Called once when the mail starts and
-- again on every lock and bag event until the form holds the batch.
--
-- The form is counted rather than each attachment being verified, because the
-- form starts every mail empty: what is on it is what this batch has put there.
local function Pass()
	local want = #batch
	local landed = Loaded()
	if landed + gone >= want then
		return Ship(landed)
	end

	local moved = false
	for index = 1, want do
		if not asked[index] then
			local answer = Offer(batch[index])
			if answer == nil then
				asked[index], gone, moved = true, gone + 1, true
			elseif answer then
				asked[index], moved = true, true
			end
		end
	end

	landed = Loaded()
	if landed + gone >= want then
		return Ship(landed)
	end

	if moved then
		idle = 0
		return true
	end

	-- Nothing moved and nothing is coming. What is left is counted as left
	-- behind rather than waited on forever, and the window says how many.
	idle = idle + 1
	if idle < PATIENCE then
		return true
	end
	gone = want - landed
	return Ship(landed)
end

-- One pass at a time, and never two.
--
-- UseContainerItem is what a pass calls and ITEM_LOCK_CHANGED is what a pass
-- waits for, and nothing says the client may not send the second from inside
-- the first. A re-entered pass would ask again for every attachment the outer
-- one had not reached yet, which is the same stack asked for twice.
local passing = false

local function Fill()
	if passing then
		return true
	end
	passing = true
	local answered = Pass()
	passing = false
	return answered
end

local function Begin(which)
	at, batch, gone, idle = which, ns.MailDraft.Batch(which), 0, 0
	-- `passing` with it, because a new mail is a new pass whatever the last one
	-- was doing when its send went out.
	asked, passing = {}, false
	filling = true
	Showing(true)
	note = ("mail %d of %d is going onto the form"):format(which, total)
	return Fill()
end

--------------------------------------------------------------------------
-- The run
--------------------------------------------------------------------------

function Send.Start()
	if running then
		return false, "a send is already going"
	end

	local why = ns.MailDraft.Problem()
	if why then
		return false, why
	end

	local already = Loaded()
	if already > 0 then
		return false, ("%d items are already on the client's own mail form"):format(already)
	end

	running, done, missing = true, 0, 0
	total = ns.MailDraft.Mails()
	note = ""
	-- The two the fill waits on, held only while a run is going. A send is a
	-- minute of an evening and these two are among the noisiest events the
	-- client has, so the frame is deaf to both the rest of the time.
	events:RegisterEvent("ITEM_LOCK_CHANGED")
	events:RegisterEvent("BAG_UPDATE_DELAYED")
	if not Begin(1) then
		return false, note
	end
	return true
end

-- What is sitting on the client's own form. Nought is the ordinary answer and
-- the only one a send may start on; anything else is a mail the server refused,
-- or a form the player half filled in Blizzard's own window.
function Send.Loaded()
	if running then
		return 0
	end
	return Loaded()
end

-- The form emptied back into the bags.
--
-- ClearSendMail is the client's own reset and is what SendMailFrame_Reset calls
-- on every close of Blizzard's window. Without it a refused mail leaves twelve
-- items on a form parked off the side of the screen, every send after it is
-- refused for a reason nothing on the screen can undo, and the only way out is
-- to walk away from the mailbox. Clicking each slot is the older way to the
-- same place and is the fallback, because one of the two exists on every
-- client that has a mailbox at all.
function Send.Unload()
	if running then
		return false
	end

	local reset = _G.ClearSendMail
	if type(reset) == "function" and pcall(reset) then
		note, missing = "", 0
		return true
	end

	local click = _G.ClickSendMailItemButton
	if type(click) ~= "function" then
		return false
	end
	for index = ns.MailDraft.PerMail(), 1, -1 do
		if Occupied(index) then
			pcall(click, index)
		end
	end
	note, missing = "", 0
	return true
end

-- Everything this file remembers, put back. The window calls it as it closes,
-- because the sentence under the send button is about a letter that is over and
-- a window that reopens saying "mail 2 of 3 was refused" is a window describing
-- somebody else's evening.
function Send.Forget()
	Send.Stop()
	done, total, missing, note = 0, 0, 0, ""
	return true
end

function Send.Stop()
	if not running then
		return false
	end
	Stop("stopped after " .. done .. " of " .. total)
	return true
end

function Send.Running()
	return running
end

function Send.Progress()
	return done, total
end

function Send.Missing()
	return missing
end

function Send.Note()
	return note
end

-- What a mail window puts under its send button, and what `/wui status` says.
function Send.Describe()
	if running then
		return ("sending %d of %d"):format(at, total)
	end
	if note == "" then
		return "nothing sent yet"
	end
	if missing > 0 then
		return ("%s, %d left in your bags"):format(note, missing)
	end
	return note
end

--------------------------------------------------------------------------

-- The server's answer. Success advances; failure stops and keeps the reason,
-- because a mail that failed has left its attachments on the client's form and
-- carrying on would send them to whoever the next mail is for.
--
-- MAIL_CLOSED ends a run whatever it was doing. Walking away from the mailbox
-- is the player saying stop, and every call below it would be refused anyway.
local function OnEvent(_, event)
	if not running then
		return
	end
	-- A lock cleared or a bag settled, which is the only news the fill is
	-- waiting on. Ignored while the mail is with the server: the bags move all
	-- through a send and none of it is about the form.
	if event == "ITEM_LOCK_CHANGED" or event == "BAG_UPDATE_DELAYED" then
		if filling then
			Fill()
		end
		return
	end
	if event == "MAIL_SEND_SUCCESS" then
		done = done + 1
		if done >= total then
			Stop(("sent %d %s"):format(total, total == 1 and "mail" or "mails"))
			ns.MailDraft.Clear()
		else
			Begin(done + 1)
		end
	elseif event == "MAIL_FAILED" then
		Stop(("mail %d of %d was refused, the rest is still in your bags"):format(at, total))
	elseif event == "MAIL_CLOSED" then
		Stop("the mailbox closed part way through")
	end
end

events:RegisterEvent("MAIL_SEND_SUCCESS")
events:RegisterEvent("MAIL_FAILED")
events:RegisterEvent("MAIL_CLOSED")
events:SetScript("OnEvent", OnEvent)
