---
revision: 5
id: 01M2Z5KCN36KC1PTR86KQ7ZW5H
---

Review of the fix before it lands: the LABEL table aliases negative remaining onto the whole-second readings. Quantum negates on the tenths arm, so a remaining of -2 s came back as 20, which is the key the 20 second reading sits on, and the square would have drawn a plausible 20 where the old code drew an obviously broken -2.0. Reachable whenever the client has not cleared a cooldown by the next tick and the stale read is a second or worse. A silently wrong number is worse than a visibly wrong one, so it is worth the comparison. Fixed by giving Quantum an EXPIRED sentinel of 1, which sits outside all three key ranges and reads as no label, so the square draws blank. Checked every boundary either side: -5.5, -2, -1, -0.5, -0.05 all blank, 0.0 through 179m unchanged. 04-ability-square still green, 0.00 KB over 330 swept readings.
