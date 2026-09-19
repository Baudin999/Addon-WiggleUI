---
revision: 5
id: 01M2WEZTE3XM6EM8KHTY1MDWYC
---

Landed in 699b35f. Swapped to desert02, which kept the first desert's inset, corner and period because the frame is the same. Rails are rolled like the middle. One wrong turn, reverted before commit: pale-blue flecks at the top of the rail joins in the preview looked like leftover margin. Measuring the alpha showed forest has no gap there and desert has one 4 px dip that the painting itself has, so they were the frame's outline against the preview background. Real fix kept: transparent texels were white (then black after a premultiplied resize), which the client's filtering pulls into the edge. The bake now bleeds the frame colour under them after the resize. Still not seen in the client.
