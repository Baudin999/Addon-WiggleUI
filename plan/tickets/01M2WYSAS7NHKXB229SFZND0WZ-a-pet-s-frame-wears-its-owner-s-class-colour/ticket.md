---
revision: 5
id: 01M2WYSAS7NHKXB229SFZND0WZ
type: task
status: todo
title: A pet's frame wears its owner's class colour
---

`Color.OfUnit` (`Unit/Color.lua`) gives players their class colour and
everything else its reaction colour, so a hunter's pet block draws friendly
green beside the hunter's own class green. Two near greens side by side read
as a mistake.

Fix: a pet token (pet, partypetN, raidpetN) takes its owner's class colour.
The power strip, focus against mana, is what tells the two apart.
