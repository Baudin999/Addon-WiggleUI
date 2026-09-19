---
revision: 5
id: 01M2WGT0ZXE6GQDAKVPGNTSCG7
---

Landed in b7d4172. Floor 0.35 scale, tint 0.35 (0.5 in the mock read too dark), border 0.2. One slip caught by the section run: Tooltip.lua calls Gauge.Paint with a nil bar, so the track-alpha read is guarded. Not seen in the client; unverified there: whether the rails' corners at 0.2 clear the rail text at the zoom he plays.
