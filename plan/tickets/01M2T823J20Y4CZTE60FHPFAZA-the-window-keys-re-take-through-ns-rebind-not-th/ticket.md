---
revision: 5
id: 01M2T823J20Y4CZTE60FHPFAZA
type: task
status: todo
title: "The window keys re-take through ns.Rebind, not their own event frame"
parent: 01M1XJZTYTM8VZ58PYTW463913
---

Core/BlizzAdapter.lua registers UPDATE_BINDINGS on a frame of its own to mark its borrowed keys dirty. That is Core's ns.Rebind rebuilt beside Core's, which item-26 says goes. Buttons/Bars.lua answers the event itself on purpose (Core's comment allows it) and Buttons/Pet.lua only reads keys to draw them.
