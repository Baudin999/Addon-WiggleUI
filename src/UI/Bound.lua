local ADDON, ns = ...

local UI = ns.UI
local Bound = {}
UI.Bound = Bound

--------------------------------------------------------------------------
-- A key held on a button through the override layer
--
-- Every key this addon takes is an override binding and never a real one.
-- SetBindingClick would write the key into the live binding set, and the next
-- SaveBindings, which the client's own Key Bindings panel calls when you press
-- Okay, would make that permanent and lose whatever the player had on the key.
-- An override sits on top of the set instead: the key it shadows comes straight
-- back the moment the override goes, and no binding file is touched.
--
-- Taking one is five steps and every file that took one wrote all five: refuse
-- in combat, refuse a bare mouse button, let go of the key so the layer can be
-- read without our own click in the way, write down what the key was carrying,
-- take it and read the layer back. The dungeon log's key and the frame
-- report's key were the same file with the names changed, the target switch and
-- the ad hoc bars carried the same Bind line for line, the charge key carried
-- it without the bare button check, and seven files declared their own copy of
-- the two mouse buttons nobody may take. check.sh refuses the copies now.
--------------------------------------------------------------------------

-- The two the binding system must never lose: a bare mouse button binding eats
-- plain targeting and the camera drag.
local BARE = { BUTTON1 = true, BUTTON2 = true }

function Bound.Bare(key)
	return BARE[key] == true
end

-- Why `key` may not be taken at all, or nil. The panel's key field and every
-- slash word ask the same question and say the same sentence.
function Bound.Refusal(key)
	if BARE[key] then
		return ("%s belongs to targeting and the camera. Hold a modifier."):format(key)
	end
	return nil
end

-- What the binding set holds for `key` under every override on it, or nil for
-- nothing. Read this way round rather than GetBindingKey walked for the key,
-- because a key with an override on it stops answering to its command from
-- that side, and every key this is asked about has one.
function Bound.Under(key)
	if type(GetBindingAction) ~= "function" or type(key) ~= "string" or key == "" then
		return nil
	end
	local ok, action = pcall(GetBindingAction, key)
	if ok and type(action) == "string" and action ~= "" then
		return action
	end
	return nil
end

-- Whether the override layer holds `key` as a `click` on the button called
-- `name`. Read back rather than believed, because a client that takes the call
-- and does nothing with it leaves no other trace. Nil where the question could
-- not be asked.
--
-- A blank layer answers `blank`. Nil is the default, for a readback that may
-- come before the client has answered at all, which at PLAYER_LOGIN it may
-- not have. A caller that has just written the key passes false, because a
-- blank layer then means the key was not taken.
function Bound.Reads(key, name, click, blank)
	if type(GetBindingAction) ~= "function" then
		return nil
	end
	local ok, action = pcall(GetBindingAction, key, true)
	if not ok or type(action) ~= "string" then
		return nil
	end
	if action == "" then
		return blank
	end
	return action == ("CLICK %s:%s"):format(name, click or "LeftButton")
end

-- Every override this addon writes and clears goes through the two below. Four
-- files wrapped the calls in their own pcall and four called them bare, and
-- none of them asked whether the button the key presses fires on an edge the
-- key reaches. check.sh refuses the client calls anywhere else now.

-- Whether this client has an override layer at all.
function Bound.Layer()
	return type(SetOverrideBindingClick) == "function" and type(ClearOverrideBindings) == "function"
end

-- Put `key` on the override layer as a `click` on the button called `name`,
-- owned by `owner`. Returns whether the client took the call, and the layer
-- read back (nil where it could not be asked).
--
-- Refused for a button UI/Press.lua did not build. Every key that went dead in
-- this addon went dead on the edge: a button that registered one edge while
-- the key was dispatched on the other binds, reads back, and does nothing.
-- Press writes the registration and the attribute from one argument and
-- records it, so a button without that record is a button nobody can promise
-- the key reaches.
--
-- pcalled because the call is refused under lockdown and because nothing here
-- proves it takes a mouse button name on 2.5.6.
function Bound.Hold(owner, key, name, click)
	if not Bound.Layer() or type(key) ~= "string" or key == "" then
		return false
	end
	local target = _G[name]
	if not (target and target.wkEdge) then
		return false
	end
	click = click or "LeftButton"
	if not pcall(SetOverrideBindingClick, owner, true, key, name, click) then
		return false
	end
	return true, Bound.Reads(key, name, click)
end

-- Every override `owner` holds, gone.
function Bound.Drop(owner)
	if Bound.Layer() then
		pcall(ClearOverrideBindings, owner)
	end
end

-- The five steps. `put(key, displaced)` stores the key and applies it, and is
-- called twice: once with "" to let go, and once with the key and what it was
-- carrying. `reads(key)` is the readback, or nil for a key that is not held
-- by a plain override. Returns the binding the key was carrying, "" for none,
-- or nil and the sentence to print.
function Bound.Take(key, put, reads)
	if InCombatLockdown() then
		return nil, "keys cannot be rebound in combat."
	end
	key = key or ""
	local refused = Bound.Refusal(key)
	if refused then
		return nil, refused
	end
	put("")
	local displaced = Bound.Under(key) or ""
	put(key, displaced)
	if key ~= "" and reads and reads(key) == false then
		return nil, ("this client would not take %s."):format(key)
	end
	return displaced
end

-- What a status line says about one key. `off` is why the key is not held
-- while its part is off, or nil where it is on.
function Bound.Describe(key, reads, displaced, off)
	if key == "" then
		return "unbound"
	end
	if off then
		return ("%s (%s, so the key is not held)"):format(key, off)
	end
	if reads == false then
		return key .. " (the client did not take it)"
	end
	if displaced and displaced ~= "" then
		return ("%s, shadowing %s"):format(key, displaced)
	end
	return key
