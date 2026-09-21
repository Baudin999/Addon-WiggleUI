#!/usr/bin/env bash
# Bakes docs/guide into the static site GitHub Pages serves out of docs/.
#
#   ./scripts/bake-guide-site.sh           write the site
#   ./scripts/bake-guide-site.sh --check   exit non-zero if it is stale
#
# Pages is set to the master branch and the /docs folder, so what is committed
# here is what is published and there is no build anywhere but this script.
#
# The markdown and the stylesheet are scripts/bake-guide-site.lua's, which
# loads the addon to read its palettes. This half does the paths, the pictures
# and the font, because ImageMagick is a thing a shell calls and not a thing
# Lua does.
#
# The pictures are not diffed in --check and that is deliberate. WebP is a
# lossy encoder and its output moves with the version of libwebp on the
# machine, so a byte comparison would turn a libwebp upgrade into a failing
# commit. What the gate checks is the failure that matters: a page referring
# to a picture that is not in docs/img.
set -euo pipefail
cd "$(dirname "$0")/.."

GUIDE="docs/guide"
OUT="docs"
SHOTS="assets/docs-screenshots"

# The screenshot the window sits on. It is blurred past reading, because the
# window's own fill is 0.97 alpha in every palette and a page with nothing
# behind it would draw that as flat. In the game what is behind it is the
# world; here it is one afternoon on the beach at Azshara.
SCENE="theme-exploration-01"

check=0
[ "${1:-}" = "--check" ] && check=1

command -v lua5.1 >/dev/null || { echo "bake-guide-site needs lua5.1" >&2; exit 1; }

# ----------------------------------------------------------------- pages

if [ "$check" -eq 1 ]; then
	want=$(mktemp -d)
	trap 'rm -rf "$want"' EXIT
	mkdir -p "$want/guide"
	lua5.1 scripts/bake-guide-site.lua src "$GUIDE" "$want" >/dev/null

	stale=0
	while IFS= read -r page; do
		name=${page#"$want/"}
		if [ ! -f "$OUT/$name" ]; then
			echo "$OUT/$name is missing; run ./scripts/bake-guide-site.sh" >&2
			stale=1
		elif ! diff -q "$page" "$OUT/$name" >/dev/null; then
			echo "$OUT/$name is stale; run ./scripts/bake-guide-site.sh" >&2
			stale=1
		fi
	done < <(find "$want" -type f | sort)

	# And the other way: a page the bake no longer writes, left behind by a
	# page that was renamed, is a page still on the site and still linked
	# from nowhere.
	while IFS= read -r page; do
		name=${page#"$OUT/"}
		[ -f "$want/$name" ] || { echo "$page is on the site and the bake writes no such page" >&2; stale=1; }
	done < <(find "$OUT" -maxdepth 1 -name 'index.html' -o -path "$OUT/guide/*.html" | sort)
else
	mkdir -p "$OUT/guide" "$OUT/img"
	lua5.1 scripts/bake-guide-site.lua src "$GUIDE" "$OUT"

	# A page that was renamed leaves its old HTML behind, and the old file is
	# still served. Dropped here rather than left for the check to report.
	while IFS= read -r page; do
		name=$(basename "$page" .html)
		[ -f "$GUIDE/$name.md" ] || { echo "dropped $page, whose page is gone"; rm -f "$page"; }
	done < <(find "$OUT/guide" -name '*.html' | sort)
fi

# ---------------------------------------------------------------- picture

# Every picture the guide names, plus the one the window sits on. Resized to
# something a browser can pull down: the originals run to 1.9 MB each and are
# 1720 wide, which is more than the column they are drawn in.
mapfile -t shots < <(grep -oh "$SHOTS/[a-z0-9-]*\.png" "$GUIDE"/*.md \
	| sed "s|$SHOTS/||;s|\.png$||" | sort -u)

missing=0
for shot in "${shots[@]}"; do
	src="$SHOTS/$shot.png"
	webp="$OUT/img/$shot.webp"
	[ -f "$src" ] || { echo "$GUIDE names $src, which is not there" >&2; missing=1; continue; }

	if [ "$check" -eq 1 ]; then
		[ -f "$webp" ] || { echo "$webp is missing; run ./scripts/bake-guide-site.sh" >&2; missing=1; }
		continue
	fi

	if [ ! -f "$webp" ] || [ "$src" -nt "$webp" ]; then
		magick "$src" -resize '1600x>' -quality 80 -define webp:method=6 "$webp"
		echo "drew img/$shot.webp"
	fi
done

if [ "$check" -eq 1 ]; then
	[ -f "$OUT/scene.webp" ] || { echo "$OUT/scene.webp is missing; run ./scripts/bake-guide-site.sh" >&2; missing=1; }
	[ -f "$OUT/Sans.ttf" ] || { echo "$OUT/Sans.ttf is missing; run ./scripts/bake-guide-site.sh" >&2; missing=1; }
	[ -f "$OUT/Sans-LICENSE.txt" ] || { echo "$OUT/Sans-LICENSE.txt is missing; the font may not ship without it" >&2; missing=1; }
	[ -f "$OUT/.nojekyll" ] || { echo "$OUT/.nojekyll is missing; Pages would run Jekyll over the site" >&2; missing=1; }
else
	if [ ! -f "$OUT/scene.webp" ] || [ "$SHOTS/$SCENE.png" -nt "$OUT/scene.webp" ]; then
		magick "$SHOTS/$SCENE.png" -resize '1200x' -blur 0x14 -modulate 70 \
			-quality 55 "$OUT/scene.webp"
		echo "drew scene.webp"
	fi

	# The addon's own font, so the page is set in what the game is set in. It
	# is Noto Sans under the SIL OFL and the licence travels with it, which is
	# the same rule scripts/check.sh puts on src/Media.
	cp -p src/Media/Sans.ttf "$OUT/Sans.ttf"
	cp -p src/Media/Sans-LICENSE.txt "$OUT/Sans-LICENSE.txt"

	# Without this, Pages runs Jekyll over the folder and drops anything whose
	# name starts with an underscore.
	touch "$OUT/.nojekyll"
fi

if [ "$check" -eq 1 ]; then
	[ "${stale:-0}" -eq 0 ] && [ "$missing" -eq 0 ] || exit 1
	echo "site      docs/ is the guide as it stands"
else
	[ "$missing" -eq 0 ] || exit 1
	echo "wrote the site into $OUT/"
fi
