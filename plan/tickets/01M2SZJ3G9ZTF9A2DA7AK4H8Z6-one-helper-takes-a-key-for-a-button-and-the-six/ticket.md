---
revision: 5
id: 01M2SZJ3G9ZTF9A2DA7AK4H8Z6
type: task
status: done
title: "One helper takes a key for a button, and the six copies of Bind go"
---

Commit 0475bbd put secure button construction in UI/Press.lua, and the four cards after it stopped at construction too. The larger copy-paste in that code is the key the button is pressed by.

Taking a key is five steps: refuse in combat, refuse a bare mouse button, let go of the key, write down what it carried, take it and read the layer back. Perf/Key.lua and Dungeons/Key.lua were the same 130-line file with the names changed. Targeting/Switch.lua carried the same Bind, Holds, Apply and Describe line for line, AdHoc/Bars.lua the same Bind per bar, and Charge/Icon.lua the same Bind without the bare mouse button check. The override readback was written seven times (those five plus Marking/Keys.lua, Hover/Cast.lua and Buttons/Bars.lua) with two meanings for a blank layer, and seven files declared `BARE = { BUTTON1 = true, BUTTON2 = true }`.

UI/Bound.lua: Bound.Bare, Bound.Refusal, Bound.Under, Bound.Reads (the blank-layer answer is an argument, so both meanings stay), Bound.Take (the five steps), Bound.Describe, and Bound.Key(spec), a holder for one key in one ns.db field that registers its own ns.Rebind and holds Apply to the end of a fight.

Gate: check.sh fails on GetBindingAction, `BUTTON1 = true`, "cannot be rebound in combat" or `Displaced = displaced` in code outside UI/Bound.lua. 36 hits on the previous HEAD, none now.
