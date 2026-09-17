---
revision: 5
id: 01M2QAENHAPGN5HFY1AWNE18PB
---

Nameplates checked as a suspect on 17 September. EnemyBars.lua Attach takes a widget from pool and Release puts it back, CreateWidget runs only on an empty pool, and LayoutWidget is skipped unless laidWidth or layoutEpoch moved. The log agrees: uiFrames sat at 10405 from minute 28 to 49 on 16 September while over12 went 33 to 580, and the oursKB lows are flat. Nothing of ours accumulates per plate.

Pools and caches. check.sh already refuses a table, a closure, a format or a join on any path hot.lua reaches from a ticker. What it cannot see is an event handler with no hot: tag and a client call that hands back a fresh table or string. oursKB still swings 16 to 57 MB, so something of ours allocates tens of MB a minute outside the lint's reach. Grep finds no obvious table-returning API on a hot path. Next is a measurement, not a read: collectgarbage('count') in Perf.Start and Perf.Stop, positive deltas summed per slot, written to the minute log. The slots name the ticker and the remainder against oursKB churn names the event handlers.
