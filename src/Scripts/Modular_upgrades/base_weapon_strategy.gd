class_name BaseWeaponStrategy 
extends BaseUpgradeStrategy

##Base strategy that all other weapon strategies will inherit from.

@export var allowed_weapon_types: Array[Weapon] = []  # -> when empty applies to all


func apply_upgrade(weapon: Weapon):
    pass

