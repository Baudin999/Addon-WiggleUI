---
revision: 5
id: 01M2X8GS48FVPRE9MQ3CXN63BY
type: feature
status: todo
title: "Every frame scales by the screen over 1440, and one general size"
---

On a 4K panel the windows and chat took a whole screen step of 2 and the HUD
took none, so chat drew a third over the author's size and every bar and frame
two thirds of it. The grid in UI/Pixel.lua now scales every adopted frame by
the screen's height over 1440 times a general size, and each screen's own zoom
multiplies on top. The setup's first question is the general size, shown live.
