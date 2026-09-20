---
revision: 5
id: 01M301EPSBHQZFFKP9PBSED0B4
type: bug
status: done
title: The addon keeps the old spec after a dual spec swap
parent: 01M1Y4JDFMVHEB87QK9R1KP4BJ
---

TBC Anniversary has dual spec. It is not the Wrath feature arriving late: it
ships on this client, 1000 gold at a class trainer from level 40, and the
client's own TBC talent window drives it.

Gethe/wow-ui-source, branch `classic_anniversary`, is the whole of what the
client answers with. `Blizzard_TalentUI_TBC.toc` loads
`Classic/Blizzard_TalentUI_Shared.lua`, and that file switches with

    C_SpecializationInfo.SetActiveSpecGroup(talentGroup)   -- Shared.lua:228

while `Classic/Blizzard_TalentUI.lua` reads the pair

    C_SpecializationInfo.GetActiveSpecGroup(false, false)  -- :306
    GetNumTalentGroups(false, false)                       -- :306

and registers `ACTIVE_TALENT_GROUP_CHANGED` at `:152`.

Now `src/Class/Spec.lua:216`:

    events:RegisterEvent("PLAYER_LOGIN")
    events:RegisterEvent("CHARACTER_POINTS_CHANGED")

That is the list. A shaman clicking from restoration to enhancement keeps the
resto rotation squares, the resto cooldown row and the resto debuff list until
a reload, because nothing tells `Spec.Forget` that the answer moved.
`Spec.Mine` reads `IsSpellKnown` on the signature talent, so it is right the
moment anything asks again, and nothing asks.

## What lands

`ACTIVE_TALENT_GROUP_CHANGED` into the same frame, dropping the cache the way
`CHARACTER_POINTS_CHANGED` already does.

Two readers beside it, both probed, because the gear sets above this card need
to name a group that is not the one you are standing in:

    Spec.Group()   C_SpecializationInfo.GetActiveSpecGroup(false, false), or 1
    Spec.Groups()  GetNumTalentGroups(false, false), or 1

Probed and not called bare. Classic Era has neither call and must answer 1 and
1 rather than raise, which is the same shape `Core/Gear.lua` gives CanDualWield
and `ns.ItemSockets` gives a client with no gems.

## Gates

A harness section that fires the event and asserts the class registry answers
the other spec's rotation afterwards, and a client stub for the two calls that
answers a second talent group.
