![WiggleUI](art/wiggleui.jpg)

# WiggleUI

An interface for TBC Anniversary (2.5.6) and Classic Era (1.15.9). It draws your
unit frames, your action bars, your bags, your character sheet, your quest log,
your map, your mail and most of the other windows the client has, and about a
dozen readouts neither client has ever had.

What follows is a guide rather than a feature list. It starts at the install,
goes through the five questions the addon asks the first time you log in, and
then walks the screen in the order you meet it. Every section names the slash
command for what it just described, because everything in the settings window
has one.

## What the wiggle is

Shake the mouse left and right and the whole screen changes.

That is the gesture the addon is named after. A theme decides how much of the
addon is drawn, and each theme can name a second theme it swaps to. One shake
swaps; the next shake swaps back. Out of the box the exploration theme wiggles
to the informational one, so a screen that keeps your chat, your quest tracker,
your bars and your meters under the pointer is one shake away from a screen that
has all four up and the feeds with them.

A shake is read off the horizontal position of the pointer and nothing else,
because a hand shaking a mouse is a sideways thing and a pointer on its way to
a button turns at most once. Six turns inside 1.2 seconds is a shake, each leg
at least 60 units long, and after one the detector is deaf for a second so a
hand that keeps going does not answer itself. Nothing is sampled while you are
holding the right button to turn the camera.

