---
revision: 5
id: 01M2Z28M8AY7XDHHV1KP95PS88
---

Done in 35902219.

The reach is one number per ring, worked out in Arrange and written on the frame as wk-reach, because the snippet cannot call Lua and because the push is measured in UIParent's units while the circle is in the ring's own. UI.Convert is the seam. Bars.Wedge takes it as an argument, defaulting to DEAD for a caller that only wants an angle, and Aim passes the ring's so the lit square and the fired square stay one answer.

Threshold is Radius(count) less half a square, which is the inner edge of the squares: the push has to reach the ring you are looking at. DEAD stays as a floor under it, so a radius at the bottom of the range still refuses a twitch.

Watch out for in the harness. push() places the pointer in physical pixels and Bars.Reach answers in UIParent units; the two differ by the UI scale, 0.65 in the stub. reachOf() in 76-adhoc does that conversion and says why. Before it was there, a push of 89 against a reach of 93 cast anyway and read as the dead zone not working.

Gated in .claude/worktrees/adhoc-radius while a peer had a half-written parchment painting in the main tree. That run turned up a gate bug worth keeping: the rename rule excluded .git as a directory only, and in a worktree it is a file whose contents are a path through a checkout still called WarriorKit. --exclude=.git is in the same commit.
