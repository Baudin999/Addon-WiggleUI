---
revision: 5
id: 01M2GJ3J1Q2D8CYTTGVEYKRFY5
---

Cause. Threat.State and Threat.Swinging in src/Unit/Threat.lua only had the tank's scale: mob on you green, mob on anyone else red.  Fix. A local Tanking() is Roster.Size() < 2 or Role.Of("player") == Role.TANK. When false, State answers red with the nearest challenger's number for a mob on you, and Threat.Shade(your scaled percent) with your number for a mob on the tank. Swinging swaps green and red the same way. Solo stays the tank view, because alone every mob is on you. Stance is not read: a warrior in defensive stance with Arms talents sets the role by typing an override.  Gate. scripts/harness/sections/25-meters.lua has a block in the three-member group that types the role as dps then tank and checks green, amber and red on State and both Swinging colours.
