---
revision: 5
id: 01M25WK1EPDR4SRMJM6QQ7100J
---

Cause. The picker label and hint in src/UnitFrames/Panel.lua were written when only the warrior had a class file. Fix. Both say 'your class'. Class.Label() stays out because the label is set once at panel build and answers 'character of unknown class' before the client names the class. Gate. No harness section quotes the text; the pre-commit run passed.
