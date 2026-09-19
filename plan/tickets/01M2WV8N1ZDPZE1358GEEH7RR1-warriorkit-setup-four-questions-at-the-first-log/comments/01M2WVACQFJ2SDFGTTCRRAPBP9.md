---
revision: 5
id: 01M2WVACQFJ2SDFGTTCRRAPBP9
---

c98517e. Setup/Previews.lua draws the cards, Setup.lua is the window, Feature.lua registers it and adds the game menu button through the new ns.GameMenu.Add. Harness 00-setup runs right after login. Not yet done: rebaking Shipped.lua from the live WTF. That bake moves about ten keys (tipFont 11, buffPulse, hitsLife 1.5, questsTabs across, skinFrames) that sections 53, 80, 85 and the tooltip font checks pin to the old values, and it shows that a reset hook writes its own skinFrames literal.
