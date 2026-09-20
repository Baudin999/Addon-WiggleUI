# Frames

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

> **Screenshot wanted:** `frames-player-target.png`, player and target blocks with a heal slice and a few auras.

<!-- nav -->
---

Previous: [Action bars](bars.md) | [All pages](README.md) | Next: [Windows](windows.md)
