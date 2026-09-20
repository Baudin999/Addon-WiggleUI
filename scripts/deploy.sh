#!/usr/bin/env bash
# Puts the tree that is here on CurseForge. One command, no arguments needed.
#
#   ./scripts/deploy.sh              bump, gate, build, upload as an alpha
#   ./scripts/deploy.sh --type beta  the same, tagged beta
#   ./scripts/deploy.sh --build      gate and build, upload nothing, no bump
#
# This is release.sh with the two things release.sh cannot guess filled in: the
# project id, which is on the project page and never changes, and the token,
# which is a secret and must not be. Everything that decides what goes in the
# zip, which game versions it is tagged for and what the changelog says lives
# in release.sh, and this file does not repeat any of it.
#
# alpha is the default on purpose. The project page says alpha, docs/CHANGELOG
# says alpha, and a release type is the one part of a CurseForge upload nobody
# can correct afterwards without deleting the file. Typing --type release is a
# decision; getting it by leaving an argument off is an accident.
set -euo pipefail
cd "$(dirname "$0")/.."

# The number under "Project ID" on the CurseForge project page. It is here
# rather than in the environment because there is one project, it will not
# change, and a mistyped id uploads this addon into somebody else's page.
: "${CF_PROJECT_ID:=1675955}"
export CF_PROJECT_ID

release_type="alpha"
upload=1
while [ $# -gt 0 ]; do
	case "$1" in
		--type) shift; release_type="${1:-}" ;;
		--build) upload=0 ;;
		-h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
		*) echo "unknown argument: $1" >&2; exit 2 ;;
	esac
	shift
done

# The token, from https://legacy.curseforge.com/account/api-tokens. A file at
# the repo root is easier to live with than an export that dies with the shell,
# so both work and the environment wins. .gitignore has the filename and says
# why; check that rule is still there before writing a token into this tree.
if [ -z "${CF_API_TOKEN:-}" ] && [ -f .curseforge-token ]; then
	CF_API_TOKEN=$(tr -d '[:space:]' < .curseforge-token)
	export CF_API_TOKEN
fi

if [ "$upload" -eq 1 ] && [ -z "${CF_API_TOKEN:-}" ]; then
	echo "no CurseForge token." >&2
	echo "Put one in .curseforge-token at the repo root, or export CF_API_TOKEN." >&2
	echo "Tokens are made at https://legacy.curseforge.com/account/api-tokens" >&2
	exit 1
fi

[ "$upload" -eq 1 ] || exec ./scripts/release.sh

# Every upload is a new version. CurseForge shows the number, the client shows
# the number, and before this ran every upload there was 1.9. The last part is
# raised, so 1.9 becomes 1.10, in the three places check.sh holds together.
version_files=(src/Core/Core.lua src/WiggleUI.toc src/WiggleUI_Vanilla.toc)

# The bump is committed on its own, so these three must hold nothing else yet.
# A peer's edit in Core.lua would otherwise ship inside a commit called Release.
if ! git diff --quiet HEAD -- "${version_files[@]}"; then
	echo "uncommitted changes in the version files; commit them first:" >&2
	git diff --stat HEAD -- "${version_files[@]}" >&2
	exit 1
fi

old=$(sed -n 's/^ns\.version = "\(.*\)"$/\1/p' src/Core/Core.lua)
[ -n "$old" ] || { echo "no ns.version in src/Core/Core.lua" >&2; exit 1; }
new="${old%.*}.$(( ${old##*.} + 1 ))"
[ "$old" != "${old%.*}" ] || new=$(( old + 1 ))

set_version() {
	sed -i "s/^ns\.version = \".*\"$/ns.version = \"$1\"/" src/Core/Core.lua
	sed -i "s/^## Version: .*/## Version: $1/" src/WiggleUI.toc src/WiggleUI_Vanilla.toc
}

echo "version $old -> $new"
set_version "$new"

# A failed release puts the old number back rather than leaving a bump for a
# version that never shipped. sed, not git checkout: the files were clean at
# HEAD a moment ago, but checkout is how a peer's work gets eaten.
if ! ./scripts/release.sh --upload --type "$release_type"; then
	set_version "$old"
	echo "version put back to $old" >&2
	exit 1
fi

git commit -q -m "Release $new" -- "${version_files[@]}"
git tag -a "v$new" -m "WiggleUI $new, $release_type"
echo "committed and tagged v$new"
