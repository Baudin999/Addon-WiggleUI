---
revision: 5
id: 01M2JZFC1MNHE5X413FE4Z0D30
---

Cause. Meter/Threat.lua took an exponential average of half second deltas of the scaled percentage. The percentage divides by the tank's total, which steps up every blow, so the rate dipped negative after each of the tank's hits and the projection only drew while it was positive. An empty threat table read 'held', the same word as a held mob with rows. Fix. Sample the fifth return, derive the threshold as value * 100 / pct, keep six half second marks of both, and project on (member gain - threshold gain) over the window. A value drop or a threshold drop past 5% restarts the window. The header says 'no threat' with a hostile target and no rows. Gate. 25-meters: the projection is 1.5 s off the window, a tank lump mid-climb still projects 11.875 s, an empty table reads 'no threat' with no rows. Not proven: why the client returns nothing for the whole group in play. The new header word says which case it is next time it happens.
