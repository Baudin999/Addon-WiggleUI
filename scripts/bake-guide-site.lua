-- Renders docs/guide into the static site GitHub Pages serves, and writes the
-- stylesheet out of the addon's own palettes.
--
-- Driven by ./scripts/bake-guide-site.sh, which finds the paths and does the
-- pictures. This half does the markdown and the colours.
--
--     lua5.1 scripts/bake-guide-site.lua <addon root> <guide dir> <out dir>
--
-- The colours are not typed here. The whole addon is loaded under the
-- harness's stub client, the same way scripts/bake-defaults.lua loads it, and
-- ns.Palettes and ns.UI.Metric are read off the live tables. A hex triple
-- written into a stylesheet by hand is a second palette, a folder away from
-- the first, wrong the day somebody edits one of the eight.
--
-- The markdown is a closed subset and the parser refuses what it does not
-- know, with the file and the line. A renderer that skips an unknown line
-- drops a paragraph out of the published page and says nothing, which is the
-- one failure a docs bake must not have.

local ROOT, GUIDE, OUT = ...
assert(ROOT and GUIDE and OUT,
	"usage: bake-guide-site.lua <addon root> <guide dir> <out dir>")

local here = arg[0]:match("^(.*)[/\\]") or "."

--------------------------------------------------------------------------
-- The addon, for its palettes
--------------------------------------------------------------------------

local function harness(path)
	return assert(loadfile(here .. "/harness/" .. path))
end

local ns = {}
do
	local H = harness("client/init.lua")("WARRIOR", harness)
	H.ns, H.carry = ns, {}
	for line in io.lines(ROOT .. "/WiggleUI.toc") do
		line = line:gsub("\r", ""):gsub("\\", "/")
		if line:match("^[A-Za-z].*%.lua$") then
			H.loading.file = line
			assert(loadfile(ROOT .. "/" .. line))("WiggleUI", ns)
			H.loading.file = "runtime"
		end
	end
end

assert(type(ns.Palettes) == "table", "the addon loaded and declared no palettes")
assert(type(ns.UI) == "table" and type(ns.UI.Metric) == "table",
	"the addon loaded and declared no UI.Metric")

--------------------------------------------------------------------------
-- Small things
--------------------------------------------------------------------------

local function read(path)
	local file = assert(io.open(path, "r"), "cannot read " .. path)
	local text = file:read("*a")
	file:close()
	return text
end

local function write(path, text)
	local file = assert(io.open(path, "w"), "cannot write " .. path)
	file:write(text)
	file:close()
end

