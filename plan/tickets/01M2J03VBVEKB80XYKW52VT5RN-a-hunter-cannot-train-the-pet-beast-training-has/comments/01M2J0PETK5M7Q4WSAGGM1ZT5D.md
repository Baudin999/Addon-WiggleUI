---
revision: 5
id: 01M2J0PETK5M7Q4WSAGGM1ZT5D
---

Cause. 2.5.6 has no pet talent tree; a pet learns through Beast Training (spell 5149), a craft session. N had no way to reach it.  Fix. b65fccb: Pet tab on a hunter's talent window. Talents/Training.lua reads the session via Core shims, Talents/Pet.lua draws the abilities and teaches with DoCraft. The Beast Training square is secure on UIParent, placed over the page and hidden in a fight by a state driver, so the window stays insecure. CraftFrame is parked while the page holds the session; closing the window calls CloseCraft. BlizzAdapter.Park no longer marks a frame parked before it exists.  Unverified in game: GetCraftInfo's cost 6th and level 7th are read off Blizzard_CraftUI/TBC, and the secure square's placement at the page's effective scale.  Gate. scripts/harness/sections/67-pet-training.lua; check.sh green in the pre-commit hook.
