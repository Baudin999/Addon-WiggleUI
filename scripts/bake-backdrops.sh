#!/usr/bin/env bash
# Bakes the painted window frames in art/ into the nine textures a window is
# drawn in, and writes src/Theme/Backdrops.lua, which says how big each piece is
# drawn.
#
# Each source is one painting: a frame round a floor that repeats, on a margin.
# Three things are done to it.
#
# The margin goes. A flat one, white or the alliance's navy, is flooded from
# the four corners of the image to alpha, with enough fuzz to take the JPEG
# fringe, and the alpha is eroded one pixel so no halo is left round the frame.
# A painted one, the arcane nebula, is out of focus where the frame is sharp,
# so it is the region of little detail that reaches the image's edge.
#
# A painting may name a ground: a second picture, the floor alone, which is
# drawn once over the whole window, scaled to cover it and cropped at the
# overflow, rather than cut into a tile. A starfield has no repeat to cut at,
# and a tile of one is a grid of hard lines. The ground is darkened whole, and
# baked at 1024 by 512 because it is drawn at the size of the window rather
# than of a tile; Backdrops.lua gives its source size, which is the shape the
# crop keeps.
#
# The floor is darkened to its painting's darken, so the item icons and the
# counts drawn over it still read. Each painting has its own, because a floor
# of pale sand needs more than one of moss before the dim labels read on it.
# Only the floor: everything inside the inner rectangle the geometry names. The corner blocks that reach into that rectangle are
# darkened with it, which is the price of not hand-painting a mask.
#
# And it is cut into nine. The middle is one repeat of the floor and is laid out
# as a grid of tiles, each rail is one repeat along its length and is laid out
# as a row, and the four corners are drawn once. A repeat cut at the measured
# period is close to seamless and not exactly, so the first OVERLAP pixels of
# each tile are cross-faded into the pixels one period on, which makes the join
# continuous whatever the painting did.
#
# The pieces are cut where they line up on the screen. The window's top left is
# the inner corner of the painting, so the middle is cut a whole number of
# periods from that corner, and each rail a whole number of periods from the
# corner it starts at. Laid out from the top left, the floor under a corner and
# the floor at the start of a rail are the pixels the painting had there.
#
# The rails and corners hang outside the window by the frame's own thickness,
# so a window keeps its size and its content keeps its place. Each rail reaches
# FADE source pixels into the floor and fades to nothing there, which is what
# hides the edge of the frame meeting a tile of floor at a different phase.
#
# Every side of every texture is a power of two, because the client will not
# draw one that is not, and scripts/check.sh gates that. The textures are
# larger than they are drawn, by up to twice, so a zoomed window stays sharp.
#
#   ./bake-backdrops.sh
#
# The outputs are committed, because they are what the addon ships.
set -uo pipefail
cd "$(dirname "$0")/.."

python3 - <<'PY' || exit 1
import struct
from PIL import Image, ImageChops, ImageDraw, ImageFilter

# One row per painting. inset is where the floor starts, left, top, right and
# bottom, in source pixels; corner is the square that holds each corner's
# ornament; period is the floor's repeat across and down, measured by
# autocorrelation of the middle; darken is what the floor keeps of its
# brightness; margin is flat or blurred. desert02 is the same frame as the
# first desert painting with a calmer floor, so it kept that painting's
# numbers; a painting with a new frame needs them measured again.
#
# A floor that does not repeat from its inner corner names where its tile is
# cut instead, as floor, and gives up the phase with the corners. Arcane's is
# three different rows of slabs, so its tile is the middle row, mortar line to
# mortar line. Its rails then repeat at a length of their own, rail, because
# the floor's 150 pixels down is a third of a snake, and are cut clear of the
# corner by a distance of their own, clear, because its corner block ends in a
# gold pillar that would otherwise stand at every join.
#
# Horde and alliance are arcane's frame and floor repainted, so they keep its
# numbers, except that their side pillar is a plain slab between two blocks at
# 200 and 490: the side rail is 150 long so the tile and its overlap end short
# of the lower block. Horde's margin is a dark brown the blurred test takes as
# readily as a nebula. Alliance's is flat navy, and its bottom rail has a
# smooth face that the blurred test reaches and eats, so it is flooded like the
# white ones: the flood compares each pixel to its corner's colour.
PAINTINGS = [
	{
		"palette": "forest", "file": "art/forrest.jpeg", "stem": "Forest",
		"inset": (60, 55, 60, 55), "corner": 120, "period": (335, 347),
		"darken": 0.60, "ground": "art/forrest_bg.jpeg", "dim": 0.55,
	},
	{
		"palette": "desert", "file": "art/desert02.jpeg", "stem": "Desert",
		"inset": (72, 100, 82, 80), "corner": 210, "period": (334, 346),
		"darken": 0.45, "ground": "art/desert_bg.jpeg", "dim": 0.45,
	},
	{
		"palette": "arcane", "file": "art/arcane.jpeg", "stem": "Arcane",
		"inset": (78, 100, 78, 82), "corner": 210, "period": (333, 150),
		"darken": 0.75, "margin": "blurred",
		"floor": (381, 313), "rail": (300, 220), "clear": 105,
		"ground": "art/arcane_bg.jpeg", "dim": 0.65,
	},
	{
		"palette": "horde", "file": "art/horde.jpeg", "stem": "Horde",
		"inset": (78, 100, 78, 82), "corner": 210, "period": (333, 150),
		"darken": 0.45, "margin": "blurred",
		"floor": (381, 313), "rail": (300, 150), "clear": 105,
		"ground": "art/horde_bg.jpeg", "dim": 0.50,
	},
	{
		"palette": "alliance", "file": "art/alliance.jpeg", "stem": "Alliance",
		"inset": (78, 100, 78, 82), "corner": 210, "period": (333, 150),
		"darken": 0.65, "margin": "flat",
		"floor": (381, 313), "rail": (300, 150), "clear": 105,
		"ground": "art/alliance_bg.jpeg", "dim": 0.50,
	},
]

