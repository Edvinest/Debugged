extends Resource
class_name Weapon

enum WeaponType {BLADE, HAMMER, GUN}

@export var weapon_name : String
@export var weapon_type : int = WeaponType.BLADE
@export var damage : float = 10.0
@export var attack_speed : float = 1.0
@export var model_scene : PackedScene

# TODO: implement weapon animation dictionary
# var attack_animations : Dictionary = {}
