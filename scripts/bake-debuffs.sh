#!/usr/bin/env bash
# Bakes src/UnitFrames/Debuffs.lua out of Blizzard's own spell tables.
#
#   ./scripts/bake-debuffs.sh [path/to/a/folder/of/exports]
#
# Five exports, every one of them Blizzard's own table, from wago.tools:
#
#   SkillLine.csv         which skill lines are a class's.
#   SkillLineAbility.csv  which spells each skill line teaches.
#   Talent.csv            every talent and the spell behind each rank.
#   SpellName.csv         a name per spell id.
#   SpellEffect.csv       what each spell does, filtered to the effects the
#                         bake reads. Whole, the table is too big to stream.
#
# Not a dependency of the addon and not needed to run it. Run this when the
# client's spell data changes.
set -uo pipefail
cd "$(dirname "$0")/.."

CLIENT="wow_anniversary"

EXPORTS="${1:-}"
if [ -z "$EXPORTS" ]; then
	EXPORTS="${TMPDIR:-/tmp}/wiggleui-debuff-exports"
	mkdir -p "$EXPORTS" || exit 1

	fetch() {
		local into="$EXPORTS/$1"
		local from="$2"
		[ -s "$into" ] && return 0
		echo "fetching $1"
		curl -fsS --max-time 300 "$from" -o "$into" || {
			echo "could not fetch $from" >&2
			rm -f "$into"
			return 1
		}
	}

	for table in SkillLine SkillLineAbility Talent SpellName; do
		fetch "$table.csv" "https://wago.tools/db2/$table/csv?branch=$CLIENT" || exit 1
	done
	# The filter is a substring match on the Effect column, so "6" brings back
	# APPLY_AURA (6) and TRIGGER_SPELL (64) together, with some others the bake
	# reads past.
	fetch SpellEffect.csv "https://wago.tools/db2/SpellEffect/csv?branch=$CLIENT&filter%5BEffect%5D=6" || exit 1
fi

for name in SkillLine.csv SkillLineAbility.csv Talent.csv SpellName.csv SpellEffect.csv; do
	[ -s "$EXPORTS/$name" ] || {
		echo "no $name in $EXPORTS" >&2
		exit 1
	}
done

echo "reading $EXPORTS"
lua5.1 scripts/bake-debuffs.lua "$EXPORTS" || exit 1
lua5.1 -e "assert(loadfile('src/UnitFrames/Debuffs.lua'))" || {
	echo "the baked file does not parse" >&2
	exit 1
}
