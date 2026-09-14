---
revision: 5
id: 01M2GJZC75CBNJRK4BDDVH8XVD
---

Cause. Threat.State and Threat.Swinging in src/Unit/Threat.lua only asked about player. A mob on your pet came back as one of your two colours, and Roster.Size() counts no pets, so solo with a pet was the tank view.  Fix. Color.threat.pet is HUE.cyan, a new hue that is not the rested blue. State asks ns.Threat("pet", unit) when UnitExists("pet"), before the no-threat-of-your-own return, and answers the pet tone with your own percent. Swinging answers it when the mob's target is your pet. The hover in Meter/Standing.lua reads "your pet's, you are at N%".  Gate. The behind-the-tank block in scripts/harness/sections/25-meters.lua puts a pet on the mob as tank and as dps and checks State and Swinging answer the pet tone, then that a pet not holding the mob draws something else. Section 25 alone is ok.
