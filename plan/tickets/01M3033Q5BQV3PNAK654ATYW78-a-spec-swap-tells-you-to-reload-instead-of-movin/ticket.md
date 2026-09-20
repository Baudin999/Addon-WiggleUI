---
revision: 5
id: 01M3033Q5BQV3PNAK654ATYW78
type: bug
status: todo
title: A spec swap tells you to reload instead of moving the interface
parent: 01M1Y4JDFMVHEB87QK9R1KP4BJ
---

`Class/Spec.lua`'s respec handler prints this when the answer moves:

    your talents now read as enhancement. Type /reload to move the bars, the
    debuff row and the cooldowns over with them.

The comment above it says why, and the reasoning is sound for the world it was
written in:

    unpicking it to save a reload after a trainer visit would be rebuilding the
    whole interface on an event that fires a handful of times in a character's
    life

That was true when a respec cost gold at a trainer. Dual spec landed at
`6b5cb292` and the same handler now fires on a click, twice a raid night, and
`/wui set swap` is built on it. A gear set you press and then have to reload
behind is not a feature anybody uses twice, and the file's own comment is now
an argument against the code under it.

## What actually stays stale

Not everything. The rotation squares and the debuff row read through `Class.Of`
per draw and follow on their own, which is why the swap looks half right rather
than plainly broken. Three parts hold a list they built once:

- the cooldown row, built at login at its ceiling;
- the options page, which keeps the spell names it labelled its switches with;
- the upkeep row, which hands out one table it built the first time it was
  asked.

Each of those is a decision taken at `PLAYER_LOGIN` on purpose. The work is
giving each one a rebuild that can run on a spec change, not unpicking the
decision.

## The shape to aim at

One call the three sign into, driven off the same frame that already drops the
cached spec, so a fourth part that caches per spec has somewhere to register
rather than a fourth reason to reload. The nag stays for the case a rebuild
cannot cover and says which part it is about, instead of naming three parts
whatever moved.

## Gate

A harness section that fires `ACTIVE_TALENT_GROUP_CHANGED` and asserts the
cooldown row draws the other spec's cooldowns without a reload, which is the
one of the three a player sees within a second of pressing the toggle.
