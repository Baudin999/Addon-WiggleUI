---
revision: 5
id: 01M2WGJ0ZZ2BYP1V4850TQ0JZ7
---

Landed in 4b90ceb. Painting replaces bands and hairline, pad 0 so the frame sits on the map; Layout(size, size) runs in Shape.Apply after SetSize, so a size change relays it. Clock tab offset by Backdrop:Thickness('bottom') at half scale. Not seen in the client. Unverified there: whether the corner buttons Shape.Corner places draw above the bezel's corners (bezel is a child of Minimap, the buttons are the client's own frames at their own levels).
