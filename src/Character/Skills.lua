local ADDON, ns = ...

local Skills = {}
ns.CharSkills = Skills

--------------------------------------------------------------------------
-- Your skills, as bars rather than as a list of numbers
--
-- The client's own skill tab is right about what to show and wrong about how.
-- Every line is a name, a bar and two numbers, and the two numbers are the only
-- thing on the line that says anything, because the bar is the same length on
-- a weapon skill you have capped and a profession you started this morning.
-- What you actually want to know is which of them are behind, and that is one
-- comparison the client never makes.
--
-- So every row here carries how far along it is as a fraction, and a weapon
-- skill under the cap for your level carries a sentence saying what that is
-- costing you. It is the same number the hit and miss page is computed from,
-- said in the place you would go looking for it.
--
-- **A weapon skill is told from a profession by what it caps at, not by what
-- its header is called.** Every header on this page is a localised string and
-- matching on one is how an addon works in English and lists nothing at all in
-- German. A weapon skill caps at five times your level and cannot be
-- abandoned; a profession caps at a multiple of seventy-five and can. The two
-- tests together are wrong only for a character at exactly level fifteen with a
-- profession at its first cap, which draws one extra sentence and nothing else.
--
-- **Reading the list expands the client's headers.** There is no way to
-- enumerate the skills under a collapsed header, so they are expanded, once,
-- before the first read. That is a write to the client's own state and it is
-- worth saying out loud: the only thing that reads it back is the client's own
-- skill frame, which this part puts in the attic.
--------------------------------------------------------------------------

local expanded = false

local function Ask(name, ...)
	local call = _G[name]
	if type(call) ~= "function" then
		return nil
	end
	local ok, a, b, c, d, e, f, g, h = pcall(call, ...)
	if not ok then
		return nil
	end
	return a, b, c, d, e, f, g, h
end

-- Every header open, once per session. Zero is the client's own word for all of
-- them, and a client that will not take it is a client where whatever was
-- already open is what gets listed, which is a shorter page rather than a
-- broken one.
local function Expand()
	if expanded then
		return
	end
	expanded = true
	Ask("ExpandSkillHeader", 0)
end

-- What kind of line this is, from what it caps at.
local function Kind(maximum, abandonable, level)
	if maximum == nil or maximum == 0 then
		return "other"
	end
	if abandonable then
		return "profession"
	end
	if maximum == level * 5 then
		return "weapon"
	end
	return "other"
end

-- Whether a line is a trade, which is what the sheet's standard tab keeps and
-- its skills tab does without.
--
-- Told apart by the same arithmetic Kind uses and for the same reason: every
-- header on this page is a localised string, and an addon that picked its
-- professions out by matching the word "Professions" works in English and finds
-- nothing at all in German. A primary trade can be abandoned and that settles
-- it. A secondary one cannot, so what is left is the shape of its cap: cooking,
-- first aid and fishing cap at a multiple of seventy-five and sit somewhere
-- under it. Languages cap at three hundred as well and fail the second half,
-- because a language is known or it is not and is always at its own cap.
-- Armour proficiencies cap at one, and a weapon skill is already gone by then.
--
-- What it gets wrong is a character who has capped every secondary trade they
-- have and taken no primary one, which draws cooking and first aid on the
-- skills tab rather than the standard one. That is one press, once, and the
-- alternative is a table of trade names in twelve languages.
local function Trade(kind, rank, maximum)
	if kind == "profession" then
		return true
	end
	if kind ~= "other" or not maximum or maximum <= 0 then
		return false
	end
	return maximum % 75 == 0 and rank < maximum
end

-- The sentence under a weapon skill, and nothing at all for one at the cap.
--
-- The number is the same one Stats.MeleeMiss is built on, asked the other way
-- round: what the shortfall adds rather than what the total comes to. Written
-- here rather than fetched from that file because what belongs to both is the
-- curve, and the curve is four constants in one place.
local function Costing(rank, maximum)
	local short = maximum - rank
	if short <= 0 then
		return nil
	end
	local base = ns.CharStats.MeleeMiss(3)
	local now = base + short * 0.6
	return ("%d points short. Against a boss that is %.2f%% to miss rather than %.2f%%.")
		:format(short, now, base)
end

--------------------------------------------------------------------------

