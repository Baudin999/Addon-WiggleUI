---
revision: 5
id: 01M2QP151Z2AXFG7XRQNYTJA4E
---

First session with the new columns, 14:25 to 14:35 on 17 September, 11 minutes, no plateau.

Whose leak. DialogueUI 2359 KB and Auctionator 3315 KB, the same figure every minute, so both are cleared. WarriorKit lows 17.5 and 16.0 MB. Questie lows 45.6, 48.6, 50.3, 53.6 MB at minutes 3, 6, 7, 10, which is 1.1 MB a minute against a floor climbing 1.6. Questie is the leak, most of it at least. floor less addonsKB is too noisy at one sample a minute to say whether the client's own code holds the rest.

Garbage. alloc is 457 to 609 MB a minute for the whole client, 100 KB a frame, in a quiet minute as much as a busy one. oursAlloc is 1.3 to 6.3 MB of that, so this addon's tickers are under 1% and the lint is doing its job. allocKey is action nearly every minute at 0.8 to 4 MB, which is small and is still a ticker allocating where check.sh says none does. oursKB swings 16 to 54 MB with under 6 MB of it made in a bracket, so either an event handler of ours makes it or the client bills us for Blizzard code running under our taint. Not known which.

Slow frames. 14 to 41 a minute, slowKey frame, slowOurs under 9 ms a minute in all, beat 0 to 5. They carry 75 to 400 KB each against 100 KB for an ordinary frame. Too few to call and none of it is the plateau.

Instrument, uncommitted. The perf window's third cost row now reads Lua memory made in the last second for every addon, from a new made column in the frame ring. Switch a feature or an addon off and the figure drops within the second or that was not the source. Section 77 ok, luacheck 0 and 0, static half of check.sh status 0.
