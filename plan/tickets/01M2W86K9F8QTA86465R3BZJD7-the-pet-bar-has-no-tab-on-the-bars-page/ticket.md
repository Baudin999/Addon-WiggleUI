---
revision: 5
id: 01M2W86K9F8QTA86465R3BZJD7
type: task
status: doing
title: The pet bar has no tab on the bars page
---

The bars page builds its tab strip from `ns.WhichBars.PLAN`, which holds the five
action bars. The pet bar stands outside that plan (src/Buttons/Pet.lua), so it
got no tab, and its shape, size, colour and hours could not be set at all.
