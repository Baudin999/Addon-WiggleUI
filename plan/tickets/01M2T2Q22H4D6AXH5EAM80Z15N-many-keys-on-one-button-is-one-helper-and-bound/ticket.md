---
revision: 5
id: 01M2T2Q22H4D6AXH5EAM80Z15N
type: task
status: todo
title: "Many keys on one button is one helper, and Bound holds every override"
---

Marking/Keys.lua and Hover/Cast.lua run the same many-keys loop (held, heldAny, proven, warn once, the unproven status line). Marking, Cast and Buttons/Bars.lua wrap SetOverrideBindingClick and ClearOverrideBindings by hand; AdHoc/Bars.lua, Charge/Icon.lua, Core/BlizzAdapter.lua and Bound.Key call them bare. All of it moves to UI/Bound.lua. The hover item path (/use) goes through the same helper on the same down edge. Every key-to-button path is checked for the edge bug.
