---
revision: 5
id: 01M2WB8JAG3QW8DRSM1HAWK0RX
---

Landed in 582c81d. The table is src/Theme/Themes.lua: 21 elements, three themes, one cell per element per theme (show, hide, hover or a fraction). Immersive: player and target at 0.2, everything else hidden. Exploration: bars, chat and quest tracker on hover; loadout stays shown because it only appears while its key is held. Palettes are src/Theme/Dark|Forest|Desert.lua, painted into UI.Color at ADDON_LOADED. Picked with /wk theme, /wk palette or the Theme page under The screen; a reload applies it. Mechanism is UI.Veil and UI.Reveal in src/UI/Veil.lua. Not worn, by design: enemy bars on plates and the Charge marker change parent per plate, so they ask ns.Theme.Mode instead of being veiled; the chat input line stays on UIParent so enter still works in immersive. Open: the bar drag handles still show over a hidden bar while barsLocked is off; Look.SetCombat and SetKey stay per bar and were not moved into the theme.
