# Action bars

**Your own action bars, redrawn.** `/wui actionbars on` reads whichever bars you
have up, stands one of ours up for each on the same action slots, moves your
keys onto it, and hides Blizzard's behind it. Bar 1 still pages by stance. Every
icon is drawn at the one size this client can draw sharp, and the border says
whether a press would land. Your keybindings are read and never written, so
`off` gives everything back with no reload.

Then every bar is yours to shape. Fold its twelve into 1, 2, 3, 4, 6 or 12 rows,
so a bar is a row along the bottom or a column down the side. Pick the colour of
the ground under the squares and how much of it you see, down to nothing, which
leaves the icons standing on the world. Send a bar off the screen when a fight
starts, or keep it off the screen until you hold shift, ctrl or alt, with its
keys working the whole time either way. Unlock the bars and shift-drag one where
you want it, or put its middle on the middle of the screen with a button, one
axis at a time. Make the squares bigger or smaller, 16 pixels to 54, and the
panel says which sizes draw sharp. Every bar answers for itself, and one press
puts the lot back to plain. While the settings window is open, whichever bar you
have picked wears a blue rim on the screen, so you are never editing the one you
thought was the other one.

    /wui actionbars on|off, actionbars match, actionbars plain
    /wui actionbars rows|square|colour|background|combat|key <bar> <value>
    /wui actionbars centre <bar> across|down
    /wui actionbars lock|unlock, actionbars where, actionbars reset
    /wui actionbars trace, for a square that will not take a drop

**A ring of your own on a key.** Hold the key and a ring of squares comes up
around the pointer; push toward one and let go and it fires. Six bars is the
cap and sixteen squares is the width of a ring. This is what the theme calls the
loadout bars,
and it stays drawn in exploration, because a bar that came up only while its key
was held and then waited for the pointer as well would be a key that shows
nothing.

    /wui adhoc, adhoc add <name>, adhoc <bar> <key|none>, adhoc zoom 1.5, adhoc on|off

**A warrior bar loadout**, with a backup of whatever it replaced. It writes
action slots and never a keybinding, because the bar 1 and bar 2 keys are
already bound and the slots those keys point at are the whole job.

    /wui buttons apply, buttons restore, buttons status

**Stripped bar art**, so the bars read as a row of icons rather than a metal
strip with gryphons on the ends.

    /wui art on|off

> **Screenshot wanted:** `actionbars.png`, two bars at different row counts and backgrounds, one hidden behind shift.