SCALE = 0.30     # window units per source pixel
FADE = 16        # source pixels a rail and a corner reach into the floor
OVERLAP = 24     # source pixels cross-faded at the start of each tile
CLEAR = 40       # source pixels a tile is cut clear of a painted shadow or notch
FUZZ = 30        # how far from the corner's colour still counts as margin, of 255
EDGE = 8         # source pixels over which the darkening ramps in
SHARP = 5        # the local detail, of 255, under which a pixel is out of focus


def pot(drawn):
	# The next power of two at least twice the drawn size, at most 256.
	side = 1
	while side < drawn * 2 and side < 256:
		side *= 2
	return side


def unflat(image):
	rgba = image.convert("RGBA")
	w, h = rgba.size
	# A flood through the corner's colour from each corner of the image, marked
	# on a copy, so the same colour inside the painting (a highlight on a gem)
	# stays.
	marked = rgba.convert("RGB")
	for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
		ImageDraw.floodfill(marked, (x, y), (255, 0, 255), thresh=FUZZ)
	r, g, b = marked.split()
	margin = Image.eval(ImageChops.difference(
		Image.merge("RGB", (r, g, b)), Image.new("RGB", marked.size, (255, 0, 255))
	).convert("L"), lambda v: 255 if v > 0 else 0)
	alpha = margin.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
	rgba.putalpha(alpha)
	return rgba


def unblur(image):
	rgba = image.convert("RGBA")
	w, h = rgba.size
	# How far each pixel is from its own blur, averaged over its neighbours:
	# near nothing on the nebula, and well above SHARP on the frame's carving.
	grey = rgba.convert("L")
	detail = ImageChops.difference(grey, grey.filter(ImageFilter.GaussianBlur(2)))
	detail = detail.filter(ImageFilter.BoxBlur(3))
	soft = detail.point(lambda v: 255 if v < SHARP else 0)
	# The soft region that reaches the edge, from a seed at each corner and at
	# the middle of each side, so a soft patch inside the frame, a gem's face,
	# is not taken for margin.
	for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
			(w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)):
		if soft.getpixel((x, y)) == 255:
			ImageDraw.floodfill(soft, (x, y), 128)
	alpha = soft.point(lambda v: 0 if v == 128 else 255)
	alpha = alpha.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
	rgba.putalpha(alpha)
	return rgba


MARGINS = {"flat": unflat, "blurred": unblur}


def darken(rgba, inset, keep):
	w, h = rgba.size
	left, top, right, bottom = inset
	# A mask of the floor, soft at its edge, and the image mixed with a darker
	# copy of itself through it.
	mask = Image.new("L", (w, h), 0)
	ImageDraw.Draw(mask).rectangle((left, top, w - right, h - bottom), fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(EDGE / 2))
	rgb = rgba.convert("RGB")
	dark = rgb.point(lambda v: int(v * keep))
	out = Image.composite(dark, rgb, mask)
	out.putalpha(rgba.getchannel("A"))
	return out


