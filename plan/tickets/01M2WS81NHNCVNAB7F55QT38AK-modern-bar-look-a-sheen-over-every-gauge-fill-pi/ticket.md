---
revision: 5
id: 01M2WS81NHNCVNAB7F55QT38AK
type: task
status: doing
title: "Modern bar look: a sheen over every gauge fill, picked on the Theme page"
parent: 01M2WS81HMRRABBTW1DEJ175G8
---

`UI/Gauge.lua` builds every gauge; `Gauge.New` lays two halves over the fill when the drawn look is modern:
white fading down to nothing over the top half, nothing fading to black over the bottom. `ns.Gradient`
(Core/Core.lua) draws them once at build, so the tick writes nothing new. `ns.db.barLook`, default flat,
read through `Theme.BarLook()` so a relayout before the reload cannot draw half of it.
