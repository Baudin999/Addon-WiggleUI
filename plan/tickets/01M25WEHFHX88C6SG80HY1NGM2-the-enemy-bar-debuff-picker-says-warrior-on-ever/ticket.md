---
revision: 5
id: 01M25WEHFHX88C6SG80HY1NGM2
type: task
status: doing
title: The enemy bar debuff picker says warrior on every class
---

src/UnitFrames/Panel.lua labels the picker "add a warrior debuff", and its
hint says "the warrior's own debuffs" and "another warrior's Sunder". The
picker lists ns.EnemyBars.Suggestions(), which is the class's own table, so
a priest sees Shadow Word: Pain under a label that says warrior.

Fix: say "your class" instead. Class.Label() cannot go in the label: the
picker text is set once when the panel is built, and before the client names
the class it answers "character of unknown class".