def seamless(image, x, y, width, height, across, down):
	# A crop of width by height at x, y, whose first OVERLAP columns are mixed
	# with the columns one period on when across is set, and rows likewise.
	tile = image.crop((x, y, x + width, y + height))
	if across:
		ahead = image.crop((x + width, y, x + width + OVERLAP, y + height))
		ramp = Image.linear_gradient("L").rotate(90, expand=True).transpose(Image.FLIP_LEFT_RIGHT)
		ramp = ramp.resize((OVERLAP, height))
		start = tile.crop((0, 0, OVERLAP, height))
		tile.paste(Image.composite(start, ahead, ramp), (0, 0))
	if down:
		ahead = image.crop((x, y + height, x + width, y + height + OVERLAP))
		ramp = Image.linear_gradient("L").resize((width, OVERLAP))
		start = tile.crop((0, 0, width, OVERLAP))
		tile.paste(Image.composite(start, ahead, ramp), (0, 0))
	return tile


def fade(tile, side, depth):
	# Multiplies the alpha down to nothing over the last depth pixels of a side.
	w, h = tile.size
	ramp = Image.new("L", (w, h), 255)
	draw = ImageDraw.Draw(ramp)
	for i in range(depth):
		value = int(255 * (depth - 1 - i) / depth)
		if side == "bottom":
			draw.line((0, h - depth + i, w, h - depth + i), fill=value)
		elif side == "top":
			draw.line((0, depth - 1 - i, w, depth - 1 - i), fill=value)
		elif side == "right":
			draw.line((w - depth + i, 0, w - depth + i, h), fill=value)
		elif side == "left":
			draw.line((depth - 1 - i, 0, depth - 1 - i, h), fill=value)
	tile.putalpha(ImageChops.multiply(tile.getchannel("A"), ramp))
	return tile


def fade_corner(tile, inward_x, inward_y, reach_x, reach_y):
	# A corner fades only where it covers floor: along the side that faces
	# along the top rail, below the rail's thickness, and along the side that
	# faces down the left rail, inside the rail's thickness. inward_x says which
	# side of the tile faces the middle across, inward_y which faces it down;
	# reach_x and reach_y are how far from the outer edge the rails end.
	w, h = tile.size
	ramp = Image.new("L", (w, h), 255)
	px = ramp.load()
	for y in range(h):
		for x in range(w):
			dx = (w - 1 - x) if inward_x == "right" else x
			dy = (h - 1 - y) if inward_y == "bottom" else y
			ox = x if inward_x == "right" else w - 1 - x
			oy = y if inward_y == "bottom" else h - 1 - y
			value = 1.0
			if dx < FADE and oy >= reach_y:
				value *= dx / FADE
			if dy < FADE and ox >= reach_x:
				value *= dy / FADE
			px[x, y] = int(255 * value)
	tile.putalpha(ImageChops.multiply(tile.getchannel("A"), ramp))
	return tile


