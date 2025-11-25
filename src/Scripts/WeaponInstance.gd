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
		if c is MeshInstance3D:
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
			_imu_hammer_attack(direction, hand)
			pass
		Weapon.WeaponType.GUN:
			_attack_shoot()
		_:
			push_warning("Unknown weapon type")

func _imu_sword_attack(direction: String, hand: Node3D) -> void:
	if is_attacking or weapon_data == null:
		return

	is_attacking = true

	# Save original hand transform
	var original_hand_pos = hand.position
	var original_hand_rot = hand.rotation_degrees
	var original_weapon_rot = rotation_degrees

	# --- Hand swing motion ---
	var hand_position_offset := Vector3.ZERO
	var hand_rotation_offset := Vector3.ZERO
	
	rotation_degrees = Vector3(-130, 0, 0)

	match direction:
		"up":               
			hand_position_offset = Vector3(0, 0.5, 0)
			model_holder.rotate_object_local(Vector3(0,1,0), deg_to_rad(90))
		"down":             
			hand_position_offset = Vector3(0, -0.5, 0)
			model_holder.rotate_object_local(Vector3(0,1,0), deg_to_rad(90))
		"left":             
			hand_position_offset = Vector3(-0.5, 0, 0)
			hand_rotation_offset = Vector3(0, 5, 0)
		"right":            
			hand_position_offset = Vector3(0.5, 0, 0)
			hand_rotation_offset = Vector3(0, 5, 0)
		"diag_up_left":     
			hand_position_offset = Vector3(-0.35, 0.35, 0)
			hand_rotation_offset = Vector3(-20, 20, 0)
		"diag_up_right":    
			hand_position_offset = Vector3(0.35, 0.35, 0)
			hand_rotation_offset = Vector3(-20, -20, 0)
		"diag_down_left":   
			hand_position_offset = Vector3(-0.35, -0.35, 0)
			hand_rotation_offset = Vector3(20, 20, 0)
		"diag_down_right":  
			hand_position_offset = Vector3(0.35, -0.35, 0)
			hand_rotation_offset = Vector3(20, -20, 0)
		"stab":             hand_position_offset = Vector3(0, 0, -0.5)

	# Apply hand movement
	hand.position += hand_position_offset
	hand.rotation_degrees += hand_rotation_offset

	_enable_hitbox(true)

	# --- Smoothly reset ---
	await _smooth_reset_rotation(original_hand_pos, original_hand_rot, original_weapon_rot, hand)

	_enable_hitbox(false)
	is_attacking = false

func _imu_hammer_attack(direction: String, hand: Node3D) -> void:
	if is_attacking or weapon_data == null:
		return

	is_attacking = true

	# Save original hand transform
	var original_hand_pos = hand.position
	var original_hand_rot = hand.rotation_degrees
	var original_weapon_rot = rotation_degrees

	# --- Hand swing motion ---
	var hand_position_offset := Vector3.ZERO
	var hand_rotation_offset := Vector3.ZERO
	
	rotation_degrees = Vector3(-130, 0, 0)

	#TODO: make nicer animations
	match direction:
		"down":             
			hand_position_offset = Vector3(0, -0.7, 0)
			hand_rotation_offset = Vector3(-20.0, 0, 0)
		"left":             
			hand_position_offset = Vector3(-0.3, -0.3, 0)
			hand_rotation_offset = Vector3(-15.0, 10.0, 0)
		"right":            
			hand_position_offset = Vector3(0.3, -0.3, 0)
			hand_rotation_offset = Vector3(-15.0, 10.0, 0)
		"stab":             
			hand_position_offset = Vector3(0, -0.2, -0.5)
			hand_rotation_offset = Vector3(-25.0, 0, 0)

	# Apply hand movement
	hand.position += hand_position_offset
	hand.rotation_degrees += hand_rotation_offset

	_enable_hitbox(true)

	# --- Smoothly reset ---
	await _smooth_reset_rotation(original_hand_pos, original_hand_rot, original_weapon_rot, hand)

	_enable_hitbox(false)
	is_attacking = false

# Smooth timed return of weapon rotation
func _smooth_reset_rotation(orig_hand_pos: Vector3, orig_hand_rot: Vector3, orig_weapon_rot: Vector3, hand: Node3D) -> void:
	var t := 0.0
	var dur := weapon_data.attack_speed

	while t < dur:
		t += get_process_delta_time()
		var alpha := t / dur

		hand.position = hand.position.lerp(orig_hand_pos, alpha)
		hand.rotation_degrees = hand.rotation_degrees.lerp(orig_hand_rot, alpha)
		rotation_degrees = rotation_degrees.lerp(orig_weapon_rot, alpha)
		model_holder.rotation_degrees = model_holder.rotation_degrees.lerp(orig_weapon_rot, alpha**2)

		await get_tree().process_frame
	is_attacking = false

func _perform_standard_attack(hand : String):
	if weapon_data == null:
		return

	match weapon_data.type:
		Weapon.WeaponType.BLADE:
			_attack_slash(hand)
		Weapon.WeaponType.HAMMER:
			_attack_slam(hand)
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

func _attack_slam(hand : String):
	if is_attacking:
		return
		
	is_attacking = true
	
	var anim_name = "attack_slam_%s" % hand.to_lower()
	emit_signal("request_animation", anim_name)
	_enable_hitbox(true)
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	_enable_hitbox(false)
	
	is_attacking = false

func _attack_shoot():
	if is_attacking:
		return
		
	is_attacking = true
	var enemy = _retro_hitscan()
	if enemy:
		enemy.take_damage(weapon_data.damage)
		
	# TODO: add effect
	
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	is_attacking = false

func _retro_hitscan() -> Node:
	var origin = global_transform.origin
	var forward = -global_transform.basis.z # this is the player forward direction
	
	# Convert it to 2D because we don't care about enemy height
	var origin2d = Vector2(origin.x, origin.z)
	var forward2d = Vector2(forward.x, forward.z).normalized()
	
	var max_shoot_dist = 10 #weapon_data.range if weapon_data.has("range") else
	var end2d = origin2d + forward2d * max_shoot_dist
	
	var best_target : Node = null
	var best_dist := INF
	
	# Width of the shot (will be useful for a shotgun for example)
	var tolerance : float = 1.0
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var pos = enemy.global_transform.origin
		var pos2d = Vector2(pos.x, pos.z)
		
		var d = Geometry2D.get_closest_point_to_segment(pos2d, origin2d, end2d)
		if d <= tolerance:
			var dist = origin2d.direction_to(pos2d)
			if dist < best_dist:
				best_dist = dist
				best_target = enemy
	
	return best_target

func _enable_hitbox(enabled : bool) -> void:
	if hitbox:
		hitbox.monitoring = enabled
		hitbox.monitorable = enabled
		
## Area3D based detection for keyboard and mouse
func _on_Hitbox_body_entered(body) -> void:
	if body.is_in_group("enemy"):
		body.take_damage(weapon_data.damage)
