extends Node3D

@export var weapon_data : Weapon

@onready var model_holder : Node3D = $ModelHolder
@onready var hitbox : Area3D = $ModelHolder/Area3D
@onready var tp_camera = %ThirdPersonCamera
@onready var fp_camera = %FirstPersonCamera
@onready var sfx_player = $AudioStream

var is_attacking : bool = false
var enemies_hit_this_attack: Array = []
signal request_animation(anim_name: String)
signal request_fp_animation(anim_name: String)

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
	instance.scale = weapon_data.weapon_scale

func _play_attack_sound():
	if weapon_data and weapon_data.attack_sound:
		sfx_player.stream = weapon_data.attack_sound
		
		sfx_player.pitch_scale = randf_range(0.9, 1.1)
		sfx_player.play()

func start_motion_attack(direction: String, hand: String) -> void:
	if is_attacking:
		return
	
	if weapon_data == null:
		return

	match weapon_data.type:
		Weapon.WeaponType.BLADE:
			_imu_sword_attack(direction, hand)
		Weapon.WeaponType.HAMMER:
			_imu_hammer_attack(direction, hand)
		_:
			push_warning("Unknown weapon type")

func _imu_sword_attack(direction: String, hand: String) -> void:
	if is_attacking or weapon_data == null:
		return

	is_attacking = true
	enemies_hit_this_attack.clear()
	_play_attack_sound()
	
	match direction:
		"up":               
			emit_signal("request_fp_animation", "swing_up_%s" % hand)
		"down":
			emit_signal("request_fp_animation", "swing_down_%s" % hand)             
		"left":             
			emit_signal("request_fp_animation", "swing_left_%s" % hand)             
		"right":            
			emit_signal("request_fp_animation", "swing_right_%s" % hand)             
		"stab":
			emit_signal("request_fp_animation", "stab_%s" % hand)

	_enable_hitbox(true)
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	_enable_hitbox(false)
	is_attacking = false

func _imu_hammer_attack(direction: String, hand: String) -> void:
	if is_attacking or weapon_data == null:
		return

	is_attacking = true
	enemies_hit_this_attack.clear()
	_play_attack_sound()
	
	match direction:
		"down": emit_signal("request_fp_animation", "swing_down_%s" % hand)
		"left": emit_signal("request_fp_animation", "swing_left_%s" % hand)           
		"right": emit_signal("request_fp_animation", "swing_right_%s" % hand)          
		"stab": emit_signal("request_fp_animation", "stab_%s" % hand)          

	_enable_hitbox(true)
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	_enable_hitbox(false)
	is_attacking = false
	
func _imu_gun_shoot(hand : String) -> void:
	if is_attacking:
		return
		
	is_attacking = true
	enemies_hit_this_attack.clear()
	_play_attack_sound()
	var enemy = _imu_aim_assist()
	if enemy:
		enemy.take_damage(weapon_data.damage)
	
	emit_signal("request_fp_animation", "shoot_%s" % hand)
	#TODO: add effect
	
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	is_attacking = false

func _imu_aim_assist(max_dist : float = 10.0, fov_degrees : float = 15.0) -> Node:
	var origin = fp_camera.global_transform.origin
	var forward = -fp_camera.global_transform.basis.z
	
	var best_target : Node = null
	var best_angle = deg_to_rad(fov_degrees)
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var to_enemy = enemy.global_transform.origin - origin
		var dist = to_enemy.length()
		
		if dist > max_dist:
			continue  # too far
		
		var dir = to_enemy.normalized()
		var angle = acos(forward.dot(dir))
		
		if angle < best_angle:
			best_angle = angle
			best_target = enemy
	
	return best_target

func _perform_standard_attack():
	if weapon_data == null:
		return

	match weapon_data.type:
		Weapon.WeaponType.BLADE:
			_attack_slash()
		Weapon.WeaponType.HAMMER:
			_attack_slam()
		Weapon.WeaponType.GUN:
			_attack_shoot()
		_:
			push_warning("Unknown weapon type")
	
func _attack_slash():
	if is_attacking:
		return
		
	is_attacking = true
	enemies_hit_this_attack.clear()
	_play_attack_sound()
	var anim_name = "sword_swing_"
	emit_signal("request_animation", anim_name)
	_enable_hitbox(true)
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	_enable_hitbox(false)
	
	is_attacking = false

func _attack_slam():
	if is_attacking:
		return
		
	is_attacking = true
	enemies_hit_this_attack.clear()
	_play_attack_sound()
	
	var anim_name = "hammer_swing_"
	emit_signal("request_animation", anim_name)
	_enable_hitbox(true)
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	_enable_hitbox(false)
	
	is_attacking = false

func _attack_shoot():
	if is_attacking:
		return
		
	is_attacking = true
	enemies_hit_this_attack.clear()
	_play_attack_sound()
	
	var enemy = _retro_hitscan()
	if enemy:
		enemy.take_damage(weapon_data.damage)
		
	# TODO: add effect
	var anim_name = "gun_shoot_"
	emit_signal("request_animation", anim_name)
	await get_tree().create_timer(weapon_data.attack_speed).timeout
	is_attacking = false

func _retro_hitscan() -> Node:
	var mouse_pos = get_viewport().get_mouse_position()

	var origin3d = tp_camera.project_ray_origin(mouse_pos)
	var dir3d = tp_camera.project_ray_normal(mouse_pos)

	# Project ray onto the ground plane (XZ)
	var t = (global_transform.origin.y - origin3d.y) / dir3d.y
	if t < 0:
		return null

	var end3d = origin3d + dir3d * t

	# Convert to 2D for Doom-style hitscan
	var origin2d = Vector2(origin3d.x, origin3d.z)
	var end2d = Vector2(end3d.x, end3d.z)

	var best_target : Node = null
	var best_dist := INF
	var tolerance := 0.75

	for enemy in get_tree().get_nodes_in_group("enemy"):
		var pos = enemy.global_transform.origin
		var pos2d = Vector2(pos.x, pos.z)

		var closest_point = Geometry2D.get_closest_point_to_segment(
			pos2d,
			origin2d,
			end2d
		)

		var dist_to_segment = pos2d.distance_to(closest_point)

		if dist_to_segment <= tolerance:
			# Distance ALONG the ray
			var dist_along = origin2d.distance_to(closest_point)
			if dist_along < best_dist:
				best_dist = dist_along
				best_target = enemy

	return best_target


func _enable_hitbox(enabled : bool) -> void:
	if hitbox:
		hitbox.monitoring = enabled
		hitbox.monitorable = enabled
		
## Area3D based detection for keyboard and mouse
func _on_area_3d_body_entered(body: Node3D) -> void:
	#print("----IN RANGE-----")
	if not is_attacking:
		return
		
	if not body.is_in_group("enemy"):
		return
		
	if body in enemies_hit_this_attack:
		return
		
	enemies_hit_this_attack.append(body)

	if body.has_method("take_damage"):
		body.take_damage(weapon_data.damage)
	else:
		push_warning("Body does not have 'take_damage' method")
