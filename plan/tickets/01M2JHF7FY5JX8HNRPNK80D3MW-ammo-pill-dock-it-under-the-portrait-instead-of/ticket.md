---
revision: 5
id: 01M2JHF7FY5JX8HNRPNK80D3MW
type: task
status: doing
title: "Ammo pill: dock it under the portrait instead of offsetting it"
parent: 01M2JFZRDAXDJT8RD2809SDK6S
---

Seen in the client on 2026-09-15: the pill still reads as floating over the bottom of the portrait. It was anchored to the portrait with a computed drop, which is an offset and not a dock.

- Dock it: the pill's top corner on the gauge side pinned to the portrait square's bottom corner on the same side, sharing the block's bottom hairline. No offset beyond that one pixel.
- Harness 10-ammo-pill asserts the dock point, the square it hangs off and the shared hairline.
