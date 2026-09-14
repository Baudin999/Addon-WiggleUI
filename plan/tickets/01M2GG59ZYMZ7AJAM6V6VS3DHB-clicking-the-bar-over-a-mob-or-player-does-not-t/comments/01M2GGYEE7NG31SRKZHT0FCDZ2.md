---
revision: 5
id: 01M2GGYEE7NG31SRKZHT0FCDZ2
---

The first fix did not work in game. Resizing and the default were real faults, but not the one stopping the click.

Cause. Blizzard_NamePlateUnitFrame.lua calls EnableMouse(false) on the plate UnitFrame in OnLoad: 'Nothing in the nameplate is clickable. Hit testing is done at the C++ level'. A plate click is meant to reach the world. Marking.lua hooked OnMouseDown on every plate's UnitFrame on NAME_PLATE_UNIT_ADDED, a mouse script turns the mouse on, and the UnitFrame ate every click. bars clickthrough and bars camera were workarounds for that hook, built on the belief that plates arrive mouse enabled.

Fix. The plate hook is gone; ctrl-click marking on a plate goes through Keys.lua's mouseover override like the world. PlateMouse, PlatePassThrough, CameraState, both settings, their panel rows and words are gone, and barsClickThrough, barsMouseThrough and barsCamera are in RETIRED.

Gate. Section 08 checks that no plate or UnitFrame carries OnMouseDown or has its mouse on, and that SetNamePlateSize survives a driver reset.
