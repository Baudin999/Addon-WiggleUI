---
revision: 5
id: 01M2WSSJX3RQAYTP6G0H8MD58Y
---

Cause. b598dec named the setting barLook and the word bars; both belong to the action bars. Load error at Register, then Theme's loader wrote "flat" over the bars' per-bar table in WTF. Nothing caught it because core.hooksPath was unset, so b598dec, 2080660 and 7ffcd79 never ran check.sh.  Fix. 4ac80cf: gaugeLook and /wk gauges, MigrateGaugeLook repairs the saved table, plus what the gate then found (hint cap, Block.Place ratchet 136 to 106, theme NO_SWITCH reason). d0bf0c2 fixed a Settings shape failure that had also landed unguarded.  Gate. hooksPath is scripts/hooks again.
