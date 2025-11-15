@tool
extends Node3D

@export var weapon_data : Weapon:
	set(value):
		weapon_data = value
		if weapon_data and weapon_data.mesh:
			_load_model(weapon_data.mesh)
		if Engine.is_editor_hint():
			return

@onready var model_holder : Node3D = $ModelHolder
@onready var hitbox : Area3D = $ModelHolder/Area3D
var is_attacking : bool = false

signal request_animation(anim_name: String)

func set_weapon_data(data : Weapon) -> void:
	weapon_data = data
	if weapon_data and weapon_data.mesh:
		_load_model(weapon_data.mesh)

func _load_model(scene: PackedScene) -> void:
	if not model_holder:
		model_holder = get_node_or_null("ModelHolder")
		if not model_holder:
			push_warning("No ModelHolder found")
			return
		
	for c in model_holder.get_children():
		c.queue_free()
	
	var instance = scene.instantiate()
	model_holder.add_child(instance)
	
	if Engine.is_editor_hint():
		instance.owner = get_tree().edited_scene_root

	# Only needed if we don't use animation based attacks or want to offset model
	instance.transform.origin = weapon_data.weapon_position
	instance.rotation_degrees = weapon_data.weapon_rotation

func start_motion_attack(direction: String, hand: Node3D) -> void:
	if is_attacking:
		return
	
	if weapon_data == null:
		return

	match weapon_data.type:
		Weapon.WeaponType.BLADE:
			_imu_sword_attack(direction, hand)
		Weapon.WeaponType.HAMMER:
			_attack_slam()
		Weapon.WeaponType.GUN:
			_attack_shoot()
		_:
			push_warning("Unknown weapon type")

func _imu_sword_attack(direction: String, hand : Node3D) -> void:
	if weapon_data == null:
		return
	
	# Since weapons point upward, rotate them forward 90°
	# so a slash looks forward, not vertical.
	var forward_offset := Vector3(-90, 0, 0)

	# Direction-based temporary rotation
	var dir_rot := Vector3.ZERO

	match direction:
		"up":
			dir_rot = Vector3(-45, 0, 0)     # tilt up
		"down":
			dir_rot = Vector3(45, 0, 0)      # tilt down
		"left":
			dir_rot = Vector3(0, 45, 0)
		"right":
			dir_rot = Vector3(0, -45, 0)
		"diag_down_right":
			dir_rot = Vector3(0, -45, 0)
		"diag_down_left":
			dir_rot = Vector3(0, -45, 0)
		"diag_up_right":
			dir_rot = Vector3(0, -45, 0)
		"diag_up_left":
			dir_rot = Vector3(0, -45, 0)
			
		"stab":
			dir_rot = Vector3(-10, 0, 0)

	var final_rot = forward_offset + dir_rot
	var original_rotation = hand.rotation_degrees
	rotation_degrees = final_rot
	_smooth_reset_rotation(original_rotation, hand)

# Smooth timed return of weapon rotation
func _smooth_reset_rotation(original_rot: Vector3, hand: Node3D) -> void:
	var t := 0.0
	var duration := weapon_data.attack_speed
	while t < duration:
		t += get_process_delta_time()
		hand.rotation_degrees = hand.rotation_degrees.lerp(original_rot, t / duration)
		await get_tree().process_frame

func _perform_standard_attack(hand : String):
	if weapon_data == null:
		return

	match weapon_data.type:
		Weapon.WeaponType.BLADE:
			_attack_slash(hand)
		Weapon.WeaponType.HAMMER:
			_attack_slam()
		Weapon.WeaponType.GUN:
			_attack_shoot()
		_:
			push_warning("Unknown weapon type")
	
func _attack_slash(hand : String):
	if is_attacking:
		return
		
	is_attacking = true
	
	var anim_name = "attack_slash_%s" % hand.to_lower()
	emit_signal("request_animation", anim_name)
	_enable_hitbox(true)
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	_enable_hitbox(false)
	
	is_attacking = false

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
