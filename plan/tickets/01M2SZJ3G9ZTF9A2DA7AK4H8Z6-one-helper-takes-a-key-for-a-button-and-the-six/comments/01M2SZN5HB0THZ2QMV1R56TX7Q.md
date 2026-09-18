---
revision: 5
id: 01M2SZN5HB0THZ2QMV1R56TX7Q
---

Landed b78c8b6. The first commit attempt tripped the rule that UI/ names no setting; the holder takes a store now and ns.KeySetting(field) in Core builds it, so the fix did not leave four copies of an adapter behind. Still copied and not in this card: Marking/Keys.lua and Hover/Cast.lua run the same many-keys-on-one-button loop (held, heldAny, proven, warn once, the unproven status line), and the pcall-guarded SetOverrideBindingClick and ClearOverrideBindings wrappers appear in Marking, Cast and Buttons/Bars.
