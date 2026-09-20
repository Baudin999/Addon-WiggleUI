---
revision: 5
id: 01M302MST6BBDQTQF8FZ6131VD
---

Phase 1 is on worktree-gearsets at e2467b54. src/Sets/{Sets,Wear,Feature}.lua, both TOCs, a scripts/trees.lua entry and scripts/harness/sections/52-sets.lua.

Shape. Four files became three: the card's Key.lua is twenty lines and it is the one thing Sets.lua is about, so it is in Sets.lua. Apply.lua is Wear.lua, because ns.Sets.Wear is the call and a file named for the call is one less indirection.

The API is the comment's list, plus ns.Sets.Plan(name, world), ns.Sets.World(), ns.Sets.Slots(), ns.Sets.Label(slot), ns.Sets.Key(link), ns.Sets.Describe(name) and ns.Sets.Running(). Plan and World are what make the harness section possible without a client stub for gear.

Two things worth not re-deriving.

The reservation is two flags and not one. A worn slot that is already right may not be a source; a worn slot whose piece has been promised elsewhere may still be a target. One flag for both makes two rings trading places come out as lift 12, drop 11, stow, which is a move and a half and a bag slot, instead of lift 11, drop 12, drop 11. That is the first thing 52-sets.lua caught.

The key's id comes off ns.ItemKind and not off field 2 of the link. The harness writes every fixture link with itemID 1 and carries the real id in the fixture table, so a key read straight out of the string keys every item alike and every scene in the section passes for the wrong reason.

Still open for the next phase. Character -> Sets needs its own scripts/trees.lua entry with SetRow.lua's exact call count, and SetRow.lua must not capture ns.Sets at file scope: the toc loads it inside the Character block, above Sets\Sets.lua. The line for 52-sets goes in runner.lua at merge. ns.Class.Spec.Group and ns.SetActiveSpecGroup are called through type() probes, so the dual-spec branch can land under this one either way.
