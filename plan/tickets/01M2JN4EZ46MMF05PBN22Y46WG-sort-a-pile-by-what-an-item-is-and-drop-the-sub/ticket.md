---
revision: 5
id: 01M2JN4EZ46MMF05PBN22Y46WG
type: task
status: todo
title: "Sort a pile by what an item is, and drop the sub-piles"
parent: 01M2JN4ESP53ET2Q080EAA8RJD
---

`Piles.Before` sorts on quality, then name. Replace it with class rank, equip slot rank, subclass, item level descending, quality descending, name, then walk position. The quest rank stays first in the quest pile, and the empty pile keeps walk order.

Once cloth sorts beside cloth, the nested trade and misc piles are captions over one square. Delete `nested`, `Nest`, `Slice` and `SubWord`. The Sub caption pool in `UI/Slot.lua` stays, because the sections card reuses it.

The same comparator orders a vendor's rack.
