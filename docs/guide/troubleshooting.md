# When something is wrong

## A part of the addon is simply missing

The client hides Lua errors unless you ask for them, so a feature that fails to
load vanishes without a word.

    /console scriptErrors 1
    /reload

Then look again. If there is an error, it is worth more than the rest of a bug
report put together.

`/wui status` prints one line per part. A part that is missing from that list
never loaded. A part that is in it but says something odd is a setting rather
than a crash.

## A window is off the bottom of the screen

    /wui reset

That puts positions, size, width and offset back. If only one thing is lost,
the part usually has a reset of its own, listed in
[Moving things](look.md#moving-things-and-how-big-they-are).

## Something else is drawing over it

    /wui replaces

This says what else you have running that this addon already draws. Two addons
drawing the same frame is the most common cause of a screen that looks broken
on a fresh install.

    /wui hide probe

That says which of Blizzard's own frames the addon has put away and what is
actually on screen right now.

## A key does nothing

The Charge key, the target switch key, the marking keys and a ring's key are
override bindings. They never touch your saved bindings and never appear in the
Key Bindings panel. That is on purpose.

    /wui hover show     every key the hover casting holds, and the macro on it
    /wui status         every part, including which keys it has taken

If another addon took the key after login, rebinding it through WiggleUI wins,
because an override sits above the saved set.

## A frame is missing on one client and not the other

    /wui skin probe

That prints what this client answered for each unit frame. The two clients do
not load the same frames, and a row the client will not answer is left out
rather than guessed.

## The screen is stuttering

    /wui perf                 the frame trace, or Ctrl-R
    /wui perf dips            the frames that went wrong, and what made each
    /wui perf dip 50          how long a frame has to be to count as one
    /wui perf watch on|off    whether the trace runs while the window is shut
    /wui perf sweep [minutes] one feature off at a time, so the log can be split
    /wui perf sweep stop      put everything back
    /wui perf show            what each ticker costs

`perf sweep` is the one to reach for when you know it is the addon but not
which part. It turns one feature off at a time on a timer and the log says
which window the dips fell in.

## Running a line of Lua

    /wui console            the console page, under Under the hood
    /wui console run <lua>  one line, and what it printed, in chat

## Putting everything back

    /wui defaults        what is not the answer the addon ships with
    /wui defaults yes    put all of it back, and reload

`defaults yes` cannot be undone, which is why it asks twice. Your groups, your
mail favourites and your muted errors are kept.

To go back further, turn the addon off in the character select addon list. Your
settings are still in SavedVariables when you turn it on again.

## Reporting a bug

https://github.com/Baudin999/Addon-WiggleUI/issues

Open an issue rather than a comment on the CurseForge page. Comments there are
not tracked and get lost between file uploads.

A report that can be acted on says:

1. Which client. TBC Anniversary 2.5.6 or Classic Era 1.15.9.
2. Your class, and your level if it might matter.
3. What you did just before it happened.
4. The Lua error text, if `/console scriptErrors 1` produced one.

Point 4 is worth more than the other three together.

<!-- nav -->
---

Previous: [Every command](commands.md) | [All pages](README.md)
