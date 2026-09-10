---
revision: 5
id: 01M25W5HN6V6NW5DDEVWSK62NS
---

Cause. LayoutWidget read widget.health:GetPoint() to find the gauge's middle. ApplyLayout runs LayoutWidget on bars already on plates, and the client throws on a positional read under a plate. Fix. Flow's Place records the rounded rectangle it gives each frame, Flow.Rect reads it back, and LayoutWidget takes gaugeMid and boxBottom from the gauge's node. Gate. The harness plate carries restricted = true, and the stub's GetPoint, GetLeft, GetTop, GetRight, GetBottom and GetCenter throw the client's message when the caller is addon code. HEAD's EnemyBars.lua fails that gate at line 1401, the line in the report. Finding. Release reads GetLeft and GetBottom off the widget while it is still on the plate, to fade it home on UIParent. That read throws too, so on the live client the leaving fade can never have run. The plate is hidden the moment its mob goes, so no mechanism puts that fade back. The path comes out: a leaving bar retires in the same frame, and fading in is unchanged.
