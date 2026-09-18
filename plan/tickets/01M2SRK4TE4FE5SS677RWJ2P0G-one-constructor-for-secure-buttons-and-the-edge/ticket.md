---
revision: 5
id: 01M2SRK4TE4FE5SS677RWJ2P0G
type: task
status: doing
title: One constructor for secure buttons and the edge they fire on
---

Nine files built a secure action button and wrote RegisterForClicks and useOnKeyDown by hand; three built SecureHandlerClickTemplate keys the same way. Four of them shipped the dead-click bug. Charge/Icon.lua and Targeting/Switch.lua still had it: registered the press, attribute unset, dead with ActionButtonUseKeyDown off.

UI/Press.lua: Press.Button(parent, name, edge, ...buttons) writes both from one edge; Press.Key(name, edge) for snippet keys; Press.Edge(button) is the one reader (Buttons/Bars.lua and Character/Trace.lua had copies). Ability.New split into Ability.Dress so the bar squares dress a Press button.

Gate: check.sh fails on SecureActionButtonTemplate or useOnKeyDown outside UI/Press.lua, and on SecureHandlerClickTemplate outside UI/.
