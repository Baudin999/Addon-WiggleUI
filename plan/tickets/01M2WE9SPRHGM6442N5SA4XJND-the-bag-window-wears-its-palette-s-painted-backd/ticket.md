---
revision: 5
id: 01M2WE9SPRHGM6442N5SA4XJND
type: task
status: doing
title: The bag window wears its palette's painted backdrop
---

art/forrest.jpeg and art/desert.jpeg are painted frames on white. Bake each into
nine TGAs in src/Media (four corners, four rails, one middle), with the white
flooded to alpha, and draw them behind the bag window when the drawn palette is
forest or desert. Dark keeps the flat fill.

- scripts/bake-backdrops.sh: flood the margin from the corners, cut one repeat
  of the middle (about 335 x 346 px) and cross-fade its seams, cut each rail
  between its ornaments, darken the middle 40% so the icons read, resize every
  piece to powers of two.
- UI/Backdrop.lua: nine textures, corners fixed, rails tiled along their length,
  middle tiled both ways. SetTexture(path, "REPEAT", "REPEAT") plus
  SetHorizTile / SetVertTile, which Titan and Details make on this client.
- UI.Window takes `backdrop = true`; Bags/Window.lua passes it.
- Gate: every palette on Theme.PALETTES either has a backdrop entry naming all
  nine pieces or says false, checked at load like the colours.

The desert image is getting regenerated; the darkening stays in the bake so a
new source only needs a re-run.
