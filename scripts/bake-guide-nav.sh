#!/usr/bin/env bash
# Writes the previous/next footer on every page of docs/guide, so a reader can
# walk the guide front to back instead of going back to the index twelve times.
#
#   ./scripts/bake-guide-nav.sh           write the footers
#   ./scripts/bake-guide-nav.sh --check   exit non-zero if any is wrong
#
# The order is not kept here. It is the order the pages are linked in from
# docs/guide/README.md, which is the index somebody already has to edit to add
# a page, so there is one list and not two that can disagree. A page's name in
# the footer is its own `# ` heading, for the same reason.
#
# The footer starts at the marker below and runs to the end of the file.
# Everything above it is the page and is never touched.
set -euo pipefail
cd "$(dirname "$0")/.."

MARKER="<!-- nav -->"
GUIDE="docs/guide"
INDEX="$GUIDE/README.md"

# Reading order, de-duplicated, first mention wins. A page the index does not
# link to gets no footer and is a page nobody can reach, which the check below
# reports rather than papering over.
mapfile -t pages < <(grep -oP '\]\(\K[a-z0-9-]+\.md(?=\))' "$INDEX" | awk '!seen[$0]++')

title() {
	local heading
	heading=$(grep -m1 '^# ' "$GUIDE/$1" | sed 's/^# //')
	[ -n "$heading" ] || { echo "$GUIDE/$1 has no '# ' heading" >&2; exit 1; }
	printf '%s' "$heading"
}

# The body is everything above the marker, with trailing blank lines dropped so
# a rerun cannot grow the file by one line each time.
body() {
	sed "/^$MARKER\$/,\$d" "$1" | sed -e :a -e '/^\s*$/{$d;N;ba' -e '}'
}

footer() {
	local index=$1 previous next line
	printf '%s\n' "$MARKER"
	printf -- '---\n\n'
	line=""
	if [ "$index" -gt 0 ]; then
		previous=${pages[index - 1]}
		line="Previous: [$(title "$previous")]($previous) | "
	fi
	line="${line}[All pages](README.md)"
	if [ "$index" -lt $((${#pages[@]} - 1)) ]; then
		next=${pages[index + 1]}
		line="$line | Next: [$(title "$next")]($next)"
	fi
	printf '%s\n' "$line"
}

stale=0
for i in "${!pages[@]}"; do
	page="$GUIDE/${pages[i]}"
	[ -f "$page" ] || { echo "$INDEX links $page, which does not exist" >&2; exit 1; }

	want=$(mktemp)
	{ body "$page"; printf '\n'; footer "$i"; } > "$want"

	if [ "${1:-}" = "--check" ]; then
		if ! diff -q "$want" "$page" >/dev/null; then
			echo "$page has the wrong footer; run ./scripts/bake-guide-nav.sh" >&2
			diff -u "$page" "$want" >&2 || true
			stale=1
		fi
		rm -f "$want"
	else
		mv "$want" "$page"
	fi
done

# A page in the folder that the index never links to is unreachable, footer or
# no footer, so it is a finding in both modes.
for page in "$GUIDE"/*.md; do
	name=$(basename "$page")
	[ "$name" = "README.md" ] && continue
	printf '%s\n' "${pages[@]}" | grep -qx "$name" && continue
	echo "$page is in the guide and the index links to nothing of it" >&2
	stale=1
done

[ "$stale" -eq 0 ] || exit 1

if [ "${1:-}" = "--check" ]; then
	echo "nav       every page of docs/guide carries the right footer"
else
	echo "wrote the footer on ${#pages[@]} pages"
fi
