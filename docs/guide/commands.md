# Every command

Generated from the help tables in the source by
`scripts/bake-guide-commands.sh`. This is the same text `/wui help` prints in
the game, so it cannot fall behind what the addon answers.

`/wui` on its own opens the settings panel. `/wui help` prints this list in
chat, and `/wui status` prints one line per part saying what it is doing right
now.

## The words Core answers itself

    /wui                       open the settings panel
    /wui panel|options|config  the same thing
    /wui status                one line per part
    /wui help                  the command list
    /wui lock                  put the theme back
    /wui unlock                every element up, drag it where you want it
    /wui reset                 positions, size, width and offset
    /wui defaults              what is not the answer the addon ships with
    /wui defaults yes          put all of it back, and reload

`defaults yes` is the one command here that cannot be undone, which is why it
asks twice. Your groups, your mail favourites and your muted errors survive it.

## charge marker

    /wui charge on|off, charge always|ready, charge marker on|off
    /wui charge marker size <16-96>, charge marker offset <-60-60>
    /wui charge weapon <name|none>, size <16-128>, bind <key|none>

## marking

    /wui mark on|off, markkey <skull|cross|moon> <key|none>, targetmark on|off

## hover

    /wui hover on|off, a key casts on whatever the mouse is over
    /wui hover show, every key and the macro it presses
    /wui hover remove <key>, hover clear
    /wui hover debug on|off, say what every press finds and whether it casts
    /wui hover list on|off, the list drawn over the world

## targeting

    /wui switch <key|none>, one key for the next enemy and the swing at it
    /wui aim on|off, the camera picks the enemy and it becomes your target

## buttons

    /wui buttons apply, buttons restore, buttons status
    /wui actionbars on|off, our bars over the client's, or the client's bottom bar back, art and all
    /wui actionbars match, back to cloning whichever bars you have on
    /wui actionbars where, actionbars reset, after dragging them with /wui unlock
    /wui actionbars rows|square|colour|background|combat|key <bar> <value>, one bar's shape, ground and hours
    /wui actionbars centre <bar> across|down, its middle on the middle of the screen
    /wui actionbars plain, every bar back to the plan's own shape
    /wui actionbars lock|unlock, whether shift and a drag moves a bar
    /wui actionbars trace, what the mouse is really touching, for a square that will not take a drop
    /wui ranks, ranks refresh

## bars

    /wui bars on|off, bars mode auto|plates|list, bars style replace|attach
    /wui bars offset <-60-60>, bars marker on|off, bars level on|off, bars quest on|off
    /wui bars cast on|off, the cast row under each bar
    /wui bars max <1-15>, bars width <120-400>, bars zoom <1-3>
    /wui bars debuff list|reset, bars debuff add|remove <spell id>, what the icon row tracks
    /wui bars icon <16-32>, the size of one debuff square
    /wui bars stack on|off, whether the client spaces plates by the size of our bar
    /wui bars distance <20-60>|off, how many yards out a plate goes up
    /wui bars fade on|off, whether a bar ramps in and out or simply appears
    /wui skin on|off, the square player, target and target of target frames
    /wui skin player|target|tot on|off, one frame at a time
    /wui skin height <18-72>, skin width <90-360>, both in screen pixels
    /wui skin link on|off, mirror the target block off the player block
    /wui skin level <-100-100>, the target's drop from the player; drag either with the frames unlocked
    /wui skin heals on|off, the incoming heal on the health gauge
    /wui skin auras on|off, our own aura rows under the player and target blocks
    /wui skin aura <12 up to the block height>, one aura square, in screen pixels
    /wui skin debuffs <0-16>, skin buffs <0-32>, how long each row runs
    /wui skin probe, what this client answered for each frame
    /wui cast on|off, your own cast bar, which sits under the swing timer
    /wui cast width <90-400>, cast height <10-40>, cast zoom <1-3>
    /wui cast reset, the bar back where it started
    /wui party on|off, blocks for the people you are grouped with
    /wui party self on|off, whether your own block is in the list
    /wui party role <name> tank|healer|dps|none, an answer you type
    /wui party icons on|off, party range on|off
    /wui party width <60-360>, party height <26-72>, party gap <0-20>
    /wui party grow right|left|down|up, party zoom <1-3>
    /wui party reset, the line back under the middle of the screen
    /wui raid on|off, the grid, which is its own frame in its own place
    /wui raid order group|role, a run of five per group or role bands
    /wui raid columns <1-8> groups, raid percolumn <1-40> in a group
    /wui raid headings on|off, the group number on each run of five
    /wui raid self on|off, raid icons on|off, raid range on|off
    /wui raid width <60-360>, raid height <26-72>, raid gap <0-20>
    /wui raid grow right|left|down|up, raid zoom <1-3>, raid reset
    /wui hide <switch> on|off, one of the client's own frames this addon replaces
    /wui hide probe, every frame those switches name and what is on screen now
    /wui auras on|off, the client's own buff row in the corner of the screen
    /wui colors, every class fill and how far the name on it is from it

