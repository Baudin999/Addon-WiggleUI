---
revision: 5
id: 01M2SS1NPQMZZJR32ES5B8T88A
---

Landed 34e3da0 on top of 0475bbd (UI/Press.lua). Unverified live: (1) that a real mouse release on a Press.Button child of the aura header runs cancelaura in combat; (2) that the header's C_UnitAuras.GetUnitAuras index agrees with UnitAura's index on 2.5.6, which the row draws from. If a square cancels its neighbour, it is (2).
