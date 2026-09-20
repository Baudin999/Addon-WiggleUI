---
revision: 5
id: 01M2Z5FZFRG36MHNRCX3NW75JR
---

Done in `scripts/check.sh`, in the hot_scan awk. Written against the fixture first and confirmed red on Countdown as it stood before Ability.lua was touched.

The rule. Three awk functions on top of what was there. `shielded(depth)` is the guard test the foot of the program already made, lifted out so the chain walk and the guard cannot disagree about what "reached on every call" means. `arm_shut` closes one arm. `chain_shut` closes a chain and decides what it is worth. State is per indent: where the chain opened, whether every arm closed so far allocated, whether the arm being read has, whether there is an else, and whether the `if` itself was shielded.

Refused only when the chain has an else and every arm allocates. A chain with no else always has the fall-through, which is a real branch and usually the common one. An else that returns or writes a constant is a free arm, which is what keeps `Ability.Draw:683` and the addon`s other honest chains green.

The part that took the second attempt. A chain whose every arm allocates *is* an allocation, so it is refused where an allocation would be refused and otherwise handed up as the enclosing arm`s own allocation. Without that, `Chat/Feed.lua:357` Feed.Handle failed: its inner chain builds the line either way, and reading it on its own says every arm allocates. Its outer chain has an arm that is `body = text` and builds nothing, so the allocation is not on every call and it is not a defect. With the composition in, Feed.Handle passes for the right reason and a chain buried one deeper inside an all-allocating chain is still caught. `NestedChain` and `NestedFree` in the fixture are exactly those two shapes.

One pre-existing bug fixed on the way, and it had to be. The blank/comment skip ran *after* the two depth loops. A blank line carries no tabs, so its indent is zero and it closed every block open in the function: a guard stopped working at the first empty line under it. It changed nothing on the live closure, 0 findings before and after, but an arm with a blank line in it would have been two arms to the chain walk. `Spaced` in the fixture holds that.

The fixture. Ten functions in a heredoc in check.sh, written to a mktemp, one awk run each, a name:refused|passed list beside them. It is not Lua the addon loads, it never reaches a TOC, and the exemption allow-lists only read under src/, so it cannot drift into being a real file. Silencing the chain rule makes three of the ten fail and the block exits 1, so it is a gate and not decoration. That answers the card`s "add a fixture rather than proving it against live source".

The two other holes the card listed.

The exemption ratchet is already done. `exemption_list allocates ALLOCATES_ALLOWED` counts `-- allocates:` per file and fails in both directions; the card was written against an older check.sh. Nothing to do.

A guard that is a constant, and a guard that tests something the tick just wrote, both still read as guards. So does an allocation inside a `for` loop inside an arm, because an arm is judged on the statements at its own depth and a deeper line is inside something else. All three are written into the comment above the rule as the next holes, deliberately and not silently. None of them is what the minute log points at today.

Gate. The rule prints one new finding across all 651 functions of the live hot closure and it is Countdown at `UI/Ability.lua:564`; after the fix on the sister card it prints none. The fixture block exits 0. ratchet.lua on check.sh against its committed copy: 0. bash -n: clean. check.sh itself was not run, by instruction; the awk was extracted to a scratch file and driven against the fixtures and against src/ directly.
