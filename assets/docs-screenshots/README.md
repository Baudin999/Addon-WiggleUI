# Screenshots for the guide

Drop a PNG in here under the name a page asks for and say so, and the
placeholder in that page becomes the picture.

Every outstanding request is a blockquote beginning **Screenshot wanted**:

    grep -rn "Screenshot wanted" docs/guide

## In the guide already

| File | Where it is used |
| --- | --- |
| `setup-page-01.png` | [The first login](../../docs/guide/first-run.md), the size question. |
| `setup-page-02.png` | [The first login](../../docs/guide/first-run.md), the mode question. |
| `setup-page-03.png` | [The first login](../../docs/guide/first-run.md), the colours question, and again on [look](../../docs/guide/look.md) as the palette picture. |
| `setup-page-04.png` | [The first login](../../docs/guide/first-run.md), the unit frames question. |
| `setup-page-05.png` | [The first login](../../docs/guide/first-run.md), the tooltips question. |
| `theme-002.png` | [The first login](../../docs/guide/first-run.md), under Getting around, for the rail and the search field. |
| `theme-informational.png` | [Look](../../docs/guide/look.md), the informational theme. |

## Still wanted

| File | What it should show | Page |
| --- | --- | --- |
| `theme-exploration.png` | The same spot and fight as `theme-informational.png`, under exploration. | [look](../../docs/guide/look.md) |
| `theme-immersive.png` | The same again under immersive, so the three read as one screen changing. | [look](../../docs/guide/look.md) |
| `charge-marker.png` | The marker over the mob the charge would hit, button lit. | [fighting](../../docs/guide/fighting.md) |
| `actionbars.png` | Two bars at different row counts and backgrounds, one hidden behind shift. | [action bars](../../docs/guide/bars.md) |
| `frames-player-target.png` | Player and target blocks, a heal slice on the gauge, a few auras. | [frames](../../docs/guide/frames.md) |
| `character-stats.png` | The character sheet stats page with the miss rows. | [windows](../../docs/guide/windows.md) |
| `meters.png` | Both meter panes mid fight, threat close to a pull. | [feeds and meters](../../docs/guide/feeds.md) |
| `minimap.png` | The square minimap with the button corral open. | [the screen](../../docs/guide/screen.md) |
| `bags-vendor.png` | The bag window at a vendor, sell and repair row showing. | [chores](../../docs/guide/chores.md) |
| `install-addons-list.png` | Character select addon list, WiggleUI ticked. | [install](../../docs/guide/install.md) |

## Shooting them

Crop to the window, apart from the three theme shots, which are the whole
screen and have to be the same spot and the same fight to be worth having as a
set.

The setup pages set the bar: the window cropped to itself, nothing of the
desktop in frame, and the pointer somewhere that is not over the thing being
described.

A full screen shot off a 3440x1440 monitor is about 5 MB, which is more than a
guide page should pull down. `theme-informational.png` is one and is the only
one; halve the width before the next two land and they come out near 1.5 MB
with nothing visible lost at the width GitHub renders them.

    magick shot.png -resize 1720x -strip shot.png