-- Every skill line, grouped under the client's own headers, in the shape the
-- readout pane draws: a title and a list of rows, each row a label, a value, an
-- optional sentence and an optional fraction that becomes a bar.
--
-- A group carries whether it holds trades, which is the one thing about it that
-- is not on the page: the sheet's standard tab draws the trade groups beside
-- your attributes and its skills tab draws the rest. The flag is on the group
-- rather than the row because the client already grouped them and a header
-- split down the middle would be the same word printed on two tabs.
function Skills.Groups()
	Expand()
	local level = Ask("UnitLevel", "player") or 1
	local count = Ask("GetNumSkillLines") or 0
	local groups, current = {}, nil

	for index = 1, count do
		local name, header, _, rank, temporary, modifier, maximum, abandonable =
			Ask("GetSkillLineInfo", index)
		if type(name) == "string" and name ~= "" then
			if header then
				current = { title = name, rows = {} }
				groups[#groups + 1] = current
			elseif current then
				local total = (rank or 0) + (temporary or 0) + (modifier or 0)
				local kind = Kind(maximum, abandonable, level)
				current.trade = current.trade or Trade(kind, total, maximum)
				current.rows[#current.rows + 1] = {
					label = name,
					value = ("%d of %d"):format(total, maximum or total),
					fraction = (maximum and maximum > 0) and (total / maximum) or nil,
					note = kind == "weapon" and Costing(total, maximum) or nil,
				}
			end
		end
	end

	-- A header the client listed with nothing under it is a header the page
	-- would draw as a title over air.
	local kept = {}
	for index = 1, #groups do
		if #groups[index].rows > 0 then
			kept[#kept + 1] = groups[index]
		end
	end
	return kept
end

-- How many weapon skills are under the cap for your level, and by how much at
-- the worst. This is the one line the status word and the page footer both
-- want, and it is the only question about this page that is worth asking
-- without opening it.
function Skills.Behind()
	Expand()
	local level = Ask("UnitLevel", "player") or 1
	local count = Ask("GetNumSkillLines") or 0
	local behind, worst = 0, 0

	for index = 1, count do
		local _, header, _, rank, temporary, modifier, maximum, abandonable =
			Ask("GetSkillLineInfo", index)
		if not header and Kind(maximum, abandonable, level) == "weapon" then
			local short = maximum - ((rank or 0) + (temporary or 0) + (modifier or 0))
			if short > 0 then
				behind = behind + 1
				worst = math.max(worst, short)
			end
		end
	end
	return behind, worst
end

--------------------------------------------------------------------------
-- The skill a thing in the world asks for
--
-- Point at a vein and the client says "Requires Mining 125", in red if you are
-- short of it. What it does not say is where you are: 118 and two nodes from
-- it, or 30 and a zone away. That number is on this page and nowhere near the
-- vein, so the world hover carries it as a bar, the same bar the skills tab
-- draws.
--
-- Matched on the skill's own name in the client's own lines, which are in the
-- same language the skill list is. No table of which objects want which skill:
-- the client already wrote the answer on the tooltip, and a fishing bobber, a
-- locked chest and a herb all name theirs.
--------------------------------------------------------------------------

-- Whether any of the client's lines names this skill.
local function Named(lines, name)
	for index = 1, #lines do
		local left = lines[index][1]
		if type(left) == "string" and left:find(name, 1, true) then
			return true
		end
	end
	return false
end

-- A bar for every skill of yours the client's lines about a thing name.
function Skills.Asked(lines)
	if type(lines) ~= "table" or #lines < 1 then
		return nil
	end
	Expand()
	local fill = ns.Unit.Color.progress.experience
	local count = Ask("GetNumSkillLines") or 0
	local rows
	for index = 1, count do
		local name, header, _, rank, temporary, modifier, maximum = Ask("GetSkillLineInfo", index)
		if not header and type(name) == "string" and name ~= ""
			and maximum and maximum > 0 and Named(lines, name) then
			local total = (rank or 0) + (temporary or 0) + (modifier or 0)
			rows = rows or {}
			rows[#rows + 1] = { name, ("%d / %d"):format(total, maximum),
				bar = total / maximum, fill = fill }
		end
	end
	return rows
end

ns.Tip.Source({
	name = "your skill in it",
	kind = "object",
	band = "body",
	order = 30,
	fill = function(subject)
		return Skills.Asked(subject.scan)
	end,
})

function Skills.Describe()
	local count = Ask("GetNumSkillLines")
	if not count then
		return "this client will not list them"
	end
	local behind, worst = Skills.Behind()
	if behind == 0 then
		return "every weapon skill at the cap for your level"
	end
	return ("%d weapon skill%s behind, the worst by %d points")
		:format(behind, behind == 1 and "" or "s", worst)
end
