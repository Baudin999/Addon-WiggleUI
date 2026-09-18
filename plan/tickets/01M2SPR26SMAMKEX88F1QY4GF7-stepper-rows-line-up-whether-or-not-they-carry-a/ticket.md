---
revision: 5
id: 01M2SPR26SMAMKEX88F1QY4GF7
type: task
status: todo
title: Stepper rows line up whether or not they carry a hint
---

On Floating numbers the "fall" row read "120..." and its buttons sat one column right of size, curve and time on screen. Two causes in `src/UI/Widgets.lua`. `kit.Stepper` gave the value 34 px, too narrow for three digits and "px". `Paired` only kept the `?` column free on a row that had a hint, and "fall" has none. Fix: the value is 44 px, and every paired row keeps the column free.
