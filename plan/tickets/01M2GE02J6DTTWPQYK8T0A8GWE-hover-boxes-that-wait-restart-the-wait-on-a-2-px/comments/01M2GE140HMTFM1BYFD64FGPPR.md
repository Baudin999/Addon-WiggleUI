---
revision: 5
id: 01M2GE140HMTFM1BYFD64FGPPR
---

Cause. Tip.Settle read GetCursorPosition every frame and reset the wait on any move past DRIFT = 2 physical pixels. At 3440x1440 a resting hand passes that, so the 200 ms bag wait and the 0.15 s chrome wait kept restarting.  Fix. The wait counts from OnEnter and only OnLeave cancels it. DRIFT, heldX/heldY and Pointer are gone. Settle on the same owner mid-wait keeps the count and takes the new subject, which the bag Follow re-enter relies on.  Gate. 74-bag-hold moves the pointer 10 units mid-wait and re-enters the square, and asserts the count carries on both times.  Not this. Quest column rows open no box (Lit only shades), and quest window rows use Tip.Hang, which opens at once.
