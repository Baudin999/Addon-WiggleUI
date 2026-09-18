---
revision: 5
id: 01M2SXB2PE7DHA9AP7BDZRMZ48
---

Landed 1443b47. Twenty-one files moved onto ns.Lockdown; nine stopped listening for PLAYER_REGEN_ENABLED at all. Twelve still listen and each is on regen_allowed in check.sh with what it does at the end of a fight, none of them a retry. Owed work is keyed by the function: Auras keeps a row.lay closure per row and EnemyBars forward-declares FlushPending for that reason. Behaviour change: Bars.Restyle and Bars.ApplyBindings now owe themselves rather than the whole Bars.Apply. Harness green through 84-questie-tracker; the hook ran the full 14.
