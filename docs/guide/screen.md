# The screen itself

**A square minimap, as wide as you asked for.** The mask and the ring come off,
the mousewheel zooms, and Blizzard's mail and tracking icons move to the
corners. Every addon button on the edge of the map goes behind one square you
press to open. Each is borrowed rather than taken: parent, position and the
button's own anchoring are handed back the moment you turn it off.

    /wui minimap on|off, minimap size <120-300>
    /wui minimap buttons on|off, minimap scan, minimap list

**Your experience along the bottom, drawn here.** Two rails: how far into the
level you are, and under it the faction you are watching, in the same flat
colours as everything else. The rested pool is a second fill running on from
where you are, so an evening's rest is something you see rather than something
you hover for, and the twenty bubbles this game has always drawn are still on
it. A rail with nothing to say is not there at all: at the level cap there is
only the reputation rail, watching nothing leaves only the experience one, and a
character with neither has no bar on the screen. Hover one and it says what is
left of the level, what the rested pool is worth, and how long the rest of the
level will take at what you have been earning this session, which is a number
the game itself will not tell you.

    /wui xp on|off, xp faction on|off, xp bubbles on|off
    /wui xp style expressive|minimal, xp width <120-900>, height <6-32>, zoom <1-3>
    /wui xp reset

**One tooltip, and parts hook into it.** Every hover in the addon opens the same
box: an action square, a nag square, a mail attachment, a link somebody put in
chat. Where the words are the client's, which is the stats on an item and the
rank and cost on an ability, they are read out of the game and redrawn here
rather than raising a gold-bordered parchment over an interface that has none.
Each box is a name, then the facts the thing itself knows, then whatever else in
the addon has something to say about it, then one blue line telling you what to
press or what to type. Adding a line to every tooltip about an item is one call
at load. That is how the vendor and auction prices work, which is why they show
up on a mail attachment and not only on the loot row they were written for. The
box docks in the corner the client keeps its own tooltip in, clear of the bags,
so nothing you hover is covered by what it says.

A creature in the world gets the same box. It is the one hover nothing in the
addon owns a frame for, since the cursor is over the world itself and the client
fills and shows its own tooltip with no script in the way, so the addon opens
its box on the pointer and holds Blizzard's down while it is up. That
suppression is narrow on purpose. It is armed only while our box is on screen
and it acts only on a tooltip that answers a unit, because the client's box is
also a linked item, a quest reward and every other addon you have installed. The
threat meter hooks a line onto it: point at anything across the room and the box
says whose it is before you swing.

    /wui tips <type> right|left|attached|anchor
    /wui tips linger <seconds>, font <pixels>, shade <percent>
    /wui world on|off, the box on a creature in the world

**An Edit Mode layout carried inside the addon**, so a fresh computer gets the
same screen.

    /wui ui save, ui apply, ui auto on|off

**What else is running.** `/wui replaces` names any other addon you have
installed that draws something this one already draws, which is the first thing
to check when two frames are fighting over the same corner.

> **Screenshot wanted:** `minimap.png`, the square minimap with the button corral open.