## meter

    /wui meter on|off, and meter dps|hps to swap what the left pane counts
    /wui meter threat on|off, rows 3 to 10, width 120 to 400, zoom 1 to 3
    /wui meter alpha 15, the bar opacity, 0 to 100 in fives

## swing

    /wui swing on|off, the main hand and off hand swing bars
    /wui swing width 180, height 10, zoom 1 to 3

## buff

    /wui buffs on|off, the row of what is missing
    /wui buffs weapon|offhand|shout|food|racial on|off, one entry at a time
    /wui buffs line <name or id> in|out|both, which line its square is on
    /wui buffs pulse on|off, resting on|off, zoom 1 to 3
    /wui buffs list, buffs add|remove <spell id>, your own flask and elixirs

## cooldown

    /wui cooldowns on|off, the row of long cooldowns over your character
    /wui cooldowns list, what your class and your trinkets put on it
    /wui cooldowns <name> on|off, one entry at a time, per character
    /wui cooldowns idle on|off, zoom 1 to 3
    /wui cooldowns add|drop <spell id>, a cooldown of your own
    /wui cooldowns left|right|line <name>, where its square sits

## standing

    /wui totems|stances on|off, the row of what you have out, over your character
    /wui totems list, one line per slot and what is in it
    /wui totems idle on|off, zoom 1 to 3

## breakdown

    /wui breakdown on|off, breakdown open for the window, breakdown to print the top ten
    /wui breakdown top 20, band all or a level band
    /wui breakdown reset yes throws away everything counted so far

## feeds

    /wui feed loot on|off, and feed combat on|off, which is whether it collects
    /wui feed <which> show|hide takes the column off the screen and leaves it collecting
    /wui feed <which> rows 3 to 24, width 200 to 520, icon 16 to 40, zoom 1 to 3
    /wui feed <which> alpha 0 to 100, mouse|header|edge on|off
    /wui feed loot group on|off, purse on|off
    /wui feed combat out|in|misses on|off, floor 0
    /wui feed <which> clear empties it, reset puts it back where it started

## chat

    /wui chat, open or close the chat window
    /wui chat on|off, draw it at all
    /wui chat room, list the rooms; chat room <name>, go to one
    /wui chat claim, whether the same lines still draw in Blizzard's window
    /wui chat forget, what is kept across a reload; chat forget yes, throw it away
    /wui chat close <name>, close the conversation with them; a right click on their room does the same
    /wui chat copy, the room you are reading in a box you can Ctrl-C out of; a right click on the lines does the same
    /wui group, list your groups and who is in them
    /wui group new <name>, group <group> add|remove <name>, group <group> party
    /wui voice, what the voice pick is doing
    /wui voice group|off, join your party or raid channel, or nothing
    /wui voice join, ask for it again now
    /wui voice who, the client's own window, for who is in it and how loud
    /wui voice why, every answer the client gives about voice

## minimap

    /wui minimap on|off, square rather than round
    /wui minimap size <120-300>, how wide the map is drawn
    /wui minimap buttons on|off, collect the addon buttons behind one square
    /wui minimap scan, look for addon buttons that have appeared since login
    /wui minimap list, name every button the corral is holding

## artwork

    /wui art on|off

## interface

    /wui ui save, ui apply, ui auto on|off

