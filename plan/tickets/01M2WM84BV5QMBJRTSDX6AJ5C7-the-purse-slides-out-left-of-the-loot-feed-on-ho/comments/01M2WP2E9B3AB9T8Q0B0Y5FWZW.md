---
revision: 5
id: 01M2WP2E9B3AB9T8Q0B0Y5FWZW
---

Cause. The purse was a three-cell strip under the loot feed with a once-a-second ticker and a tooltip on top; it added empty height under the rows and read as a status bar bolted onto a list.  Fix. a35c130: the strip and its ticker are gone. The header's right end shows the session's takings in heading gold through a generic Feed:Aside, rewritten on money events, and holds the header up with no title. Hovering it for Tip.HOLD slides the ledger out from behind the feed's left edge (right edge near the left of the screen): a tooltip surface on the painted floor in a clipping frame one level under the feed, Feeds/Drawer.lua. Leaving figure and panel waits the same HOLD and slides it back; re-entry mid-slide reverses from where it stands. Motion is the drops' Ease.out over lootFloatSeconds on the shared tween tick. lootFeedPurse stays and switches figure and panel.  Gate. 35-purse and new 81-purse-drawer; check.sh marker lists and Perf ORDER updated. Full check.sh on the integrated tree: exit 0, 0 warnings / 0 errors in 296 files.
