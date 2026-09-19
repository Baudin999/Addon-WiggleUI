---
revision: 5
id: 01M2WPZZ0HW87D1MA5MR4KNXRY
---

Landed fa5ae3d. UI/Tooltip.lua holds TYPES (key, label, default) and one placement per type; Tip.Open/Settle/Hang take the type as the third argument, before above, and Tooltip.Show asserts it. Map pins got their own type because UI/Chart.lua marks were the one icon hover not on the agreed list. Bottom left is DOCK units off the left edge at CONTAINER_OFFSET_Y. The marker is FULLSCREEN_DIALOG so the options window does not cover it, and the page's stack frame OnShow/OnHide drive Settings.ShowAnchor. Shade is a black BACKGROUND -5 texture: above the painting's corners, under the BORDER gauges. tipPlace retired; a player who had set the old global to beside or anchor lands on the per-type defaults. Gate: check.sh refuses Tooltip.(DOCK|BESIDE|RIGHT|LEFT|ATTACHED|ANCHOR) outside Tooltip.lua and Settings/.
