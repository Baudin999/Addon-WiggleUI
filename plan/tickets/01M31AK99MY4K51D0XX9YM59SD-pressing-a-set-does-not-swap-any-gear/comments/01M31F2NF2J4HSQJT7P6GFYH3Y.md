---
revision: 5
id: 01M31F2NF2J4HSQJT7P6GFYH3Y
---

Landed at 119d0fc9. Both causes were as written.

Fix. Wear.lua:Run answers a stow with ns.Stow() rather than Ask("ClearCursor"), and Step falls through with `return Step()` after Skip. SetRow.Put reads the refusal ns.Sets.Put answers and prints it, which fixes all three call sites at once because they all go through that one door.

Gate. 52-sets.lua drives the queue against the client now: a stow leaves the cursor empty and a bag one fuller, and a gesture refused mid run leaves the queue advancing, says what it left alone, and lets the next word run. The staleness is made by emptying a bag slot from inside the first PickupContainerItem, which is what a bag sort or another addon looks like from in there; it has to happen before that call rather than after, because the stub fires the event synchronously and the whole rest of the plan is walked inside it.

Note for whoever reads this next. Three free bag slots is no longer asked for by a set holding three deliberate holes: Room counts a stow as spending one, and that was always right. What was wrong was that the stow never spent it.
