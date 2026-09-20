local ADDON, ns = ...

local Codec = {}
ns.ProfileCodec = Codec

--------------------------------------------------------------------------
-- A profile as a string you can paste
--
-- The string is WK1: and then base64 over an eight digit checksum and the
-- profile written out by Write below. Base64 because an edit box turns a |
-- into an escape and chat mangles anything outside printable ASCII, and the
-- checksum because a paste that lost its last line is the usual way one of
-- these arrives broken.
--
-- Read is a parser rather than loadstring. The text is somebody else's, and
-- loadstring would run whatever they put in it inside this addon. The parser
-- knows four types, a depth limit and nothing else, so the worst a hostile
-- string can do is be refused.
--------------------------------------------------------------------------

local PREFIX = "WK1:"
local DEPTH = 12
local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local DIGIT = {}
for at = 1, #ALPHABET do
	DIGIT[ALPHABET:sub(at, at)] = at - 1
end

-- Adler-32, in arithmetic, because neither client promises the bit library to
-- the harness that tests this.
local function Sum(text)
	local a, b = 1, 0
	for at = 1, #text do
		a = (a + text:byte(at)) % 65521
		b = (b + a) % 65521
	end
	return b * 65536 + a
end

local function Encode(text)
	local out = {}
	for at = 1, #text, 3 do
		local x, y, z = text:byte(at, at + 2)
		local n = x * 65536 + (y or 0) * 256 + (z or 0)
		local d = { math.floor(n / 262144), math.floor(n / 4096) % 64,
			math.floor(n / 64) % 64, n % 64 }
		out[#out + 1] = ALPHABET:sub(d[1] + 1, d[1] + 1)
			.. ALPHABET:sub(d[2] + 1, d[2] + 1)
			.. (y and ALPHABET:sub(d[3] + 1, d[3] + 1) or "=")
			.. (z and ALPHABET:sub(d[4] + 1, d[4] + 1) or "=")
	end
	return table.concat(out)
end

local function Decode(text)
	text = text:gsub("=+$", "")
	if #text % 4 == 1 then
		return nil
	end
	local out = {}
	for at = 1, #text, 4 do
		local n, count = 0, 0
		for each = at, math.min(at + 3, #text) do
			local digit = DIGIT[text:sub(each, each)]
			if not digit then
				return nil
			end
			n, count = n * 64 + digit, count + 1
		end
		n = n * 64 ^ (4 - count)
		local bytes = { math.floor(n / 65536), math.floor(n / 256) % 256, n % 256 }
		out[#out + 1] = string.char(unpack(bytes, 1, count - 1))
	end
	return table.concat(out)
end

-- Keys in one order whatever pairs felt like, so the same profile is always
-- the same string and two can be compared by eye.
local function Before(a, b)
	if type(a) ~= type(b) then
		return type(a) == "number"
	end
	return a < b
end

local function Finite(value)
	return value == value and value ~= math.huge and value ~= -math.huge
end

local Write

local function WriteTable(value, out, depth)
	local keys = {}
	for key in pairs(value) do
		local kind = type(key)
		if kind ~= "string" and not (kind == "number" and Finite(key)) then
			return false
		end
		keys[#keys + 1] = key
	end
	table.sort(keys, Before)
	out[#out + 1] = "t"
	for _, key in ipairs(keys) do
		if not Write(key, out, depth + 1) or not Write(value[key], out, depth + 1) then
			return false
		end
	end
	out[#out + 1] = "e"
	return true
end

function Write(value, out, depth)
	local kind = type(value)
	if depth > DEPTH then
		return false
	elseif kind == "string" then
		out[#out + 1] = "s" .. #value .. ":" .. value
	elseif kind == "number" and Finite(value) then
		out[#out + 1] = ("n%.17g;"):format(value)
	elseif kind == "boolean" then
		out[#out + 1] = value and "T" or "F"
	elseif kind == "table" then
		return WriteTable(value, out, depth)
	else
		return false
	end
	return true
end

local Read

local function ReadTable(text, at, depth)
	local value = {}
	while text:sub(at, at) ~= "e" do
		local key, held
		key, at = Read(text, at, depth + 1)
		if key == nil or type(key) == "boolean" or type(key) == "table" then
			return nil
		end
		held, at = Read(text, at, depth + 1)
		if held == nil then
			return nil
		end
		value[key] = held
	end
	return value, at + 1
end

-- One value starting at `at`, and where the next one starts. Nil on anything
-- it does not recognise, which includes running off the end.
function Read(text, at, depth)
	if not at or depth > DEPTH then
		return nil
	end
	local tag = text:sub(at, at)
	if tag == "T" or tag == "F" then
		return tag == "T", at + 1
	elseif tag == "s" then
		local _, stop, length = text:find("^(%d+):", at + 1)
		length = tonumber(length)
		if not length or stop + length > #text then
			return nil
		end
		return text:sub(stop + 1, stop + length), stop + length + 1
	elseif tag == "n" then
		local _, stop, digits = text:find("^([^;]+);", at + 1)
		local number = tonumber(digits)
		if not number or not Finite(number) then
			return nil
		end
		return number, stop + 1
	elseif tag == "t" then
		return ReadTable(text, at + 1, depth)
	end
	return nil
end

-- The string for one value, or nil where the value holds something a string
-- cannot carry: a function, a frame, a key that is a table.
function Codec.Write(value)
	local out = {}
	if not Write(value, out, 0) then
		return nil
	end
	local body = table.concat(out)
	return PREFIX .. Encode(("%08x"):format(Sum(body)) .. body)
end

-- The value back, or nil and why. Spaces and line breaks are dropped first,
-- because a string that went through a chat window or a forum post comes back
-- wrapped.
function Codec.Read(text)
	if type(text) ~= "string" then
		return nil, "nothing was pasted"
	end
	text = text:gsub("%s", "")
	if text == "" then
		return nil, "nothing was pasted"
	end
	if text:sub(1, #PREFIX) ~= PREFIX then
		return nil, "that is not a WiggleUI profile string"
	end
	local raw = Decode(text:sub(#PREFIX + 1))
	local sum = raw and tonumber(raw:sub(1, 8), 16)
	local body = raw and raw:sub(9)
	if not sum or sum ~= Sum(body) then
		return nil, "the string is damaged or cut short, copy it again"
	end
	local value, stop = Read(body, 1, 0)
	if value == nil or stop ~= #body + 1 then
		return nil, "the string is damaged or cut short, copy it again"
	end
	return value
end
