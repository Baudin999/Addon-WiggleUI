---
revision: 5
id: 01M2GJVVQ3JV4JQ7KSFGQVCH8W
type: bug
status: todo
title: Your pet holding a mob is drawn as you holding it
---

When your pet holds a mob, the enemy bar draws it in one of your own two
threat colours, so it reads as if you have aggro.

Where. `src/Unit/Threat.lua`, `Threat.State` and `Threat.Swinging`. Both only
ask about `player`. `Roster.Size()` counts members and not pets, so solo with a
pet is the tank view.

Fix. A fifth tone, `Color.threat.pet`, in its own hue. `State` asks
`ns.Threat("pet", unit)` before anything else and answers the pet tone with
your own percent when the pet is tanking. `Swinging` answers it when the mob's
target is your pet.
