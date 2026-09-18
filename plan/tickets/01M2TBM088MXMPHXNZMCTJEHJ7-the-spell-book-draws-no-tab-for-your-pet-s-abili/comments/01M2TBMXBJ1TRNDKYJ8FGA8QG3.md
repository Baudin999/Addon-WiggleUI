---
revision: 5
id: 01M2TBMXBJ1TRNDKYJ8FGA8QG3
---

Landed in 7326078. Cause: Read.Tabs walked only BOOKTYPE_SPELL. Fix: a pet tab read off HasPetSpells and the pet book, armed by name(rank), hidden via Tabs:SetShown when the pet goes. Gate: 68-spellbook puts Kibble out and checks the tab, the armed spell, the drag and the tab leaving; full hook green, 0/0. Not done: right-click to toggle autocast, which Blizzard's pet page has.
