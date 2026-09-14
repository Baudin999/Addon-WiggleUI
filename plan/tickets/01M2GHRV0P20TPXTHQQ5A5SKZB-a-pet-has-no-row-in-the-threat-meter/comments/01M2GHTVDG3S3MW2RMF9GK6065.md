---
revision: 5
id: 01M2GHTVDG3S3MW2RMF9GK6065
---

Cause. Meter/Threat.lua walked Roster.Units(), and Roster only ever put a pet into units and owners, never into order. Fix. Roster.Fighters() is order with each pet after its owner; the threat sampler and Rank walk it. Pets are noted in known under their own name and the owner's class, so the row reads as the hunter's. Units() is unchanged because the party frames, quest party and enemy bars walk it. Gate. 25-meters gives partypet1 60% and checks four ranked rows, the Wolf as HUNTER, and the row gone when its threat is. Not covered: the enemy bars' Threat.Top still ignores pets.
