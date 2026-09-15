---
revision: 5
id: 01M2JP3ZK9K5GRK999FNK1N2RH
---

Landed in b242c3e. Grid's greedy Fit, Wants, Room and Named are gone. The flow asks every block on a line for flow.rows rows and raises the rows while the line is too wide, each block capped at floor(sqrt(n / 1.618)) and never below the rows it needs to fit the window alone. A new pile starts the next line only when no block can grow. A split pile with everything on one side draws in one lane. ORDER follows Baganator's TBC order. Collect(owner, state, fold, marks) adds section, rule and break rows for the bag window only. Grid.Block(index) exposes each pile's left, top, lane, rest and width for the harness. Gate at zero.
