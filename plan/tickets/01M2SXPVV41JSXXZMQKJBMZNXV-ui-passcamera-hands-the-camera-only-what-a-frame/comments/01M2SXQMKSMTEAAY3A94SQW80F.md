---
revision: 5
id: 01M2SXQMKSMTEAAY3A94SQW80F
---

Landed 707c480. The live 2.5.6 client has no SetPassThroughButtons, so the three wrong rows only misbehaved on a client that has it; the fix is in the decision, not a symptom anyone saw on 2.5.6. Buttons/Square.lua stays hung by hand: an empty square closes the box with Tip.Close(true), which Hang does not do. Bags/Grid.lua still makes no pass at all; with Keep it would pass only the middle button, which buys nothing.
