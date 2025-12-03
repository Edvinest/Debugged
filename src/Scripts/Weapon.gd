class_name Weapon extends Resource

enum WeaponType {BLADE, HAMMER, GUN}

@export_category("Basic information")
@export var name : String
@export var type : int = WeaponType.BLADE
@export var damage : float = 10.0
@export var attack_speed : float = 1.0
@export var mesh : PackedScene

@export_category("Weapon orientation")
@export var weapon_position : Vector3
@export var weapon_rotation : Vector3
@export var weapon_scale : Vector3 = Vector3(1, 1, 1)
