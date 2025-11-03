@tool
extends Node3D

@export var weapon_data : Weapon
@onready var model_holder : Node3D = $ModelHolder
@onready var hitbox : Area3D = $ModelHolder/Area3D
var is_attacking : bool = false

func _physics_process(_delta: float) -> void:
	if is_attacking:
		if get_parent().get_parent().using_first_person():
			_motion_hit_detection()

func set_weapon_data(data : Weapon) -> void:
	weapon_data = data
	if weapon_data and weapon_data.mesh:
		_load_model(weapon_data.mesh)

func _load_model(scene: PackedScene) -> void:
	for c in model_holder.get_children():
		c.queue_free()
		
	var instance = scene.instantiate()
	model_holder.add_child(instance)

	# Only needed if we don't use animation based attacks or want to offset model
	instance.transform.origin = weapon_data.weapon_position
	instance.rotation_degrees = weapon_data.weapon_rotation

func start_attack(is_motion: bool) -> void:
	if is_attacking:
		return
		
	is_attacking = true
	if not is_motion:
		_perform_standard_attack()
	else:
		await get_tree().create_timer(0.3).timeout
		is_attacking = false

func _perform_standard_attack():
	if weapon_data == null:
		return

	match weapon_data.weapon_type:
		Weapon.WeaponType.BLADE:
			_attack_slash()
		Weapon.WeaponType.HAMMER:
			_attack_slam()
		Weapon.WeaponType.GUN:
			_attack_shoot()
		_:
			push_warning("Unknown weapon type")
	
func _attack_slash():
	#TODO: implement animations
	_enable_hitbox(true)
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	_enable_hitbox(false)

func _attack_slam():
	# TODO: Implement it later
	pass

func _attack_shoot():
	# TODO: Implement it later
	pass

func _enable_hitbox(enabled : bool) -> void:
	if hitbox:
		hitbox.monitoring = enabled
		hitbox.monitorable = enabled
		
## Area3D based detection for keyboard and mouse
func _on_Hitbox_body_entered(body) -> void:
	if body.is_in_group("enemy"):
		body.take_damage(weapon_data.damage)

## for IMU based attacks
## uses the tip of the weapon to track each hit
func _motion_hit_detection():
	pass