local function sorted(t)
	local keys = {}
	for key in pairs(t) do keys[#keys + 1] = key end
	table.sort(keys)
	return keys
end

-- GitHub's own anchor rule, because the anchors in the guide were written
-- against GitHub's rendering and two of them are already linked.
local function slug(text)
	return (text:lower()
		:gsub("`", "")
		:gsub("[^%w%s%-]", "")
		:gsub("%s+", "-"))
end

local function escape(text)
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

--------------------------------------------------------------------------
-- The pages, in the order the index links them
--
-- The same rule bake-guide-nav.sh follows and for the same reason: the index
-- is the list somebody already edits to add a page, so a second list here
-- would be a list that can disagree with it.
--------------------------------------------------------------------------

local index = read(GUIDE .. "/README.md")

local order, seen = {}, {}
for name in index:gmatch("%]%((%a[%w%-]*%.md)%)") do
	if not seen[name] then
		seen[name] = true
		order[#order + 1] = name
	end
end
assert(#order > 0, "docs/guide/README.md links no pages")

local titles = {}
for _, name in ipairs(order) do
	local heading = read(GUIDE .. "/" .. name):match("^#%s+([^\n]+)")
	assert(heading, GUIDE .. "/" .. name .. " has no '# ' heading")
	titles[name] = heading
end

--------------------------------------------------------------------------
-- Links
--
-- Every target in the guide is one of five shapes and the sixth is a mistake.
-- An unknown target is refused rather than passed through, because a relative
-- link to a .md file works on GitHub and 404s on the site, which is exactly
-- the kind of break nobody clicks until a reader does.
--------------------------------------------------------------------------

local SHOTS = "%.%./%.%./assets/docs%-screenshots/([%w%-]+)%.png"

local function href(target, depth)
	local up = depth == 0 and "" or "../"

	if target:match("^https?://") or target:match("^mailto:") then
		return target, true
	end
	if target:match("^#") then
		return target, false
	end

	local shot = target:match("^" .. SHOTS .. "$")
	if shot then
		return up .. "img/" .. shot .. ".webp", false
	end

	local page, anchor = target:match("^([%w%-]+%.md)(#?[%w%-]*)$")
	if page == "README.md" then
		return up .. "index.html" .. anchor, false
	end
	if page and titles[page] then
		local file = page:gsub("%.md$", ".html")
		return (depth == 0 and "guide/" or "") .. file .. anchor, false
	end

	error(("unknown link target %q"):format(target), 0)
end

--------------------------------------------------------------------------
-- Inline markdown
--
-- Code spans come out first and go back last, so a backtick run containing a
-- star is not read as emphasis. Everything is escaped before any of it, which
-- is safe because none of the three patterns below uses &, < or >.
--------------------------------------------------------------------------

local function inline(text, depth, where)
	local spans = {}
	text = escape(text):gsub("`([^`]*)`", function(code)
		spans[#spans + 1] = "<code>" .. code .. "</code>"
		return "\1" .. #spans .. "\2"
	end)

	text = text:gsub("%[([^%]]*)%]%(([^%)]*)%)", function(label, target)
		local ok, link, external = pcall(href, target, depth)
		if not ok then
			error(("%s: %s"):format(where, link), 0)
		end
		if external then
			return ('<a href="%s" target="_blank" rel="noopener">%s</a>'):format(link, label)
		end
		return ('<a href="%s">%s</a>'):format(link, label)
	end)

	text = text:gsub("%*%*([^%*]+)%*%*", "<strong>%1</strong>")

	local star = text:match("%*")
	if star then
		error(("%s: a star this bake does not read: %s"):format(where, text), 0)
	end

	return (text:gsub("\1(%d+)\2", function(n) return spans[tonumber(n)] end))
end

--------------------------------------------------------------------------
-- Block markdown
--
-- Line driven, one block at a time, and every start it does not know is an
-- error naming the file and the line.
--------------------------------------------------------------------------

-- The width and height a picture is drawn at, read out of the PNG's own
-- header. Written onto the tag so the browser keeps the room before the
-- picture arrives and the paragraph under it does not jump when it does.
-- WIDE is the same stop bake-guide-site.sh gives ImageMagick, so the two
-- agree on what a resized picture comes out as.
local WIDE = 1600

local function dimensions(path)
	local file = io.open(path, "rb")
	if not file then return nil end
	local head = file:read(24)
	file:close()
	if not head or #head < 24 or head:sub(1, 8) ~= "\137PNG\r\n\26\n"
		or head:sub(13, 16) ~= "IHDR" then
		return nil
	end
	local function be(at)
		local a, b, c, d = head:byte(at, at + 3)
		return ((a * 256 + b) * 256 + c) * 256 + d
	end
	local w, h = be(17), be(21)
	if w > WIDE then
		h = math.floor(h * WIDE / w + 0.5)
		w = WIDE
	end
	return w, h
end

-- The author's own notes to himself, which are in the guide on purpose and are
-- not for a reader. They stay in the markdown and go into the HTML as a
-- comment, so the published page does not carry them and nothing is lost.
local NOTE = "^%*%*Screenshot wanted:%*%*"

local function page(name, source, depth)
	local body = source:gsub("\n<!%-%- nav %-%->.*$", "\n")
	local lines = {}
	for line in (body .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = line:gsub("%s+$", "")
	end

	local notes = 0
	local title, sections = nil, {}
	local current

	local function where(at) return ("%s:%d"):format(name, at) end
	local function text(at, raw) return inline(raw, depth, where(at)) end

	-- Everything a section's search entry is built from: the headings and the
	-- prose under them, with the markup taken back off.
	local function collect(raw)
		if current then current.text[#current.text + 1] = raw end
	end

	-- One pass over a run of lines. A list item's body goes back through here
	-- rather than being read as one line of text, which is what a numbered
	-- item with a picture under it actually is. `offset` is where this run
	-- starts in the file, so an error inside an item still names the line
	-- somebody has to go and edit.
	local function render(rows, offset)
		local out = {}
		local function put(html) out[#out + 1] = html end

		local i, n = 1, #rows
		while i <= n do
			local line = rows[i]
			local at = offset + i

			if line == "" then
				i = i + 1

			elseif line:match("^# ") then
				assert(not title, where(at) .. ": a second '# ' heading")
				title = line:match("^# (.+)$")
				put("<h1>" .. text(at, title) .. "</h1>")
				-- The page's own opening, so the prose above the first '## '
				-- is searchable. Six of the thirteen pages have no '## ' at
				-- all and without this they were in the index as nothing.
				current = { heading = title, text = {} }
				sections[#sections + 1] = current
				i = i + 1

			elseif line:match("^## ") then
				local heading = line:match("^## (.+)$")
				local id = slug(heading)
				current = { id = id, heading = heading, text = {} }
				sections[#sections + 1] = current
				put(('<h2 id="%s"><a class="anchor" href="#%s">%s</a></h2>')
					:format(id, id, text(at, heading)))
				i = i + 1

			elseif line:match("^###") then
				error(where(at) .. ": a heading deeper than '## ', which this bake does not draw", 0)

			elseif line:match("^```") then
				error(where(at) .. ": a fenced code block; the guide indents its blocks by four", 0)

			elseif line:match("^!%[") then
				local alt, target = line:match("^!%[([^%]]*)%]%(([^%)]+)%)$")
				assert(alt and target, where(at) .. ": an image line this bake does not read")
				local src = href(target, depth)
				local w, h = dimensions(GUIDE .. "/" .. target)
				local size = w and (' width="%d" height="%d"'):format(w, h) or ""
				put(('<figure><a href="%s"><img src="%s" alt="%s"%s loading="lazy" decoding="async"></a>'
					.. '<figcaption>%s</figcaption></figure>')
					:format(src, src, escape(alt), size, text(at, alt)))
				collect(alt)
				i = i + 1

			elseif line:match("^>") then
				local quote = {}
				while i <= n and rows[i]:match("^>") do
					quote[#quote + 1] = rows[i]:gsub("^>%s?", "")
					i = i + 1
				end
				local joined = table.concat(quote, " ")
				if joined:match(NOTE) then
					notes = notes + 1
					put("<!-- " .. joined:gsub("%-%-", "- -") .. " -->")
				else
					put("<blockquote><p>" .. text(at, joined) .. "</p></blockquote>")
					collect(joined)
				end

			elseif line:match("^|") then
				local start = i
				local table_rows = {}
				while i <= n and rows[i]:match("^|") do
					table_rows[#table_rows + 1] = rows[i]
					i = i + 1
				end
				local html = { "<table>" }
				for k, row in ipairs(table_rows) do
					local cells = {}
					for cell in row:gmatch("|([^|]+)") do
						cells[#cells + 1] = cell:match("^%s*(.-)%s*$")
					end
					if k == 2 then
						for _, cell in ipairs(cells) do
							assert(cell:match("^:?%-%-%-+:?$"),
								where(offset + start + 1) .. ": a table rule this bake does not read")
						end
					else
						local tag = k == 1 and "th" or "td"
						local tr = { k == 1 and "<thead><tr>" or "<tr>" }
						for _, cell in ipairs(cells) do
							tr[#tr + 1] = ("<%s>%s</%s>"):format(tag, text(offset + start + k - 1, cell), tag)
						end
						tr[#tr + 1] = k == 1 and "</tr></thead><tbody>" or "</tr>"
						html[#html + 1] = table.concat(tr)
						collect((row:gsub("|", " ")))
					end
				end
				html[#html + 1] = "</tbody></table>"
				put(table.concat(html))

			elseif line:match("^[ \t]") then
				-- An indented block. Blank lines inside it are kept, blank
				-- lines after it are not, so a two part command table stays
				-- one block and a rerun cannot grow it.
				local block = {}
				while i <= n and (rows[i] == "" or rows[i]:match("^[ \t]")) do
					block[#block + 1] = rows[i]
					i = i + 1
				end
				for k = #block, 1, -1 do
					if block[k] == "" then block[k] = nil else break end
				end
				local code = {}
				for k, row in ipairs(block) do
					code[k] = escape((row:gsub("^    ", ""):gsub("^\t", "")))
				end
				put("<pre><code>" .. table.concat(code, "\n") .. "</code></pre>")
				collect(table.concat(block, " "))

			elseif line:match("^%- ") or line:match("^%d+%. ") then
				local ordered = line:match("^%d") ~= nil
				local items = {}

				while i <= n do
					-- A blank line between two items belongs to the list.
					local k = i
					while k <= n and rows[k] == "" do k = k + 1 end
					if k > n then break end
					local marker = rows[k]:match("^%- ") or rows[k]:match("^%d+%. ")
					if not marker then break end

					i = k
					local start = i
					local pad = "^" .. string.rep(" ", #marker)
					local item = { rows[i]:sub(#marker + 1) }
					i = i + 1

					-- The item runs to the first line that is neither blank
					-- nor indented under its own marker. A blank stays with
					-- the item only when something indented follows it, which
					-- is how a picture ends up inside item three rather than
					-- in a code block after the list.
					while i <= n do
						if rows[i] == "" then
							local j = i + 1
							while j <= n and rows[j] == "" do j = j + 1 end
							if j <= n and rows[j]:match(pad) then
								item[#item + 1] = ""
								i = i + 1
							else
								break
							end
						elseif rows[i]:match(pad) then
							item[#item + 1] = rows[i]:sub(#marker + 1)
							i = i + 1
						else
							break
						end
					end

					items[#items + 1] = { body = item, at = offset + start - 1 }
				end

				local list = { ordered and "<ol>" or "<ul>" }
				for _, item in ipairs(items) do
					local html = render(item.body, item.at)
					-- One paragraph and nothing else does not need the <p>.
					local only = html:match("^<p>(.*)</p>$")
					if only and not only:find("<p>", 1, true) then html = only end
					list[#list + 1] = "<li>" .. html .. "</li>"
				end
				list[#list + 1] = ordered and "</ol>" or "</ul>"
				put(table.concat(list))

			elseif line:match("^%* ") or line:match("^%*[^%*]") or line:match("^<")
				or line:match("^=") then
				error(where(at) .. ": a line this bake does not read: " .. line, 0)

			else
				local para = {}
				while i <= n and rows[i] ~= "" and not rows[i]:match("^[#>|!%-]")
					and not rows[i]:match("^%d+%. ") and not rows[i]:match("^[ \t]") do
					para[#para + 1] = rows[i]
					i = i + 1
				end
				local joined = table.concat(para, " ")
				put("<p>" .. text(at, joined) .. "</p>")
				collect(joined)
			end
		end

		return table.concat(out, "\n")
	end

	local html = render(lines, 0)
	assert(title, name .. " has no '# ' heading")
	return { title = title, html = html, sections = sections, notes = notes }
end

--------------------------------------------------------------------------
-- The page around the page
--------------------------------------------------------------------------

local GENERATED = "<!-- Written by scripts/bake-guide-site.sh out of docs/guide. Do not edit. -->"

local function rail(current, depth)
	local up = depth == 0 and "" or "../"
	local rows = { ('<a class="rail-row%s" href="%sindex.html">All pages</a>')
		:format(current == nil and " on" or "", up) }
	for _, name in ipairs(order) do
		local file = name:gsub("%.md$", ".html")
		rows[#rows + 1] = ('<a class="rail-row%s" href="%s%s">%s</a>')
			:format(name == current and " on" or "",
				depth == 0 and "guide/" or "", file, escape(titles[name]))
	end
	return table.concat(rows, "\n")
end

local function document(opts)
	local up = opts.depth == 0 and "" or "../"
	return ([[<!DOCTYPE html>
<html lang="en" data-palette="dark">
<head>
%s
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>%s</title>
<meta name="description" content="%s">
<link rel="stylesheet" href="%swiggle.css">
<script>try{var p=localStorage.getItem("wiggle-palette");if(p)document.documentElement.dataset.palette=p}catch(e){}</script>
</head>
<body>
<div class="window">
	<header class="titlebar">
		<a class="brand" href="%sindex.html">WiggleUI</a>
		<div class="search">
			<input id="find" type="search" placeholder="Search the guide" autocomplete="off" spellcheck="false">
			<div id="hits" class="hits" hidden></div>
		</div>
		<label class="palette">
			<span class="sr">Palette</span>
			<select id="palette">%s</select>
		</label>
	</header>
	<div class="split">
		<nav class="rail">
			<div class="rail-inner">
%s
				<p class="rail-note">Shake the mouse sideways to change the palette, the way the addon changes theme. <button type="button" id="wiggle-off" class="linky"></button></p>
			</div>
		</nav>
		<main class="page">
%s
		</main>
	</div>
	<footer class="footer">
		<span>%s</span>
		<span><a href="https://github.com/Baudin999/Addon-WiggleUI" target="_blank" rel="noopener">GitHub</a> &middot; <a href="https://github.com/Baudin999/Addon-WiggleUI/issues" target="_blank" rel="noopener">Report a bug</a></span>
	</footer>
</div>
<script src="%swiggle.js"></script>
</body>
</html>
]]):format(GENERATED, escape(opts.title), escape(opts.description), up, up,
		opts.options, opts.rail, opts.html, escape(opts.footer), up)
end

--------------------------------------------------------------------------
-- Write
--------------------------------------------------------------------------

local PALETTES = sorted(ns.Palettes)

local options = {}
for _, name in ipairs(PALETTES) do
	options[#options + 1] = ('<option value="%s">%s</option>')
		:format(name, name:sub(1, 1):upper() .. name:sub(2))
end
options = table.concat(options)

local search, notes = {}, 0

local function emit(name, file, depth, description, at)
	local built = page(name, read(GUIDE .. "/" .. name), depth)
	notes = notes + built.notes

	local link = depth == 0 and "index.html" or ("guide/" .. name:gsub("%.md$", ".html"))
	for _, section in ipairs(built.sections) do
		local words = table.concat(section.text, " ")
			:gsub("%[([^%]]*)%]%([^%)]*%)", "%1"):gsub("[`%*]", "")
		-- A page whose opening is one line and a heading straight after has
		-- nothing worth its own row.
		if #words > 40 then
			search[#search + 1] = {
				page = built.title,
				href = section.id and (link .. "#" .. section.id) or link,
				heading = section.heading, text = words,
			}
		end
	end

	local navigation, prose
	if depth == 0 then
		navigation, prose = rail(nil, 0), built.html
	else
		navigation, prose = rail(name, 1), built.html
	end

	write(OUT .. "/" .. file, document({
		at = at,
		depth = depth,
		title = depth == 0 and built.title or (built.title .. " - WiggleUI"),
		description = description,
		options = options,
		rail = navigation,
		html = prose,
		footer = ("The WiggleUI guide, page %d of %d"):format(at, #order + 1),
	}))
	return built
end

-- The index's own description is the first paragraph of the guide, because a
-- page with no description is a search result with nothing under the title.
local blurb = index:match("\n\n([^\n#][^\n]*\n[^\n]*)")
blurb = (blurb or "The WiggleUI guide"):gsub("\n", " "):gsub("%s+", " ")

emit("README.md", "index.html", 0, blurb, 1)
for at, name in ipairs(order) do
	emit(name, "guide/" .. name:gsub("%.md$", ".html"), 1,
		titles[name] .. ", from the WiggleUI guide.", at + 1)
end

--------------------------------------------------------------------------
-- The stylesheet, out of the addon's own tables
--------------------------------------------------------------------------

local function css(color)
	local r = math.floor(color[1] * 255 + 0.5)
	local g = math.floor(color[2] * 255 + 0.5)
	local b = math.floor(color[3] * 255 + 0.5)
	local a = color[4]
	if a and a < 1 then
		return ("rgba(%d, %d, %d, %s)"):format(r, g, b, tostring(a))
	end
	return ("#%02x%02x%02x"):format(r, g, b)
end

local sheet = {
	"/* Written by scripts/bake-guide-site.sh out of the addon's own tables. Do not edit. */",
	"/* The colours are src/Theme/*.lua and the numbers are UI.Metric in src/UI/Theme.lua. */",
	"",
}

local metric = {}
for _, key in ipairs(sorted(ns.UI.Metric)) do
	metric[#metric + 1] = ("\t--m-%s: %s;"):format(key, tostring(ns.UI.Metric[key]))
end
sheet[#sheet + 1] = ":root {\n" .. table.concat(metric, "\n") .. "\n}"
sheet[#sheet + 1] = ""

for _, name in ipairs(PALETTES) do
	local rules = {}
	for _, key in ipairs(sorted(ns.Palettes[name])) do
		if key ~= "unit" then
			rules[#rules + 1] = ("\t--c-%s: %s;"):format(key, css(ns.Palettes[name][key]))
		end
	end
	local unit = ns.Palettes[name].unit
	for _, key in ipairs(sorted(unit)) do
		rules[#rules + 1] = ("\t--u-%s: %s;"):format(key, css(unit[key]))
	end
	sheet[#sheet + 1] = ('[data-palette="%s"] {\n%s\n}'):format(name, table.concat(rules, "\n"))
end

sheet[#sheet + 1] = ""
sheet[#sheet + 1] = read(here .. "/site/site.css")
write(OUT .. "/wiggle.css", table.concat(sheet, "\n"))

--------------------------------------------------------------------------
-- The script, and the search index under it
--------------------------------------------------------------------------

local function json(text)
	return '"' .. text:gsub("[\\\"]", "\\%0"):gsub("\n", " "):gsub("%c", " ") .. '"'
end

local rows = {}
for _, entry in ipairs(search) do
	rows[#rows + 1] = ("{p:%s,h:%s,u:%s,t:%s}")
		:format(json(entry.page), json(entry.heading), json(entry.href), json(entry.text))
end

local names = {}
for _, name in ipairs(PALETTES) do names[#names + 1] = json(name) end

write(OUT .. "/wiggle.js", table.concat({
	"// Written by scripts/bake-guide-site.sh. Do not edit.",
	"var WIGGLE_PALETTES = [" .. table.concat(names, ",") .. "];",
	"var WIGGLE_INDEX = [" .. table.concat(rows, ",\n") .. "];",
	read(here .. "/site/site.js"),
}, "\n"))

print(("site      %d pages, %d sections indexed, %d palettes, %d author notes held back")
	:format(#order + 1, #search, #PALETTES, notes))
