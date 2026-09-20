---
revision: 5
id: 01M3032DHH7D9NTGZZP2K2JQAM
---

Landed at 6b5cb292. ./scripts/check.sh at zero.

Three shims in Core, ns.ActiveSpecGroup, ns.NumSpecGroups and ns.SetActiveSpecGroup, and the event on the frame in Class/Spec.lua. Section 52-spec-group drives a swap the way the client does, by moving the trees and firing the event with nothing else touched, and asks the shims on a client with none of the calls and on one whose call raises.

Ruled out, so nobody re-derives it. No new client stub was needed: scripts/harness/client/18-talents.lua already installs all three calls off H.talentModel and already fires ACTIVE_TALENT_GROUP_CHANGED itself, so a second file would have redefined those globals over it and broken 67-talents.

Also found: Talents/Read.lua already carried the whole dual-spec API, Read.Groups and Read.Activate, with a fallback to the older GetActiveTalentGroup names, allow-listed in check.sh at 'the whole dual-spec API'. It was left alone on purpose. It reads a group it was handed rather than the live one, so it is not a caller of the new shims, and moving one of its probes into Core would mean bringing that allow-list count down in the same commit.

The section had to go into CLASS_SECTIONS as well as SECTIONS: the runner fails any section whose code names Spec.Mine, Spec.Token or PLAYER_CLASS and is not in that list.
