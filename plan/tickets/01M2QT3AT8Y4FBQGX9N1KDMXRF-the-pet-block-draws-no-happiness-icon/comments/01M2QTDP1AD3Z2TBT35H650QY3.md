---
revision: 5
id: 01M2QTDP1AD3Z2TBT35H650QY3
---

Cause. PetFrame is caged and the pet block carried a raid marker only.  Fix. b95a40b adds a fourth badge, mood, on the pet spec: Interface\PetPaperDollFrame\UI-PetHappiness cropped to PetFrame.lua's three cells, read with GetPetHappiness and HasPetUI's second answer, marked on UNIT_HAPPINESS. All three faces draw and a demon draws none.  Open. b95a40b went in with core.hooksPath unset, so nothing gated it, and its subject line swallowed the body. The full gate then named harness/client/03-player.lua at 809 lines, which is mine. The fix is in the working tree and not committed: the two stubs move to client/20-tradeskill.lua beside the pet training calls. They cannot sit in 08-blizzard.lua, which loads after the addon, and Paint.lua takes both calls at load.  Gate. 10-unit-frame-skin is green. check.sh is red at HEAD on four files this card did not touch, so the amend is blocked until that is settled.