## comfort

    /wui loot on|off, empty a corpse in one go
    /wui filter on|off, take only the colours, the kinds and the prices you asked for
    /wui leftovers on|off, loot and destroy the rest, so a corpse can be skinned
    /wui reagents list|clear, what your professions have put on the filter, or empty it
    /wui sell on|off, grey items at every merchant
    /wui repair, pay the merchant in front of you now
    /wui repair on|off, pay every merchant who mends, guild funds first
    /wui zoom on|off, how far the camera pulls back
    /wui thanks on|off, whisper a stranger who buffs you
    /wui thanks <word>, what to whisper them instead of ty
    /wui ding, hear the level up fanfare now
    /wui ding on|off, five seconds of the eighties every time you level
    /wui errors on|off, filter the red text through your muted list
    /wui errors list|clear, what is muted and what has come past, or empty it
    /wui errors charge, mute what a missed charge shouts at you
    /wui destroy, review what your bags are finished with, one at a time

## settings

    /wui scale, list every screen and what it is drawn at
    /wui scale <screen> <0.5 to 3>, how big one screen is drawn, in tenths
    /wui tips <type> right|left|attached|anchor, where one type of tooltip opens
    /wui tips linger <seconds>, font <pixels>, shade <percent>, how long it stays, how big it reads and how dark

## performance

    /wui perf, the frame trace: what every frame cost and why the bad ones did
    /wui perf key <key|none>, which key opens it. Ctrl-R out of the box
    /wui perf dips, the frames that went wrong and what made each one
    /wui perf watch on|off, whether the trace runs while the window is shut
    /wui perf dip <ms>, how long a frame has to be to count as one
    /wui perf sweep [minutes], one feature off at a time so the log can be split on it
    /wui perf sweep stop puts everything back, perf sweep status says where it is
    /wui perf show, what each ticker costs. perf on|off, tick timing
    /wui perf reset, clear the counters and the log

## menu

    /wui menu, what the client's own menu is made of and where our button went
    /wui menu on|off, the client's menu in the addon's look or in its own

## mail

    /wui mail, open the window you are standing at a mailbox for
    /wui mail on|off, the addon's mail window instead of the client's
    /wui mail hide on|off, move Blizzard's own window out of the way
    /wui mail bags on|off, right click a stack in your bags to attach it
    /wui mail fav|unfav <name>, the quick list down the left of the window
    /wui mail favs, what is on that list and who each of them is
    /wui mail warn on|off, whether a stranger takes two presses as well as red

## quests

    /wui quests, open the quest log
    /wui quests on|off, the addon's quest log instead of the client's
    /wui quests hide on|off, put Blizzard's own log in the attic and take the L key
    /wui quests tracker on|off, switch Questie's own tracker off through Questie
    /wui quests where, whether Questie is answering for the where column and the map
    /wui quests drops, what a hover over a creature says about the quest items it carries
    /wui quests party, what can say how many of your group are on a quest

## world

    /wui world on|off, the addon's own tooltip on a creature in the world

## xp

    /wui xp on|off, the experience and reputation rails along the bottom
    /wui xp faction on|off, the reputation rail under the experience one
    /wui xp bubbles on|off, the twenty segment marks
    /wui xp style expressive|minimal, the placed rail or a line across the screen
    /wui xp width <120-900>, xp height <6-32>, xp zoom <1-3>
    /wui xp reset, the rails back along the bottom of the screen

## character

    /wui character, open the character sheet
    /wui reputation, open your standings in a window of their own
    /wui reputation list, how many factions you know and how many are exalted
    /wui character on|off, the addon's character sheet instead of the client's
    /wui character hide on|off, put Blizzard's own sheet in the attic and take the C key
    /wui character gear, what you are wearing and how worn it is
    /wui character stats, your hit and what you still miss with it
    /wui character skills, which weapon skills are behind the cap for your level
    /wui character trace on|off, say in chat what each click on a gear square did

## map

    /wui map, open the world map
    /wui map on|off, the addon's world map instead of the client's
    /wui map hide on|off, put Blizzard's own map in the attic and take the M key
    /wui map zones, how many zones the client will name and how many have a level range
    /wui map markers, whether Questie is answering for the markers on the map
    /wui map turnins, where the question mark went for every quest you have finished
    /wui map turnins <name>, the same for one quest, finished or not
    /wui map group, whether the client will say where the people you are with are
    /wui map places, every kind of place Questie can draw, and which are on
    /wui map places <kind> on|off, one of them switched, in Questie and on both maps

