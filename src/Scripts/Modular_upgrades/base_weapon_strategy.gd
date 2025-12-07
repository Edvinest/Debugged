class_name BaseWeaponStrategy 
extends BaseUpgradeStrategy

##Base strategy that all other weapon strategies will inherit from.

@export var allowed_weapon_type: Weapon = null 


func apply_upgrade(weapon: Weapon):
    pass

