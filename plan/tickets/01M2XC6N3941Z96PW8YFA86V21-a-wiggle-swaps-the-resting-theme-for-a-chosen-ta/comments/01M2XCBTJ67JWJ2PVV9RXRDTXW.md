---
revision: 5
id: 01M2XCBTJ67JWJ2PVV9RXRDTXW
---

Landed in c515231. Settings wiggleInformational/Immersive/Exploration (none or a theme) and wiggled. Theme.Aim reads the drawn theme's target, starts or stops the 'wiggle' tick and re-pins; called at ADDON_LOADED, from the picker and /wk wiggle. chosen is the table on screen, so Theme.Mode follows a swap. Untouched(key) keeps an element unveiled only when it is 'show' in both themes. Non-hover modes now UI.Unreveal first. Themes.RAIL decides the rail style per theme. Target change is live; theme change is still at /reload. Unverified in the client.
