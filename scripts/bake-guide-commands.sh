#!/usr/bin/env bash
# Bakes docs/guide/commands.md out of the help tables in the source, so the
# command reference cannot drift from the commands the addon answers.
#
#   ./scripts/bake-guide-commands.sh           write the file
#   ./scripts/bake-guide-commands.sh --check   exit non-zero if it is stale
#
# The reference in docs/README.md drifted for a year and nothing said so: it
# still listed `/wui loadout` five months after the weapon loadouts came out at
# e4971974, and it listed five palettes where the code has eight. A hand
# maintained list of a hundred and eighty commands is a list that is wrong.
#
# Every part declares `help` in its Feature.lua and `name` beside it, and
# `/wui help` prints exactly those lines. This reads the same two fields, in
# `order`, and writes them out. The words Core answers itself are not in any
# registry, so they are the one block spelled out below.
set -euo pipefail
cd "$(dirname "$0")/.."

out="docs/guide/commands.md"
[ "${1:-}" = "--check" ] && out=$(mktemp)

# The previous/next footer belongs to bake-guide-nav.sh and is appended back
# below, so the two bakes do not overwrite each other. Read before anything
# truncates the file, because in write mode $out is the file.
nav=$(sed -n '/^<!-- nav -->$/,$p' docs/guide/commands.md 2>/dev/null || true)

# The parts in panel order, one row each, in a file rather than down a pipe:
# the loop that reads it runs awk per row and a loop reading a pipe it shares
# with its own producer is a shape that has bitten this script once already.
rows=$(mktemp)
trap 'rm -f "$rows"' EXIT

# Every file that registers a part. Theme, the game menu and the replaced
# notice register from outside a Feature.lua, so the list is grepped rather
# than globbed.
files=$(grep -rl "ns.Register" --include="*.lua" src/ | sort)

{
	cat <<'HEAD'
# Every command

Generated from the help tables in the source by
`scripts/bake-guide-commands.sh`. This is the same text `/wui help` prints in
the game, so it cannot fall behind what the addon answers.

`/wui` on its own opens the settings panel. `/wui help` prints this list in
chat, and `/wui status` prints one line per part saying what it is doing right
now.

## The words Core answers itself

    /wui                       open the settings panel
    /wui panel|options|config  the same thing
    /wui status                one line per part
    /wui help                  the command list
    /wui lock                  put the theme back
    /wui unlock                every element up, drag it where you want it
    /wui reset                 positions, size, width and offset
    /wui defaults              what is not the answer the addon ships with
    /wui defaults yes          put all of it back, and reload

`defaults yes` is the one command here that cannot be undone, which is why it
asks twice. Your groups, your mail favourites and your muted errors survive it.
HEAD

	for f in $files; do
		# || true on both: pipefail makes a grep that found nothing a failed
		# pipeline, and a file under src/ that calls ns.Register without an
		# order is a helper registering nothing, not an error.
		order=$(grep -oP '^\s*order = \K[0-9]+' "$f" | head -1) || true
		name=$(grep -oP '^\s*name = "\K[^"]+' "$f" | head -1) || true
		[ -n "$order" ] && [ -n "$name" ] || continue
		printf '%03d\t%s\t%s\n' "$order" "$name" "$f"
	done | sort -n > "$rows"

	while IFS=$'\t' read -r _ name file; do
		lines=$(awk '/^[ \t]*help = \{/{d=1;next} d&&/^[ \t]*\},/{exit} d' "$file" |
			grep -oP '"\K[^"]*(?=")') || continue
		[ -n "$lines" ] || continue
		# A part with no switch of its own registers under a global-shaped name,
		# WiggleUIGameMenuSetup and the like. Strip the prefix and split the
		# humps rather than keeping a map of the two that do it today.
		heading=$(printf '%s' "$name" | sed -e 's/^WiggleUI//' \
			-e 's/\([a-z0-9]\)\([A-Z]\)/\1 \2/g' | tr '[:upper:]' '[:lower:]')
		printf '\n## %s\n\n' "$heading"
		printf '%s\n' "$lines" | sed 's|^|    /wui |'
	done < "$rows"

	# The while ends on a failed read, which is how a loop ends and not a
	# finding. Without this the group's status is that read and set -e kills it.
	:
} > "$out"

# Put the footer back, so what is compared or written is the whole page.
[ -z "$nav" ] || printf '\n%s\n' "$nav" >> "$out"

if [ "${1:-}" = "--check" ]; then
	if ! diff -q "$out" docs/guide/commands.md >/dev/null 2>&1; then
		echo "docs/guide/commands.md is stale; run ./scripts/bake-guide-commands.sh" >&2
		diff -u docs/guide/commands.md "$out" >&2 || true
		rm -f "$out"
		exit 1
	fi
	rm -f "$out"
	echo "commands  docs/guide/commands.md matches the help tables"
else
	echo "wrote $out"
fi
