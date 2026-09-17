-- WarriorKitDB.perfLog as a table, oldest minute first.
--
-- The log is a ring of parallel columns, which is the right shape to write from
-- a tick and the wrong one to read. This turns it into one tab separated row a
-- minute, in the order the minutes happened, with a column per addon on the end.
--
--     lua5.1 scripts/perflog.lua <WTF/Account/NAME/SavedVariables/WarriorKit.lua>
--     lua5.1 scripts/perflog.lua <file> | column -t -s "$(printf '\t')"
--
-- A session is a run of rows whose `up` counts 1, 2, 3. A row where it goes back
-- to 1 is the minute after a reload.
--
-- `off` is near the front because it is what the rest of the row is grouped by
-- while a sweep is running: the feature Perf/Sweep.lua had switched off for the
-- whole of that minute, `base` for a baseline step, `-` with no sweep running,
-- and `mixed` for the one minute a step change had to land in the middle of.

local path = arg[1]
if not path then
	io.stderr:write("usage: lua5.1 scripts/perflog.lua <SavedVariables/WarriorKit.lua>\n")
	os.exit(2)
end
dofile(path)

local log = WarriorKitDB and WarriorKitDB.perfLog
if type(log) ~= "table" or type(log.at) ~= "table" then
	io.stderr:write("no perfLog in " .. path .. "\n")
	os.exit(1)
end

local columns = { "at", "up", "off", "frames", "avg", "worst", "over12", "over20", "over50",
	"beat", "slowMs", "slowOurs", "slowKey", "slowEvents", "slowAlloc", "slowSweeps",
	"ours", "lua", "events", "heap", "floor", "alloc", "freed", "sweeps",
	"oursKB", "oursAlloc", "allocKey", "allocKB", "addonsKB",
	"qQueued", "qPins", "qMapPins", "topEvent", "topEvents", "nextEvent", "nextEvents",
	"grower", "grew", "readMs", "uiFrames", "uiShown", "uiRegions", "uiTicking" }

local addons = {}
for name in pairs(log.addons or {}) do
	addons[#addons + 1] = name
end
table.sort(addons)

local function cell(value)
	if value == nil or value == "" then
		return "-"
	end
	return tostring(value)
end

local header = { "time" }
for index = 2, #columns do
	header[#header + 1] = columns[index]
end
for index = 1, #addons do
	header[#header + 1] = addons[index]
end
print(table.concat(header, "\t"))

local size, head, filled = log.size, log.head, log.filled
for step = 1, filled do
	local row = (head - filled + step - 1) % size + 1
	local out = { os.date("%m-%d %H:%M", log.at[row]) }
	for index = 2, #columns do
		local column = log[columns[index]]
		out[#out + 1] = cell(column and column[row])
	end
	for index = 1, #addons do
		out[#out + 1] = cell(log.addons[addons[index]][row])
	end
	print(table.concat(out, "\t"))
end
