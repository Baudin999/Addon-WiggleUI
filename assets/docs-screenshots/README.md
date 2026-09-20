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
| `theme-immersive.png` | [Look](../../docs/guide/look.md), the immersive theme. |
| `theme-exploration-02.png` | [Look](../../docs/guide/look.md), exploration mid fight. |
| `theme-exploration-01.png` | [Look](../../docs/guide/look.md), exploration a moment after the kill. |
| `character-stats.png` | [Windows](../../docs/guide/windows.md), the character sheet. |
| `bags.png` | [Windows](../../docs/guide/windows.md), the bag window. |
| `meters-01.png` | [Feeds and meters](../../docs/guide/feeds.md), the two meter panes. |
| `meters-02.png` | [Feeds and meters](../../docs/guide/feeds.md), the breakdown window. |

## Still wanted

| File | What it should show | Page |
| --- | --- | --- |
| `charge-marker.png` | The marker over the mob the charge would hit, button lit. | [fighting](../../docs/guide/fighting.md) |
| `actionbars.png` | Two bars at different row counts and backgrounds, one hidden behind shift. | [action bars](../../docs/guide/bars.md) |
| `frames-player-target.png` | Player and target blocks, a heal slice on the gauge, a few auras. | [frames](../../docs/guide/frames.md) |
| `minimap.png` | The square minimap with the button corral open. | [the screen](../../docs/guide/screen.md) |
| `bags-vendor.png` | The same bag window with a vendor open, so the sell and repair row is on it. | [chores](../../docs/guide/chores.md) |
| `install-addons-list.png` | Character select addon list, WiggleUI ticked. | [install](../../docs/guide/install.md) |

## Shooting them

Crop to the window. The four theme shots are the exception and are the whole
screen, which is what makes them worth having: one beach, one crocolisk, three
themes.

The setup pages set the bar: the window cropped to itself, nothing of the
desktop in frame, and the pointer somewhere that is not over the thing being
described.

A full screen shot off a 3440x1440 monitor is 5 to 6 MB, and four of them on
one page is not a page anybody waits for. The four here were halved to 1720
wide, which costs nothing at the width GitHub draws them and took the set from
22 MB to 6.8. Do the same to the next full screen shot before committing it:

    magick shot.png -resize 1720x -strip shot.png

The originals are in git history if a full size one is ever wanted.
