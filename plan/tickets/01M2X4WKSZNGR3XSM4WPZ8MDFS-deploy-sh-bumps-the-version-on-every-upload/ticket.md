---
revision: 5
id: 01M2X4WKSZNGR3XSM4WPZ8MDFS
type: task
status: doing
title: deploy.sh bumps the version on every upload
---

deploy.sh uploads whatever version is typed into Core.lua and both TOCs, and nothing ever changed it, so every upload has been 1.9.

An upload through deploy.sh raises the last component of the version in all three files, runs the release, and on success commits the bump and tags it. On failure the three lines go back. --build does not bump.
