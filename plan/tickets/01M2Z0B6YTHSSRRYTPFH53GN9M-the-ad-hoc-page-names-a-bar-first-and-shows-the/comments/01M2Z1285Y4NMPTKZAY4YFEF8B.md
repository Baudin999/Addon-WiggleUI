---
revision: 5
id: 01M2Z1285Y4NMPTKZAY4YFEF8B
---

Done in 0c02ea8f.

Shape. Bars.Radius and Bars.Where are public and Arrange goes through them, so the page multiplies one number (EDGE over Bars.SIZE, which is 27 over 54) and lays nothing out itself. The angle is written twice in the addon now, here and in the snippet, and the snippet's copy cannot be helped: a restricted environment cannot call Lua.

The middle square is the place after the last one, so Landed's drag into the middle lands on Move(from, count + 1), which AdHoc.Move clamps to the end. That was free; nothing in AdHoc.lua changed for it.

What I ruled out. A tab that turns into an edit field on the plus, which needs an EditBox anyway and puts the keyboard on a frame the strip rebuilds on every refresh. A permanent 'new bar' row under the strip, which is a second name field on a page that already has one. The empty square as a seventeenth position on the circle, which is the version where the circle you are looking at is never the circle you get.

76-adhoc measures the drift between the page's squares and Bars.Where at 0.0 units on a ring of four. Flip the comparison to drift < 0 and it fails, so the check runs.

Not done here: UI.Field has one caller besides ui.TextField and the other six copies are 01M2Z0BMX0R0Y7FZS8YRK4CQAR. The drop square work on 01M2TFMSF6DSMVA60KRR9ESQNJ now has a ring to fold in rather than a fourth wrapped row.
