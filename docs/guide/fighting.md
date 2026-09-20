# Fighting

**One Charge button.** It casts Charge, Intervene or Intercept depending on the
stance you stand in and what you are looking at, and out of combat it aims by
camera rather than by target.

    /wui charge on|off, charge always|ready
    /wui charge marker on|off, marker size <16-96>, marker offset <-60-60>
    /wui charge bind <key|none>, charge weapon <name|none>

**Raid marking on a held key and a click.** Bind skull, cross and moon to keys
and the icon goes on whatever is under the cursor.

    /wui mark on|off, markkey <skull|cross|moon> <key|none>, targetmark on|off

**One key that switches target and swings.** TAB cycles and stops there. Bind a
key here and it takes the next enemy and starts the attack on it. The other half
of the page lets the camera pick the enemy in front of you and makes that the
one you are targeting.

    /wui switch <key|none>
    /wui aim on|off

**Casting on what the mouse is over.** Drop a spell into the slot on the page
and press a key, and that key casts it on whatever the pointer is on, without
dropping the target you already had. New bindings default to friendly, because
an enemy key is a key you press on what you are already swinging at and the
client targets that for you anyway. The list of what is bound can be drawn over
the world as a small caption. Bindings are per character, since a spell is
something one character knows.

    /wui hover on|off, hover show, hover remove <key>, hover clear
    /wui hover list on|off, the sheet over the world

**A swing timer, with the Slam press marked on it.** One bar per hand, filling
towards the next swing off the combat log, and a green band on the main hand bar
showing where to press Slam so the cast finishes exactly as the swing does.
Press before the band and the Slam restart throws away the swing you had
charged; press after it and the swing is pushed out to the end of the cast. The
whole bar goes green while you are on the band. The cast time is the client's
own, measured off your last Slam, and it follows your haste, so the band moves
when Flurry lands. The bars are drawn for anybody holding a weapon; the band is
a warrior's.

    /wui swing on|off, swing width 180, height 10, zoom 1 to 3

**A nag for what you forgot.** A row of squares over your character when
something that should be up is not: a sharpening stone worn off either hand,
Battle Shout lapsed, no food. It is not there at all when nothing is wrong, so
seeing it is the whole message. A shield is never nagged about. Hover a square
and it tells you what is missing and what fixes it; click it and the options
window opens on the row's own page.

The row has two lines. The out line is checked between fights, because a stone
and a plate of food are things you put on before the pull. The in line is
checked during one: the racial you own and have not pressed, Blood Fury on an
orc and Berserking on a troll pulsing in the middle of your screen until you
spend them, and whatever you dragged there because it lapses mid swing, a
shaman's shield being the case it was built for. An entry can stand on both
lines, and a shield does. Drag a spell out of your spellbook onto either line,
drag a square onto the other line to check it there as well, or drag one off.
Every entry has its own tick box too, per character, because a bank alt that
will never own a sharpening stone does not need to be told about one forever.
Add a flask by spell id where there is nothing to drag, because these clients
will not say that an aura came from one.

    /wui buffs on|off, buffs weapon|offhand|shout|food|racial on|off
    /wui buffs line <name or id> in|out|both
    /wui buffs list, buffs add|remove <spell id>
    /wui buffs pulse on|off, resting on|off, zoom 1 to 3

**Two rows of cooldowns over your character.** Seconds on the top line, minutes
docked under it, up for the whole fight. Your class and your trinkets fill it;
drag a spell from your spellbook onto a line, across lines, or off the row.

    /wui cooldowns on|off, cooldowns list, cooldowns <name> on|off
    /wui cooldowns add|drop <spell id>, cooldowns left|right|line <name>
    /wui cooldowns idle on|off, zoom 1 to 3

**A totem bar with a hole where a totem is missing.** The client draws the
totems you have out as a row as long as the number of them, so the square in the
second place is a different totem every time you look and the one thing it can
never say is which slot is empty. This is the four slots instead, always in the
same order and always in the same place: earth, fire, water, air, which is
Blizzard's own order. A filled slot is the totem's art with the seconds over it
and a sweep that fills as it runs out; an empty one is a hole with the element's
colour on its edge. After a week you stop reading names, because the second
square is Windfury and Windfury being a hole is a sentence. It is up in a fight
and afterwards while anything is still standing, and gone once everything has
run out. Nothing in the part knows what a totem is: the slots, their order and
their colours are a plan in `Class/Shaman.lua`, so a warrior's three stances are
one more plan and one more reader rather than a second feature.

    /wui totems on|off (or /wui stances), totems list, totems idle on|off, zoom 1 to 3

## The class pages

The Charge button, the warrior bar loadout and the Slam band are warrior only,
and on any other class they are not there at all: no button, no icon in the
world, no key taken, no band on the swing bar, and your action targeting setting
left exactly where you had it. The rail in the settings window grows a group
named after your class only if your class has pages nobody else does.

Everything else in this guide works the same on a hunter as it does on a
warrior, the swing bars included. The totem row is a shaman's and the same file
draws a warrior's stances, because both are a plan in `Class/<yours>.lua` and one
reader.

> **Screenshot wanted:** `charge-marker.png`, the marker over a mob with the button lit.

<!-- nav -->
---

Previous: [Themes, placing and profiles](look.md) | [All pages](README.md) | Next: [Action bars](bars.md)
