---
revision: 5
id: 01M301FQJ8N4GS4E9MWGA3VAQP
---

The shape of this page, decided 2026-09-20 with the sets contract on
01M1Y4JJ5PT1EHD89PXR22QRYG.

A row grows a third line. The big disc stays what you are **wearing**, because
that is the sheet's job and a page showing a saved set instead stops answering
what you have on. Under the note line, at the near edge, one small disc per set:

    O   Sunfury Robe of the Magus
        ilvl 128              * * *      note and socket dots, unchanged
        o o o                            the sets, new line

Four states per circle: the item's icon for a set that names a piece, the same
dimmed when that piece is what the big disc is already showing, a hollow ring
for unset, a ring with a slash for deliberately empty. The third and fourth are
opposite intentions and cannot look alike.

That layout answers a question nobody asked for. A circle that disagrees with
the big disc on its own row is a piece of the set that did not go on, so a
glance down the column after a swap is the whole of "did it work".

The row is 36 and becomes 48, and only when more than one set exists. The rows
are centred and the figure stands on their block (`Paperdoll.lua:2058`), so the
growth moves him too, and a page shorter than its rows loses the bottom row.
One set or none and the page is what it is today.

The circles go beside the disc and never over it. Anything overlapping the
secure square is a mouse fight with a protected frame, and a drop landing on it
in a fight would be a refused equip rather than a set edit.

Gestures: click takes what you are wearing into that set's slot, which is how a
set actually gets built; a drop from the bags sets the slot and then clears the
cursor; a drag off clears it back to unset. Circle to circle goes through
ns.UI.Carry rather than the client's cursor, so a copy between sets cannot
equip, unequip or destroy anything. The worn square is never a drag source for
this: picking a piece up off the paperdoll unequips it.

The toggles are a stack at the top left, mirroring the head block on the right.
Identity on the right, sets on the left. Each is a large disc wearing the spec's
own icon, which the client hands over for a group you are not standing in:

    local _, name, _, icon = C_SpecializationInfo.GetSpecializationInfo(
        tree, false, false, nil, nil, groupIndex)

A set with no group falls back to its most distinctive piece. Clicking one wears
the set, and switches talents first when it names the other group.

A hover on a small circle opens that set's piece, built from the saved link so a
piece in the bank still reads, with the set's name as the first line. Shift on
it compares against the big disc on the same row.

None of it on the inspect page. `pane.inspect` already gates the durability
line, the stone countdown and the cooldown arc, and a set circle on somebody
else's boots is the same kind of fact.