def bleed(image):
	# The colour under a transparent pixel is still the white of the margin,
	# and both the resize here and the client's filtering read it: a visible
	# pixel beside one comes out pale. So each transparent pixel takes the
	# colour of the frame near it: the colour blurred with alpha as its weight,
	# then divided by the blurred alpha so it is the frame's colour and not the
	# frame's colour darkened toward black.
	alpha = image.getchannel("A")
	solid = Image.new("RGB", image.size, (0, 0, 0))
	solid.paste(image.convert("RGB"), mask=alpha)
	spread = solid.filter(ImageFilter.GaussianBlur(4))
	weight = alpha.filter(ImageFilter.GaussianBlur(4)).tobytes()
	bands = []
	for band in spread.split():
		bands.append(Image.frombytes("L", image.size, bytes(
			min(255, v * 255 // w) if w else 0 for v, w in zip(band.tobytes(), weight))))
	out = Image.composite(image.convert("RGB"), Image.merge("RGB", bands),
		alpha.point(lambda v: 255 if v else 0))
	out.putalpha(alpha)
	return out


def write_tga(image, path, size):
	# Resized premultiplied, so no transparent colour is mixed in, and bled
	# after, because the premultiplied round trip leaves transparent black.
	image = bleed(image.convert("RGBa").resize(size, Image.LANCZOS).convert("RGBA"))
	w, h = image.size
	header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
	with open(path, "wb") as f:
		f.write(header)
		f.write(image.tobytes("raw", "BGRA"))


def drawn(source):
	return round(source * SCALE)


lua = [
	"local ADDON, ns = ...",
	"",
	"-- Written by scripts/bake-backdrops.sh. Do not edit: change the painting or",
	"-- the numbers at the top of the bake, and run it again.",
	"--",
	"-- One entry per palette that has a painted frame. Each piece is a texture",
	"-- and the size it is drawn at in window units; corner, top and left are the",
	"-- frame's thickness outside the window, and fade is how far each rail and",
	"-- corner reaches in over the floor. cover says the floor is one picture",
	"-- drawn over the whole window, and its size is the picture's shape. A",
	"-- palette with no entry keeps the flat window fill.",
	"",
	"ns.Backdrops = {",
]

for p in PAINTINGS:
	src = darken(MARGINS[p.get("margin", "flat")](Image.open(p["file"])), p["inset"], p["darken"])
	W, H = src.size
	left, top, right, bottom = p["inset"]
	c = p["corner"]
	pw, ph = p["period"]
	stem = p["stem"]
	pieces = {}

	def emit(key, image, drawn_size, size=None):
		name = f"{stem}-{key}.tga"
		write_tga(image, f"src/Media/{name}", size or (pot(drawn_size[0]), pot(drawn_size[1])))
		pieces[key] = (name, drawn_size)

	# The middle, a whole period right of the inner corner so its phase is the
	# painting's at the window's top left. The rails cast a painted shadow over
	# the first rows and columns of floor, so the tile is cut CLEAR further in
	# and rolled back by as much: a seamless tile rolled is the same tile with
	# its origin moved, which puts the phase back where it was.
	if "ground" in p:
		ground = Image.open(p["ground"]).convert("RGB")
		ground = ground.point(lambda v: int(v * p["dim"])).convert("RGBA")
		emit("Middle", ground, ground.size, (1024, 512))
	elif "floor" in p:
		mid = seamless(src, p["floor"][0], p["floor"][1], pw, ph, True, True)
		emit("Middle", mid, (drawn(pw), drawn(ph)))
	else:
		mid = seamless(src, left + pw + CLEAR, top + CLEAR, pw, ph, True, True)
		emit("Middle", ImageChops.offset(mid, CLEAR, CLEAR), (drawn(pw), drawn(ph)))

	# The rails, each in phase with where its corner ends, which is where the
	# row of them is laid on the screen. Cut CLEAR further along and rolled back
	# like the middle, because the painting's corner block meets its rail at a
	# notch, and a tile that starts on the notch repeats it at every join.
	clear = p.get("clear", CLEAR)

	def rail(x, y, width, height, across):
		tile = seamless(src, x + (clear if across else 0), y + (0 if across else clear),
			width, height, across, not across)
		return ImageChops.offset(tile, clear % width if across else 0, 0 if across else clear % height)

	rw, rh = p.get("rail", (pw, ph))
	emit("Top", fade(rail(c, 0, rw, top + FADE, True), "bottom", FADE),
		(drawn(rw), drawn(top + FADE)))
	emit("Bottom", fade(rail(c, H - bottom - FADE, rw, bottom + FADE, True), "top", FADE),
		(drawn(rw), drawn(bottom + FADE)))
	emit("Left", fade(rail(0, c, left + FADE, rh, False), "right", FADE),
		(drawn(left + FADE), drawn(rh)))
	emit("Right", fade(rail(W - right - FADE, c, right + FADE, rh, False), "left", FADE),
		(drawn(right + FADE), drawn(rh)))

	emit("TopLeft", fade_corner(src.crop((0, 0, c, c)), "right", "bottom", left, top),
		(drawn(c), drawn(c)))
	emit("TopRight", fade_corner(src.crop((W - c, 0, W, c)), "left", "bottom", right, top),
		(drawn(c), drawn(c)))
	emit("BottomLeft", fade_corner(src.crop((0, H - c, c, H)), "right", "top", left, bottom),
		(drawn(c), drawn(c)))
	emit("BottomRight", fade_corner(src.crop((W - c, H - c, W, H)), "left", "top", right, bottom),
		(drawn(c), drawn(c)))

	lua.append(f"\t{p['palette']} = {{")
	lua.append(f"\t\tthickness = {{ left = {drawn(left)}, top = {drawn(top)}, "
		f"right = {drawn(right)}, bottom = {drawn(bottom)} }},")
	lua.append(f"\t\tfade = {drawn(FADE)},")
	lua.append(f"\t\tcorner = {drawn(c)},")
	if "ground" in p:
		lua.append("\t\tcover = true,")
	for key in ("Middle", "Top", "Bottom", "Left", "Right", "TopLeft", "TopRight", "BottomLeft", "BottomRight"):
		name, (dw, dh) = pieces[key]
		lua.append(f"\t\t{key} = {{ \"Interface\\\\AddOns\\\\WarriorKit\\\\Media\\\\{name}\", {dw}, {dh} }},")
	lua.append("\t},")
	print(f"baked {stem}: {W}x{H}, corner {drawn(c)}, tile {drawn(pw)}x{drawn(ph)}")

lua.append("}")
with open("src/Theme/Backdrops.lua", "w") as f:
	f.write("\n".join(lua) + "\n")
PY

printf 'wrote src/Theme/Backdrops.lua\n'
