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
		if not button or type(SetOverrideBindingClick) ~= "function" then
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
		ClearOverrideBindings(button)
		if key ~= "" and Wanted() then
			SetOverrideBindingClick(button, true, key, name, "LeftButton")
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
