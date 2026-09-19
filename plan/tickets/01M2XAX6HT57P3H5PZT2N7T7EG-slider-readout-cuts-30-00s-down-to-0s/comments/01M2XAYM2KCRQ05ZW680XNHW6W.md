---
revision: 5
id: 01M2XAYM2KCRQ05ZW680XNHW6W
---

Fixed in 6380e5e. UI/Widgets.lua Readout() measures format(low) and format(high) before Paired and sizes the value field to the wider; Slider and Stepper both use it. 17-zoom-page asserts readout width >= string width with a '%.2f seconds' format, because the harness glyph advance (0.53 em) fits '30.00s' in 40 px where the game's Sans.ttf does not; it fails on the old 40 and 44.