end

-- One key held on the button called spec.name. The key lives in the part's
-- own settings, so the part hands over how to read and write it.
--
--   spec.store    key() answers the key held now; save(key, displaced) stores
--                 it, and the binding it shadows when there is one, which the
--                 let-go step does not pass; shadowed() answers that binding.
--                 ns.KeySetting(field) builds one over a saved field.
--   spec.button   the button, or nil until it is built; set `.button` then
--   spec.wanted   answers whether the key is held right now, where a switch
--                 can turn the part off without unbinding it
--   spec.off      what Describe says while `wanted` answers false
--   spec.write    writes the key itself, for a key the layer does not hold
--                 as a plain override; nothing is read back then
--   spec.absent   the sentence Bind says while there is no button
--
-- The holder carries Apply, Bind, Describe and Reads. Apply is held to the end
-- of a fight and is taken again every time the client rebuilds its binding
-- set, which throws every override away. See ns.Rebind in Core/Core.lua.
function Bound.Key(spec)
	local hold = { button = spec.button }
	local name = spec.name

	local function Key()
		return spec.store.key() or ""
	end

	local function Wanted()
		return not spec.wanted or spec.wanted()
	end

	function hold.Apply()
		local button = hold.button
		if not button or not Bound.Layer() then
			return false
		end
		if ns.Lockdown.Held(hold.Apply) then
			return false
		end
		local key = Key()
		if spec.write then
			spec.write(button, key)
			return true
		end
		Bound.Drop(button)
		if key ~= "" and Wanted() then
			Bound.Hold(button, key, name)
		end
		return true
	end

	function hold.Reads(key)
		if spec.write then
			return nil
		end
		return Bound.Reads(key, name, "LeftButton", false)
	end

	function hold.Bind(key)
		if not hold.button then
			return nil, spec.absent and spec.absent() or "there is nothing here for a key to press."
		end
		return Bound.Take(key, function(taken, displaced)
			spec.store.save(taken, displaced)
			hold.Apply()
		end, hold.Reads)
	end

	function hold.Describe()
		local key = Key()
		return Bound.Describe(key, key ~= "" and hold.Reads(key),
			spec.store.shadowed(), not Wanted() and spec.off or nil)
	end

	ns.Rebind(hold.Apply)
	return hold
end

--------------------------------------------------------------------------
-- Several keys on one button
--
-- The marks and the hover list each put a list of keys on one button, telling
-- the keys apart by the click name the binding hands over. Both files ran the
-- same loop with the same four locals: which keys are up, whether any is,
-- whether the readback has ever answered, and whether the one warning has
-- been said. This is that loop.
--
--   spec.button   the button every key presses, built by UI/Press.lua
--   spec.name     its global name
--   spec.list()   the keys wanted now, as { id, key, click } in order; `id`
--                 is what Holds is asked with
--   spec.wanted() whether the part is on at all
--   spec.clear()  runs after the old keys go and before the new ones
--   spec.put(one) runs before one key goes up, to write what it presses
--   spec.told(one, taken, reads)
--                 after each: taken is nil for a key nobody may take, false
--                 for one the client refused, true for one it took
--   spec.log      a debug log taking a format, or nil
--   spec.idle     what the log says while `wanted` answers false
--   spec.refused  said once, the first time the client refuses a key
--   spec.ignored  said once, when the client takes the keys and holds none
--
-- Apply returns false when combat held it back, and runs again at every
-- binding rebuild, see ns.Rebind in Core/Core.lua.
--------------------------------------------------------------------------

function Bound.Keys(spec)
	local keys = {}
	local held = {}   -- id -> the key on the override layer
	local heldAny     -- true while at least one is up
	local proven      -- nil until the readback has answered once
	local warned

	local function Log(...)
		if spec.log then
			spec.log(...)
		end
	end

	local function Warn(sentence)
		if not warned then
			warned = true
			ns.Print(sentence)
		end
	end

	function keys.Apply()
		if ns.Lockdown.Held(keys.Apply) then
			Log("in combat, so the keys are held until the fight ends")
			return false
		end
		Bound.Drop(spec.button)
		if spec.clear then
			spec.clear()
		end
		held, heldAny = {}, false
		if not spec.wanted() then
			if spec.idle then
				Log(spec.idle)
			end
			return true
		end
		for _, one in ipairs(spec.list()) do
			local key = one.key
			if type(key) ~= "string" or key == "" or Bound.Bare(key) then
				if spec.told then
					spec.told(one, nil)
				end
			else
				if spec.put then
					spec.put(one)
				end
				local taken, reads = Bound.Hold(spec.button, key, spec.name, one.click)
				if taken then
					held[one.id] = key
					heldAny = true
					if reads ~= nil then
						proven = reads
					end
				else
					Warn(spec.refused)
				end
				if spec.told then
					spec.told(one, taken, reads)
				end
			end
		end
		if heldAny and proven == false then
			Warn(spec.ignored)
		end
		return true
	end

	-- The key `id` holds on the layer, or nil.
	function keys.Holds(id)
		return held[id]
	end

	function keys.Active()
		return heldAny == true
	end

	-- What is wrong with the keys in the words a status line uses, or nil.
	-- Always what the layer says, never what the part meant to set.
	function keys.Trouble()
		if ns.Lockdown.Owed(keys.Apply) then
			return "waiting for combat to drop"
		end
		if not heldAny then
			return nil
		end
		if proven == nil then
			return "unproven"
		end
		if not proven then
			return "the client did not take them"
		end
		return nil
	end

	ns.Rebind(keys.Apply)
	return keys
end
