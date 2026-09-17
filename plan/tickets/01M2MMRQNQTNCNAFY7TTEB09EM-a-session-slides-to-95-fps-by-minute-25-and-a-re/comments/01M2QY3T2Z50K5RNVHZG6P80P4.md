---
revision: 5
id: 01M2QY3T2Z50K5RNVHZG6P80P4
---

Second session after the fix, 16:42 to 16:59 on 17 September, 18 minutes. over12 is 0 to 3 from minute 2 on, with one 9, and beat is 0 in every row. The 14:49 session had over12 at 160 and beat at 117 by minute 18. qQueued 0 to 30. alloc 2 to 22 MB a minute. Questie 37.0 to 37.9 MB with two one minute bumps to 38.8 and 39.7, WarriorKit 8 to 15 MB, addonsKB 50.8 to 58.8 and flat.

floor is no longer a clean reading. With this little garbage the collector runs a pass every second minute, freed is 0 in the minutes between, and the low of a minute with no pass in it is only the heap before the next one. Read after a pass instead: heap less addonsKB is 77.4 MB at minute 2, 79.2 at 7, 81.4 at 9, 84.2 at 11, 86.0 at 13, 85.0 at 16. So about 0.5 MB a minute is still growing and no addon holds it, which leaves the client's own interface code. It has no ten a second cost riding on it. Whether it levels off is for the long session to say. Still in review: 18 minutes is short of the 21 to 27 where the plateau used to start.
