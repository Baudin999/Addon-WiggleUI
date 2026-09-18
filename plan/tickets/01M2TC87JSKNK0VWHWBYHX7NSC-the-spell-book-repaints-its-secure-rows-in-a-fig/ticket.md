---
revision: 5
id: 01M2TC87JSKNK0VWHWBYHX7NSC
type: bug
status: doing
title: The spell book repaints its secure rows in a fight and the game stalls
---

Opening the spell book in combat left the window half drawn and the game stuck. Window.Paint moved and showed every row in a fight, and each row is the parent of a secure square, so the client refused every one of those calls. The pet tab added UNIT_PET and the pet book as repaint triggers that fire in a fight.
