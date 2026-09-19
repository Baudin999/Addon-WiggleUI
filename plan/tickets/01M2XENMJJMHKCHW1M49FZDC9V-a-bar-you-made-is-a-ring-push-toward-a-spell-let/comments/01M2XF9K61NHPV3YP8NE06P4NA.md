---
revision: 5
id: 01M2XF9K61NHPV3YP8NE06P4NA
---

Landed in 6dfdd4f. check.sh 0 warnings, 0 errors.

Cause of a hidden bug found on the way. Wrapped_Click on 2.5.6 (Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua) runs a post body only when the pre body returns a message. The old square close had pre "" and never ran in game. The harness stub ran post always and ran the secure half before pre. 14-secure.lua now follows Wrapped_Click.

Also: ring is FULLSCREEN strata; at MEDIUM it opened under DIALOG windows.

Not proven outside the game: that the client's GetMousePosition on the hidden SecureFrameTemplate screen frame answers as OPie's SCREEN does. Test in game: hold the key, push, release, in and out of combat.
