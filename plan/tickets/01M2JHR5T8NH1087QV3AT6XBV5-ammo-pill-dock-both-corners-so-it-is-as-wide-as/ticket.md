---
revision: 5
id: 01M2JHR5T8NH1087QV3AT6XBV5
type: task
status: todo
title: "Ammo pill: dock both corners so it is as wide as the portrait"
parent: 01M2JFZRDAXDJT8RD2809SDK6S
---

Seen in the client on 2026-09-15: docked at the bottom border, but only by one corner, and measured four digits wide.

- Dock both top corners: TOP<portrait edge> to BOTTOM<portrait edge> and TOP<gauge edge> to BOTTOM<gauge edge> of the portrait square, one pixel up for the shared hairline. The width comes from the dock and the pill is as wide as the portrait square.
- Icon on the portrait side. The number is anchored between the icon and the pill's far edge, centred. No string measured.
- The 9999 cap existed because the pill was four digits wide. The width is the portrait now, so the cap goes.
- Harness 10-ammo-pill asserts both dock points and the offsets.
