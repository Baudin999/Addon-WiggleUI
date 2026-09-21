---
revision: 5
id: 01M31B67WVYHVFR2YBSA66GFA5
---

Landed. Two things the bake found in the guide itself, both fixed in the bake rather than in the prose.

Six of the thirteen pages have no '## ' heading at all: bars, chores, feeds, frames, screen and windows. The first cut of the search index only collected text under a heading, so half the guide was in the index as nothing. Every page now opens a section of its own at the '# ' line.

first-run.md's numbered items carry a picture each, indented three spaces under the marker with a blank line between. A line-at-a-time parser read the continuation as a four space code block and printed five raw '![...](...)' into a grey box. A list item's body now goes back through the same block parser, so an item is a run of blocks and not a line of text.

Ruled out on the way: 'background-attachment: fixed' for the blurred scene. It repaints the whole image every scroll frame, which on a 2733 pixel window was enough to stop the renderer answering a screenshot, and iOS ignores it. Two fixed pseudo elements instead.

Gate: ./scripts/check.sh at 0 warnings / 0 errors, 322 files, with bake-guide-site --check in the loop beside commands and nav.