`/wui wiggle <theme>` sets what the theme you are in swaps to, and `/wui wiggle
none` turns the gesture off, which also stops the addon reading the mouse at
all. The full mechanics are under [themes](#themes-palettes-and-the-wiggle),
below.

## Install

Unzip into `Interface/AddOns`, so that the folder is
`Interface/AddOns/WiggleUI` with `WiggleUI.toc` directly inside it.

[Questie](https://www.curseforge.com/wow/addons/questie) is the one other addon
this one asks anything of, and it is worth having. Both TOCs name it under
`## OptionalDeps` and the CurseForge upload declares it an optional dependency,
so an addon manager offers it alongside this download and the client loads it
first where it is there. Install it by hand if you took the zip. Nothing here
needs it; the section on [Questie](#what-questie-adds) says what it adds.

## The first login

The first time you log in, five cards come up, one question each, with a picture
of the answer on every card.

1. **How big should everything be.** Picking a card sizes the real screen behind
   the window while you look at it. Four stops, from smaller to largest, and
   every part can still be sized on its own later.
2. **How much of the addon do you want on the screen.** This is the theme:
   immersive, exploration or informational. They run from the one that shows
   least to the one that shows most, which is also from the player who knows the
   game best to the one who is new to it.
3. **Which colours should the addon wear.** Dark, forest, desert, arcane, horde,
   alliance, fire or parchment. All but dark carry a painted frame round every
   window; parchment's is a sheet of paper with a torn, scorched edge.
4. **How should your unit frames look.** Modern is shaded bars stacked tight
   with one dark edge and no portrait, the bars taking the portrait's room. Flat
   is flat fills with a hairline round each and your portrait beside them.
5. **Where should a tooltip open.** In the corner the game keeps its own tooltip
   in, or attached to whatever you hovered. A map pin is attached either way,
   because a box in the screen's corner is a long way from the pin it names.

Nothing is written until you finish the last page. Skipping, closing the window
or pressing Escape keeps what you have, which on a fresh install is the shipped
screen, and the setup never comes up on its own again.

Finishing reloads the interface if the mode, the colours or the frames moved,
because those three are drawn once at load. It also lays the chosen mode's
shipped screen over this character's profile, windows and sizes included, so
picking immersive gives you the author's immersive screen rather than the
informational one with things hidden.

To answer them again, type `/wui setup`, or press Escape and take **WiggleUI
Setup** from the game menu. It starts on your current answers rather than on the
shipped ones.

## Getting around

`/wui` opens the settings window and `/wui` again closes it.

Down the left is a rail of nine groups, and a tenth named after your class if
your class has pages nobody else does. A group is a thing you can point at on
the screen or a job you came to do: On and off, Fighting, Action bars, Frames,
Windows, Feeds and meters, Chores, The screen, Under the hood. The group you are
in stands open with its sections listed under it and the rest stay one line
each.

The window opens on **On and off**, which is one switch per part of the addon
and a sentence saying what turning it on puts on your screen. Nothing else is on
that page: no numbers, no ranges. Turn things on, go and look at your screen,
come back. The same switch sits at the top of that part's own page with its
numbers under it.

There is a search field above the page. Type into it and it lists every control
in the window that matches, wherever it lives, and taking one takes you to its
page with the control marked. It takes the keyboard when you click it and at no
other time.

Two commands are worth knowing before the rest:

    /wui help      every word the addon answers, one line each
    /wui status    what every part is doing right now

`/wui` is also `/wiggleui` and `/wiggle`, if the short one is taken.

## Moving things, and how big they are

    /wui unlock    everything up and draggable
    /wui lock      the theme back
    /wui reset     every frame where it started

Unlocking brings up every element the theme hides or fades, whole and at full
alpha, so you can find it and drag it. Locking puts the theme back. This is how
the frames are placed; nothing here is dragged with a modifier held except the
action bars, which want shift because a bare drag on a bar is a drag of what is
in it.

Sizes live under **The screen**, one row per thing that can be sized, and
`Everything` at the top of the list multiplies the rest.

    /wui scale                     list every screen and what it is drawn at
    /wui scale everything 1.2      the lot
    /wui scale <screen> <0.5-3>    one of them, in tenths

The grid already scales by your monitor's height, so `1` is the author's screen
on your monitor rather than the author's screen in pixels. Numbers off the stops
are refused rather than rounded, so `/wui scale everything 1.3` says what the
stops are instead of quietly becoming 1.25.

## Themes, palettes and the wiggle

A theme is one decision about how much of the addon you see, taken for all
twenty three elements at once instead of a tick box per page. Each element gets
one of four answers:

    show     drawn as the part draws it
    hide     off the screen, but still running, so a key bound to a hidden bar still fires
    hover    invisible until the pointer is on it
    0.2      drawn at that fraction of itself, any number above 0 and below 1

The three themes:

- **informational** draws everything, all of the time. This is the one for a new
  player and the one the wiggle target usually is.
- **immersive** is you and the game. Your frame and your target's at a fifth,
  and nothing else. Bags, the map, the character sheet and every other window
  you open still open, because a theme is about what is on the screen while you
  are not asking for anything.
- **exploration** is the middle. Chat, quests, the bars and the meters wait
  under the pointer, drops and messages still slide in, and the loot and combat
  feeds go, because a feed is read as it arrives and one you have to find with
  the mouse has already scrolled past.

Each of the three, and the two other choices drawn at the same moment:

    /wui theme informational|immersive|exploration
    /wui palette dark|forest|desert|arcane|horde|alliance|fire
    /wui gauges flat|modern

All three take effect at the next `/reload`, and that is on purpose. Reading the
choice once at load is what keeps a theme costing nothing after the loading
screen: an element that is `show` in the theme you loaded and `show` in its
wiggle target is never touched again for the rest of the session.

The wiggle is the exception, and it is why the swap is between exactly two
themes rather than any theme to any other. Every element that either theme does
anything to is put under a veil when it is built, and the shake changes the
veil's alpha. That is cheap enough to happen mid-pull, which matters, because
the pull is when you want your bars up.

    /wui wiggle none|<theme>

The target is saved per theme and takes effect the moment you set it, unlike the
theme itself. Whether the wiggle is up is saved too, so a player who lives in
the target does not shake the mouse after every loading screen.

One limit worth knowing. The client refuses two writes on a protected frame
while you are in a fight: putting a veil on, and showing or hiding one. Alpha is
not protected. So a frame that is already veiled and already on the screen
redresses in combat exactly as it does out of it, which is the whole of the
exploration to informational swap, and anything more waits for the fight to end
and then happens.

## Profiles, and putting it back

Every setting on this character, the theme and the window spots included, comes
from one profile.

    /wui profile                 which profile this character wears, and what else exists
    /wui profile new <name>      copy this one under a new name and wear it
    /wui profile use <name>      wear another, reloading
    /wui profile delete <name>
    /wui profile export|import   a string, to hand a profile to somebody else

Switching and deleting both ask first, because a dropdown pick is too easy a
press for a reload and for something that cannot be undone.

Records are not settings and stay on the account: your groups, your mail
favourites, the errors you muted, the flasks you track and the gold ledger.

    /wui defaults       how many settings are not what the addon ships with
    /wui defaults yes   put them back and reload

`defaults` on its own only reports. It is also how a default that moved in an
update reaches you, since your saved answer wins until you ask for the shipped
one.

## Fighting

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

## Action bars

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

## Frames

**Your frame, your target's and your target's target.** Square, class coloured,
the power under the health, and the incoming heal drawn on the health gauge.
Either portraits beside the bars or the bars taking that room, which is the
flat and modern answer from the setup. The target block can mirror the player
block so the two stay the same size, and you can drag either apart.

    /wui skin on|off, skin player|target|tot on|off
    /wui skin height <18-72>, width <90-360>, link on|off, level <-100-100>
    /wui skin heals on|off, auras on|off, aura <size>, debuffs <0-16>, buffs <0-32>
    /wui skin probe, what this client answered for each frame

**Party and raid frames that stop moving.** The same block your own frame wears,
one per person you are grouped with: class colour on the health, the power under
it, the name and the percent, and the role each one is playing said with
Blizzard's own icon. The slot is decided by role and then by name, so the healer
is in the same place in every group you are ever in, and it is worked out
between fights and never during one. Left click targets, which is the point of
the whole thing, because the Charge button casts Intervene at whoever you are
looking at. Somebody out of range, dead, offline or running back drains to the
empty colour and their block says which. A member the client will not name a
power for gets no rail rather than an empty one. Where the addon guesses a role
wrong, tell it: `/wui party role <name> healer` is kept for that character and
beats everything the client thinks.

    /wui party on|off, party self on|off, party role <name> tank|healer|dps|none
    /wui party icons on|off, party range on|off
    /wui party width <60-360>, height <26-72>, gap <0-20>, grow right|left|down|up, zoom 1 to 3
    /wui party reset

**Your own cast bar.** One bar under the swing timer, the same width as it, in
the same flat colours as everything else here. The spell on the left and the
seconds left on the right, counted in tenths because that is what an interrupt
is timed in, and a channel drains from the other end rather than filling. A cast
that does not finish, because you were interrupted or walked out of range or the
client refused the press, turns the bar red and holds it where it stopped for
most of a second: an empty bar is what a cast that finished leaves behind, so a
cast that died has to look like something else.

    /wui cast on|off, cast width <90-400>, height <10-40>, zoom 1 to 3, cast reset

**Threat-coloured enemy bars.** They replace the Blizzard nameplate and carry a
tag saying what the kill is worth. A mob that pays you nothing, because it is far
below you or because somebody else tagged it, goes grey by name as well as by
tag, so you can read it off a screen full of plates. Each bar can carry a cast
row under it and a row of debuff squares you choose by spell id.

    /wui bars on|off, bars mode auto|plates|list, bars style replace|attach
    /wui bars max <1-15>, width <120-400>, zoom <1-3>, offset <-60-60>
    /wui bars marker|level|quest|cast|stack|fade on|off
    /wui bars debuff list|reset|add|remove <spell id>, bars icon <16-32>
    /wui bars distance <20-60>|off

Blizzard's player, target, party and raid frames and its cast bar all go off the
screen, and one tick box each puts them back.

## Windows

Every window in this list replaces one the client has, or fills a hole where the
client has none. The ones that replace something have two switches: `on` draws
ours, and `hide` puts Blizzard's in the attic and takes its key, so C opens this
character sheet rather than that one.

**The character sheet, which says how often you miss.** One page the C key
opens, the size of your monitor, with no window chrome on it. Nineteen slots in
two columns, you standing full height in the gap, and a column down the right
holding what your gear adds up to. That column has four tabs and they change the
list without taking the gear off the screen: standard, which is your hit, your
five attributes and your trades; extended, the resistances and the four rating
groups; skills; and standings.

No client on either of these versions has ever put your miss chance on the
character sheet, because the client knows your hit rating and not your hit
chance. This works it out: how often a special, a white swing and a spell go
wide against a boss and against your own level, with the hit off your gear
already taken off. Each of those numbers is the hit you still want, so there is
no second line saying it twice. The badges at the head of the column are the
four numbers the client's own sheet has never had: item level, durability, empty
slots and that miss chance, and each slot draws its own durability as a line
under it. The skills tab prices what a weapon skill under the cap for your level
is costing you. Right click a slot to take a piece off, drag one on to put it
on, and neither works in a fight because the client will not allow it. The
window itself does open in a fight.

    /wui character, character on|off, character hide on|off
    /wui character gear, stats, skills
    /wui reputation, your standings in a window of their own; reputation list
    /wui character trace on|off, what each click on a gear square did

**A socketing window that knows what you are carrying.** Shift-click a piece on
the gear page and it opens on that piece's holes with every gem in your bags
underneath, the ones that go in the hole you are pointing at first. Click a
hole, click a gem, press apply. Blizzard's own frame gives you three holes and a
drag: you find the gem in your bags yourself, the sparkle that says it matched
is gone in half a second, and the gem you are about to destroy is named nowhere.
Here the line beside the apply button says what applying costs you, by name and
by count, and whether the item would pay its socket bonus afterwards, which is
the number you are socketing for. Right click a hole to take a gem back out.
Nothing is spent until you press apply. TBC only: Classic Era has no sockets,
and on that client this part registers no event at all.

    /wui sockets on|off, sockets hide on|off, sockets gems

**A spell book with one row per spell.** Every spell you know, one row each, and
the button beside the rank folds out the ranks you know. What you pick is what
the square on your bar holds.

    /wui spellbook, spellbook on|off, spellbook hide on|off, spellbook ranks

**A talent window with all three trees side by side.** Nothing to scroll, every
talent on the screen at once, and what unlearning them would cost along the
bottom. A hunter's pet gets a tab instead of Blizzard's Beast Training window.

    /wui talents, talents on|off, talents hide on|off
    /wui talents trees, talents cost, talents pet, talents pet on|off

**A quest log three columns wide.** Every quest you are on down the left, grouped
by zone. In the middle, what this one wants, or a map of where it wants it. On
the right, what it pays.

    /wui quests, quests on|off, quests hide on|off, quests tracker on|off
    /wui quests where, quests drops, quests party

**A world map with every zone down the left.** The zone you picked beside it with
Questie's markers and your group on top, and a line under it saying who the zone
is for. Where a quest's turn-in went is on it for every quest you have finished.

    /wui map, map on|off, map hide on|off
    /wui map zones, markers, turnins [name], group
    /wui map places, map places <kind> on|off

**A dungeon log, where there has never been one.** Neither of these clients has
an adventure guide. Shift-L opens a shelf of dungeons, each wearing its own
loading screen; click one for three columns. Every boss in the game down the
left, grouped by dungeon and in level order, so the column answers "what should
I be running now" without a single click. In the middle, the dungeon's own map,
cut into its floors, with a numbered mark per boss. Neither client will hand
that map over: the 1.15 one has no dungeon maps in its map tree at all and the
2.5 one has a hundred and four of them and files art for none, so the picture is
drawn from the tiles both of them ship all the same. On the right, what that
boss drops, in the client's own grade colours with the client's own tooltip on
every row. Forty dungeons, two hundred and thirty seven bosses, and every item
id in the book generated from Questie's databases rather than typed, then
checked against the client again when the row is drawn: a drop the client
disagrees with is left out instead of shown.

The marks are yours. No database on either client says where a boss stands
inside an instance, so the addon writes down where you were standing the first
time you loot each one, and the map fills in as you run the place. Any drop the
book did not have goes down beside it, which is how the Outland half of the loot
arrives, because the database this was generated from does not carry it.

    /wui dungeons, dungeons on|off, dungeons key <key|none>
    /wui dungeons book, maps, shelf, seen, here, forget

**One bag window instead of five.** What you carry sorted into the piles the
client already files it under, and the free slots counted along the bottom.
While a vendor is open the window grows a row that sells your greys and pays for
your mending, marks what the sale will take and dims what it will not.

    /wui bags, bags on|off, bags hide on|off, bags columns <6-16>, bags hover <0-500>
    /wui bags count, bags stack, bags clear
    /wui bags session [name], bags session clear

**A merchant window with the whole rack in it.** Everything the vendor has at
once, in the same piles and the same squares as your bags. The client shows ten
at a time behind an arrow.

    /wui merchant on|off, merchant hide on|off, merchant stock, merchant sold

**A mail window that says who you are writing to.** A quick list of the people
you mail down the left, the recipient coloured green for one of your own
characters, blue for somebody you know and red for a stranger before you press
send, and more than twelve attachments split across as many mails as it takes.
Right click a stack in your bags to attach it.

    /wui mail, mail on|off, mail hide on|off, mail bags on|off
    /wui mail fav|unfav <name>, mail favs, mail warn on|off

**A chat window, and one tab for the people you play with.** Name your wife, your
kids or your guild officers in `/wui` and every line any of them says, in any
channel, is copied to one tab of its own, together with the whispers you send
them. The tab is not drawn until there is a name on the list. Beside it are two
more: everything anyone said, and whispers on their own. Nothing else is in it.
Loot, experience, system text and every addon's output stay in Blizzard's
window, which is not hidden and not unregistered, because there is no safe way
to tell those lines apart from the ones this window already drew. The
conversation is taken out of Blizzard's frames through FrameXML's own message
filter, so one tick box puts it back with no reload. Names are class coloured, a
click on one answers it, item links still work, and nothing fades out after two
minutes. A right click on a conversation closes it, a right click on the lines
of any room opens a box you can copy them out of, and what this addon says has a
room of its own beside the System room.

    /wui chat, chat on|off, chat room [name], chat claim, chat forget [yes]
    /wui chat close <name>, chat copy
    /wui group, group new <name>, group <group> add|remove <name>, group <group> party

**A voice channel joined when you log in.** Pick your party or raid channel, or
any community or guild stream you are in, the same list the client's own Chat
Channels window puts a voice button on. The addon activates it at login and asks
again whenever it could have appeared, which for a party channel is when you
group up and for a community one is when the first person joins. It only ever
joins: nothing here leaves a channel, mutes anyone or moves a volume. Blizzard's
voice chat has no channels you can name, so what there is to pick is short, and
`/wui` says so.

    /wui voice, voice group|off, voice join, voice who, voice why

**The game menu Escape opens**, drawn in this addon's palette rather than the
client's parchment, with the addon's own button on it.

    /wui menu, menu on|off

## Feeds and meters

**A loot stream, and the combat log beside it.** Two columns of what just
happened, newest at the top and older underneath, scrolled with the wheel. A
loot row is the item's icon, its name in its own quality colour and how many
dropped, with a stripe down the left in that same colour, so a pull reads as a
ribbon before you read a word of it. A quest item carries a ring round its icon,
because a quest item is white and so is a stack of linen. The loot feed has no
word over it and no line round it, and over the rows are seven small squares:
five gems in the quality colours, a quest bang and a stack of coins. Click one
and that kind stops being drawn. They filter what you are looking at rather than
what is recorded, so turning one back on brings its history with it. Hover a row
and the tooltip carries what a vendor pays for one and what the stack came to,
plus what it goes for at auction if you have Auctionator, TSM, Auctioneer or
RECrystallize installed. None of them is required and the line names whichever
answered.

A combat row is three columns off the combat log: what happened, who it was, and
the number. The stripe says which way the blow went and a critical draws its
number in gold with a mark after it, so the crit is not a hue you have to be
able to see. Entering and leaving combat draw a band across the feed, which is
what separates one pull from the one before it, and the band at the end says how
long the fight took. Both feeds are the same widget, and adding a third is a
file that captures something and a table of settings.

Nothing in either feed is on a ticker: they change when something happens to you
and when you scroll them, and never in between.

    /wui feed loot on|off, feed combat on|off, feed <which> show|hide
    /wui feed <which> rows 3 to 24, width 200 to 520, icon 16 to 40, zoom 1 to 3
    /wui feed <which> alpha 0 to 100, mouse|header|edge on|off
    /wui feed loot group on|off, purse on|off
    /wui feed combat out|in|misses on|off, floor 0
    /wui feed <which> clear, feed <which> reset

**A damage meter and a threat meter, side by side.** One row per player: the spec
icon, the name, the number, and a class-coloured bar as long as their share of
the top row. Click the header for the breakdown of your own damage, right click
it to swap damage for healing. The threat side is the client's own percentage,
where 100 means that player takes the mob, and beside it the seconds until they
get there at the rate they are gaining. Nothing is drawn but the rows, so it
sits on the screen rather than over it. A row opens nothing, because there is
nothing behind a row.

    /wui meter on|off, meter dps|hps, meter threat on|off
    /wui meter rows 3 to 10, width 120 to 400, zoom 1 to 3, alpha 15

**A breakdown of what this character actually does.** One row per ability, kept
between sessions: how much of your damage it is, how often it lands, how often
it crits, what it averages, and what stopped it when it did not land. The miss
column names the outcome rather than pooling it, because a dodge and a parry
mean different things and dodge is the one you can do something about. Shouts,
stances and Charge are counted but not listed, since in a damage ranking they
are a run of zeroes above the rows you came to read.

It answers the questions a meter cannot, because a meter forgets the pull it was
counting: whether Slam pays for the swing it costs, what share of your damage
comes from Thunder Clap, whether that new axe changed anything. Rows can be read
one level band at a time, since in this era the target's level drives crit and
miss hard and a number pooled across grey trash and an elite is the average of
two unrelated things.

    /wui breakdown open, and Escape closes it
    /wui breakdown, the top ten to chat
    /wui breakdown on|off, breakdown top 20, breakdown band all|<band>
    /wui breakdown reset yes

**Numbers floating off your character.** What you land falls left, what lands on
you falls right, healing rises. Damage is white, healing green, a big hit gold, a
miss grey. A word appears above your head the moment an ability comes up, once.

    /wui hits on|off, hits size 30, fall 90, curve 44, time 1.3
    /wui hits merge on|off, calls on|off, quiet on|off

## Chores

Five things done for you, each its own switch:

- Corpses empty in one go instead of one slot at a time, with a filter for the
  colours, the kinds and the prices you asked for, and an option to loot and
  destroy the rest so a corpse can still be skinned.
- Grey items sell themselves at every merchant.
- Damaged gear pays for its own repair at any merchant who mends, out of the
  guild bank where your rank allows it and out of your purse where it does not.
  Hold shift as you open a merchant to skip the selling and the repair both.
- The camera pulls back four times the base distance instead of 1.9.
- A stranger who buffs you in passing gets a whispered `ty`, once every ten
  minutes per person, and nobody in your party or raid is ever whispered.

One command each, in that order:

    /wui loot on|off, filter on|off, leftovers on|off, reagents list|clear
    /wui sell on|off
    /wui repair, repair on|off
    /wui zoom on|off
    /wui thanks on|off, thanks <word>

**A filter for the red text in the middle of the screen.** Tick the messages you
do not need and they stop drawing. Nothing is hidden that you did not tick, the
list is shared by every character on the account, and one press silences what a
missed charge shouts at you.

    /wui errors on|off, errors list|clear, errors charge

**`/wui destroy` clears out finished quest items.** One card at a time, with the
quest it came from written on it, and a destroy and a skip. It reads Questie's
database to work out which quest, so it needs Questie installed. `/wui bags
clear` is the same review from the bag window.

**A fanfare when you level, if you supply the sound.** WiggleUI plays
`Media/BestAround.mp3` over the client's own chime and does not ship that file:
it is five seconds of a record somebody else made and is not ours to hand out.
Install [BestAround](https://www.wowinterface.com/downloads/info18925-BestAround.html),
which is where everybody who has heard this joke heard it, and copy its
`bestaround.mp3` into WiggleUI's `Media/` under that name. Any sound file you
like works just as well. With nothing there the fanfare is silent and `/wui`
says why. It plays on the master volume rather than the sound effects slider, so
combat noise turned down does not take it with it, and two levels in one breath
play it once.

    /wui ding, ding on|off

## The screen itself

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

## What Questie adds

The quest log window, the tracker, the map and the bag lanes all draw off the
client on their own. What [Questie](https://www.curseforge.com/wow/addons/questie)
adds is the map pin for where a quest is turned in, the drop rate under an item
something wanted, a party member's progress on a quest you share, the places on
the map you can tick on and off, and the quest a finished item belongs to on a
clutter card. Each of those says in the panel that Questie is not answering
rather than showing you a blank.

## Under the hood

    /wui perf            the frame trace: what every frame cost and why the bad ones did
    /wui perf key <key>  which key opens it, Ctrl-R out of the box
    /wui perf dips       the frames that went wrong and what made each one
    /wui perf sweep      one feature off at a time, so a log can be split on it
    /wui console         a few lines of Lua, run inside the game
    /wui replaces        what else is running that this addon already draws

## Repo layout

    src/        the addon, exactly what the client loads
    src/Media/  the art and fonts the addon ships: the icon, two typefaces
                and the nine pieces of each of the six painted frames
    docs/       the engineering notes, including the file map and API caveats
    plan/       the open work, read and written with ckplan
    scripts/    check.sh, bake-ui.sh, release.sh
    art/        the project art: the banner above, the avatar, the plaque

`art/` is for GitHub and the CurseForge project page and is not shipped, which
is what separates it from `src/Media/`. The client reads BLP and TGA, so a JPEG
in the addon folder would be dead weight.

`src/` is what a client sees. Link it in rather than copying, so there is one
copy to edit and every client loads it:

    ln -s "$PWD/src" "/path/to/World of Warcraft/_anniversary_/Interface/AddOns/WiggleUI"

## Developing

    ./scripts/check.sh

Syntax, TOC agreement, version agreement, saved-variable declarations, a guard
check on every write reachable from an OnUpdate, and luacheck. Zero warnings and
zero errors is the bar, and it passes, so any finding is yours.

    ./scripts/release.sh

Builds `dist/WiggleUI-<version>.zip`. Add `--upload` to publish it to
CurseForge. It refuses to build anything if `check.sh` fails.

There is no commit hook. There was one, and it ran `check.sh` and the harness on
every commit, which is the same two runs `check.sh` already does for every class
and spec: the harness went past twenty times a day for one answer. Run the line
above before you commit. The gate is the same gate; what is gone is running it
twice for the same tree.

Version lives in three places on purpose, `ns.version` in `src/Core/Core.lua` and
`## Version:` in both TOCs. `check.sh` fails if they drift, which is how the
1.1-versus-1.2 split got caught.

## Licence

MIT. See `LICENSE`.
