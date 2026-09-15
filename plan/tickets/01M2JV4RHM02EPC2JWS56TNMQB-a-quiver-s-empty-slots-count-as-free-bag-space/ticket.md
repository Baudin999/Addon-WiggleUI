---
revision: 5
id: 01M2JV4RHM02EPC2JWS56TNMQB
type: bug
status: done
title: A quiver's empty slots count as free bag space
---

The footer's free count adds in the empty slots of a quiver, an ammo pouch, a soul bag or a herb bag. None of those take ordinary items, so the number overstates your room.

Fix. Read each bag's family off the second return of GetContainerNumFreeSlots, the call Baganator makes in Sorting/BagUsageChecks.lua. A bag with a family other than 0 keeps its slots out of the footer, and its empty slots fold into a pile of their own under the bag's name: one square with the count, like the Empty pile.

Files. src/Core/Core.lua, src/Core/Piles.lua, src/Bags/Bags.lua, src/Bags/Grid.lua, scripts/harness/client/04-hands.lua, scripts/harness/sections/55-bags.lua.
