---
revision: 5
id: 01M2ZRQYWG7RYR58JX5QK1GXZP
---

Landed at 8a60a63f. Breakdown/Graph.lua is new, Split holds four bands at once and returns the pooled row beside them, the window is 868 wide with the pane on the right, and the reset is in its footer.

Worth knowing for whatever touches this next. The plot columns are a whole number of pixels by construction, not by rounding at the point of use: 262 over three is 87 and a third and 33-anchors fails every label and every dot at once. plot.column is floored and the box is three of it.

Two rules in the drawing that are not obvious from the picture and are both gated. A band with no attempts leaves a hole rather than a point on the floor, because a line dropping to zero at the right hand end reads as a miss rate that improves against bosses. And an outcome that has never happened at all gets no line: six flat lines along the floor were burying the two that meant something, and the legend dims the unlit ones rather than reflowing, so it can be learned once.

Split fills one table and hands it back, so a caller wanting two readings copies the first out as numbers between the calls. PaintPane does that for the lifetime total. A second call clobbers the first.

Ruled out: putting the graph in UI/. It has one caller and the kit's own rule is that a widget moves there on the second one.