## bags

    /wui bags, open the bag window
    /wui bags on|off, one window with your bags grouped instead of five of the client's
    /wui bags hide on|off, take the client's own bag calls so B opens this one
    /wui bags columns <6-16>, how many squares across
    /wui bags hover <0-500>, how long the pointer holds still on a square before its box opens, in milliseconds
    /wui bags count, how many slots you have and how many are free
    /wui bags stack, put your half stacks together and free the slots under them
    /wui bags clear, review what your bags are finished with, one at a time
    /wui bags session [name], start or stop recording what reaches your bags
    /wui bags session clear, forget what the last session recorded

## dungeons

    /wui dungeons, open the dungeon log
    /wui dungeons on|off, the dungeon log and the key that opens it
    /wui dungeons key <key|none>, which key opens it
    /wui dungeons book, how many dungeons, bosses and drops the book has
    /wui dungeons maps, whether this client has a map for each dungeon
    /wui dungeons shelf, whether this client has a picture for each dungeon
    /wui dungeons seen, how much the ledger has learned from your own runs
    /wui dungeons here, which dungeon the window would open on where you stand
    /wui dungeons forget, throw the ledger away

## merchant

    /wui merchant on|off, the whole rack in one window instead of ten at a time
    /wui merchant hide on|off, move the client's own merchant window off the screen
    /wui merchant stock, what the vendor in front of you has
    /wui merchant sold, what is on the buyback rack

## console

    /wui console, the page. console xp, a probe. console run <lua>, one line of Lua

## talents

    /wui talents, open the talent window
    /wui talents on|off, the addon's talent window instead of the client's
    /wui talents hide on|off, keep Blizzard's own from loading and take the N key
    /wui talents trees, how many points are in each of your three trees
    /wui talents cost, what your trainer last quoted to unlearn them, and what the schedule says
    /wui talents pet, a hunter's pet: what Beast Training can teach it and the points it has
    /wui talents pet on|off, the pet's tab instead of Blizzard's Beast Training window
    /wui talents trace on|off, says in chat where a press on a pet ability stops

## spellbook

    /wui spellbook, open the spell book
    /wui spellbook on|off, the addon's spell book instead of the client's
    /wui spellbook hide on|off, put Blizzard's own book in the attic and take the P key
    /wui spellbook ranks, how many squares are set below the best rank you know

## adhoc

    /wui adhoc, every bar, its key and how many squares it holds
    /wui adhoc add <name>, a new bar
    /wui adhoc <bar> <key|none>, the key you hold to open that ring
    /wui adhoc zoom 1.5, the bars' zoom, 0.5 to 3
    /wui adhoc radius 160, how far out the squares sit and how far you push
    /wui adhoc on|off

## hits

    /wui hits on|off, damage floating off your character and healing rising over it
    /wui hits size 30, fall 90, curve 44, time 1.3
    /wui hits merge on|off, calls on|off, quiet on|off

## sockets

    /wui sockets on|off, this addon's socketing window instead of the client's
    /wui sockets hide on|off, move the client's own socketing window off the screen
    /wui sockets gems, every gem in your bags that goes in a hole

## replaced

    /wui replaces, what else is running that this addon already draws

## theme

    /wui theme informational|immersive|exploration|<yours>, how much of the addon is on the screen, from the next /reload
    /wui palette dark|forest|desert|arcane|horde|alliance|fire|parchment, the addon's colours, from the next /reload
    /wui gauges flat|modern, how every health, power and cast bar is drawn, from the next /reload
    /wui wiggle none|<theme>, what the theme swaps to on a shake of the mouse

## game menu setup

    /wui setup, the five first questions again: size, mode, colours, unit frames and tooltips

## profiles

    /wui profile, list the profiles and say which one this character wears
    /wui profile use <name>, wear another profile, reloading
    /wui profile new <name>, copy this one under a new name and wear it
    /wui profile delete <name>, delete one this character is not wearing
    /wui profile export | import, a string to share a profile with another player

<!-- nav -->
---

Previous: [The screen itself](screen.md) | [All pages](README.md) | Next: [When something is wrong](troubleshooting.md)
