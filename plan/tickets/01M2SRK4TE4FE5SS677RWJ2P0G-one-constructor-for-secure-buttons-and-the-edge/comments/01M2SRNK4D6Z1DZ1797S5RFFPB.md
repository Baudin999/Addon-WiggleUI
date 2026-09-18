---
revision: 5
id: 01M2SRNK4D6Z1DZ1797S5RFFPB
---

Landed 0475bbd. Twelve sites moved onto UI/Press.lua. Charge/Icon and Targeting/Switch had the dead-click shape latent (AnyDown, attribute unset); they now set useOnKeyDown true. Ability.New takes (parent, name, palette) and builds a plain frame; a pressable square is Ability.Dress(UI.Press.Button(...)). Next: the combat-safe buff cancel builds its buttons with Press.Button.
