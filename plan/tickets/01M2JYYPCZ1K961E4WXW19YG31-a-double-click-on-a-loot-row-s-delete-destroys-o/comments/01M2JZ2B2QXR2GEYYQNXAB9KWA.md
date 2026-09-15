---
revision: 5
id: 01M2JZ2B2QXR2GEYYQNXAB9KWA
---

Cause. Rows never move, so after the cross or the can takes a row out the next entry repaints under the same button, and a bounced second click destroyed it. Comfort/Destroy.lua had solved this for the clutter card with its own DEBOUNCE and lastTake locals.  Fix. That guard moved into UI/Widgets.lua as UI.Debounce(seconds): a closure answering true once and false for 0.4 s after, nil until the first press so a press early in the client's clock still counts. Destroy.Take asks a ready() built from it instead of its locals. UI/Feed.lua builds one per feed in RowButtons and every row button asks it inside onClick, so both buttons on every row share the window.  Gate. 40-loot-watch.lua: two rows of linen, two presses of the cross in one instant destroy one and leave one row, a press after advance(1) takes the second. The blue press got an advance(1) in front so the guard cannot make it pass vacuously. 24-clutter-window's second-click check still passes through the helper.
