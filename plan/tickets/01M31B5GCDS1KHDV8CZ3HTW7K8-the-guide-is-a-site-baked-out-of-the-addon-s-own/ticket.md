---
revision: 5
id: 01M31B5GCDS1KHDV8CZ3HTW7K8
type: task
status: todo
title: "The guide is a site, baked out of the addon's own palettes"
---

GitHub Pages serves `docs/` off master. `scripts/bake-guide-site.sh` writes the
whole site there out of `docs/guide/*.md`, and `scripts/check.sh` refuses a
commit that leaves it stale, next to the two bakes that were already there.

What the bake does:

- `scripts/bake-guide-site.lua` loads the addon under `scripts/harness`, the
  way `bake-defaults.lua` does, and writes `docs/wiggle.css` out of
  `ns.Palettes` and `ns.UI.Metric`. No colour and no measurement is typed into
  the stylesheet. Eight palettes, twenty seven metrics, one `--zoom` that is
  the site's own because a browser will not scale twelve pixel prose the way
  the grid does.
- The markdown subset is closed and the parser refuses what it does not know,
  naming the file and the line. A renderer that skips an unknown line drops a
  paragraph off the published page and says nothing.
- The page copies the settings window: rail down the left, search in the title
  bar, the palette picker beside it. The window fill is the palette's own 0.97
  alpha over a blurred screenshot, so the translucency means what it means in
  the game.
- The wiggle works on the page. `scripts/site/site.js` is `UI/Wiggle.lua`
  constant for constant, six turns inside 1.2 seconds, each leg 60 long, deaf
  for a second after. On the site it steps the palette, because there is no
  addon on a web page to draw more or less of.
- Search is over every section, ranked so a section whose heading is the word
  beats one that mentions it.
- The thirteen screenshots go from 10.6 MB of PNG to 1.0 MB of WebP. The
  originals stay in `assets/`, which is outside the published folder.

Not done, and worth doing if the site wants to look more like the addon: seven
of the eight palettes carry a painted nine slice frame and a full window cover
texture in `src/Media` (`ns.Backdrops`). The site draws the flat fill that
`dark` uses. The covers are one `background-image` each and would carry most of
what Desert, Forest and Parchment actually look like.

No CI. Pages is set to deploy from the branch, so a push publishes and the
pre-commit hook is the gate.
