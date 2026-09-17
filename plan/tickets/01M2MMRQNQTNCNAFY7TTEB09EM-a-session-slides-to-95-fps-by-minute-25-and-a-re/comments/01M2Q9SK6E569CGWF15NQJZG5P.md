---
revision: 5
id: 01M2Q9SK6E569CGWF15NQJZG5P
---

Read of the two 17 September sessions, 10:15 to 10:36 and 10:43 to 11:00, the first with floor and oursKB.

Floor. 130.8 MB at minute 2 to 162.1 at minute 21, and 130.1 to 154.2 across 15 minutes of the next. 1.65 MB a minute both times, straight line, back to 106 MB on reload.

Ours. The lows of oursKB are 16.1, 16.0, 16.5, 18.8 MB at minutes 3, 11, 14, 19 and 18.4, 14.1, 18.4 in the second session. A leak of ours at that rate would put the minute 19 low near 45 MB. Floor climbs alone, so the leak is another addon's. Details, Baganator, OPie and Syndicator are disabled in AddOns.txt, which leaves Questie 11.37.1, Titan, Auctionator, DialogueUI, Clique, Leatrix_Plus.

Not the slowdown. Minutes 18 to 20 of the first session ran 3533 frames at 16.98 ms. That is maxFPSBk 61 in Config.wtf, the window out of focus for about 72 s. 5136 and 4759 frames in the minutes either side solve to 21 s and 30 s at 58.9 fps, and over12 agrees to within 2 s.

Suspect for the 10 Hz signature. Questie runs two unconditional C_Timer.NewTicker(0.1) loops, QuestieMap.lua:218 and QuestieCombatQueue.lua:17. The first resumes a coroutine that walks HBDPins.activeMinimapPins and calls FadeLogic and GlowUpdate per pin, so its cost follows the pin count. Not tested. Neither session ran past minute 21, so neither reached the plateau.

Also seen. freed is 320 to 390 MB a minute in the world and 70 to 105 at the auction house. oursKB swings 16 to 57 MB inside that, so about half the garbage the collector chases is ours. Separate from the leak and worth its own card.

Next. One 35 minute session with Questie disabled. If floor stays flat and minute 27 stays clean it is Questie. Or log every addon's KB low per five minutes so the log names it.
