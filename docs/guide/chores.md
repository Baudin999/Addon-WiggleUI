# Chores

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

> **Screenshot wanted** for `images/bags-vendor.png`: the bag window at a vendor, with the sell row showing.
