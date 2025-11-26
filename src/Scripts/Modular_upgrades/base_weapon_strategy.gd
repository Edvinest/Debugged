class_name BaseWeaponStrategy extends Resource

##Base strategy that all other weapon strategies will inherit from.

@export var upgrade_name: String = "*upgrade name"
@export var texture: Texture2D = null
@export var upgrade_specs: String = "*upgrade specs"
@export var upgrade_cost: float = 0.0
@export var allowed_weapon_types: Array = []  # -> when empty applies to all


func apply_upgrade(weapon: Weapon):
    pass

