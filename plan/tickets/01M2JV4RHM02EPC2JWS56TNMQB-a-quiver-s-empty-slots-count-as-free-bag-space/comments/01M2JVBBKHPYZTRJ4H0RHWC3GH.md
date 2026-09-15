---
revision: 5
id: 01M2JVBBKHPYZTRJ4H0RHWC3GH
---

Cause. Bags.lua Sweep counted every empty slot in all five bags as free, including the slots of a quiver, ammo pouch, soul bag or herb bag.  Fix. ns.BagFamily reads the second return of GetContainerNumFreeSlots. A bag with a nonzero family keeps its slots out of state.free and state.slots, and its empty slots go in pile bag1..bag4, renamed after the worn bag and folded to one square like Empty. Grid marks every fold square with button.fold and the hold counts it off state.vacant[pile]. The hold's check against state.carried covers every bag. Bags.Entry bounds on state.walked, because state.slots no longer covers the special bags.  Gate. 55-bags carries a two-slot quiver in bag 4 and checks the footer numbers stay 3 free of the ordinary slots and the quiver folds to one square counting 2. Landed in c609ec7.
