extends CharacterBody3D

signal player_died

@export var speed := 5.0
@onready var firstPersonCamera = $FirstPersonCamera
@onready var thirdPersonCamera = $ThirdPersonCamera
@onready var stats = Firebase.Firestore.collection("Stats")
@onready var ach = Firebase.Firestore.collection("Achievements")
var score=PlayerData.highscore

@export var left_weapon : Weapon = PlayerData.left_hand_weapon
@export var right_weapon : Weapon = PlayerData.right_hand_weapon

var using_first_person : bool
var pause_fl = false
var mouse_sensitivity := 0.002
var controller_sensitivity := 2.0
var gravity := 30

#Speed component
@export var speed_component : PlayerSpeedComponent = null

var tp_camera_original_rotation : Vector3

#Health component
@export var health_component: PlayerHealthComponent = null
var MAX_HEALTH: float
var health: float

@onready var hp_bar: ProgressBar = $HUD/Control/ProgressBar
@onready var death_screen = %DEATH_SCREEN

var spawn_point = null

func _ready():
	if spawn_point != null:
		global_position = spawn_point.global_position 
	
	if health_component == null:
		push_warning("No HEALTH component is scope.")
	MAX_HEALTH = health_component.player_max_health
	health = MAX_HEALTH

	if speed_component == null:
		push_warning("No SPEED component is scope.")
	speed = speed_component.player_speed
	
	death_screen.hide()
	if left_weapon != null or right_weapon != null:
		$Body.set_weapons(left_weapon, right_weapon)
	tp_camera_original_rotation = thirdPersonCamera.global_rotation
	
	using_first_person = Input.get_connected_joypads().size() > 0
	set_camera_mode(using_first_person)
	
func _process(delta: float) -> void:
	if not using_first_person:
		_update_animation()
	
	if pause_fl:
		return
	
	MAX_HEALTH = health_component.player_max_health
	hp_bar.max_value = MAX_HEALTH
	#print(hp_bar.max_value)
	speed = speed_component.player_speed
	hp_bar.value = health
	if health <= 0:
		death_screen.show()
		player_died.emit()
		var doc = await stats.get_doc(PlayerData.uid)
		var current_highscore = doc.get_value("highscore")

		if score > current_highscore:
			
			# Achievement ID-k listája a külön dokumentumból
			var ach_doc = await ach.get_doc("achievements")
			var ach_list = ach_doc.get_value("achievement_id_list")
			var achievements = doc.get_value("achievements")  # JELENLEGI lista
			
			for ach_id in ach_list:
				var ach_data = await ach.get_doc(ach_id)
				#print("Checking:", ach_id, "→", ach_data)
				
				var required_score = ach_data.get_value("score_needed")
				
				if score >= required_score:
					# Már ne legyen duplikátum
					if ach_id not in achievements:
						achievements.append(ach_id)

			# FIRESTORE UPDATE – csak egyszer
			await stats.set_doc(PlayerData.uid, {
				"u_id": PlayerData.uid,
				"highscore": score,
				"achievements": achievements
			})
		

	var right_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var right_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)

	# Deadzone
	
	if abs(right_x) > 0.15 and using_first_person:
		rotate_y(-right_x * delta * controller_sensitivity)  
	
	if abs(right_y) > 0.15:
		firstPersonCamera.rotate_x(-right_y * delta * controller_sensitivity)
		firstPersonCamera.rotation.x = clamp(firstPersonCamera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if using_first_person:
			rotate_y(-event.relative.x * mouse_sensitivity)
			firstPersonCamera.rotate_x(-event.relative.y * mouse_sensitivity)
			firstPersonCamera.rotation.x = clamp(firstPersonCamera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _input(event):
	if event.is_action_pressed("toggle_view"):
		using_first_person = !using_first_person
		set_camera_mode(using_first_person)
		
func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = Vector3.ZERO
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if using_first_person:
		var bodyBasis = Basis(Vector3.UP, rotation.y)
		direction = (bodyBasis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
	else:
		direction = (thirdPersonCamera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		_third_person_controls()
			
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _update_animation() -> void:
	if velocity.length() < 0.1:
		$AnimationTree["parameters/conditions/idle"] = true
		$AnimationTree["parameters/conditions/is_moving"] = false
	else:
		$AnimationTree["parameters/conditions/idle"] = false
		$AnimationTree["parameters/conditions/is_moving"] = true
		
func _third_person_controls():
		var mousePosition = get_viewport().get_mouse_position()
		var from = thirdPersonCamera.project_ray_origin(mousePosition)
		var dir = thirdPersonCamera.project_ray_normal(mousePosition)
		
		var t = (global_transform.origin.y - from.y) / dir.y
		if t < 0:
			return

		var target_pos = from + dir * t
		var lookDir = target_pos - global_transform.origin
		lookDir.y = 0
		lookDir = lookDir.normalized()
		
		var target_angle = atan2(-lookDir.x, -lookDir.z)
		$Body/ThirdPersonModel.rotation.y = target_angle + PI

func set_camera_mode(first_person: bool):
	using_first_person = first_person
	
	RenderingServer.global_shader_parameter_set("is_third_person", not first_person)

	if first_person:
		$Body/FirstPersonModel.visible = true
		$Body/ThirdPersonModel.visible = false
		
		var f = -$Body/ThirdPersonModel.global_transform.basis.z
		rotation.y = atan2(f.x, f.z)
		$Body/FirstPersonModel.global_rotation.y = global_rotation.y
		firstPersonCamera.rotation.x = 0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		$Body/FirstPersonModel.visible = false
		$Body/ThirdPersonModel.visible = true
		rotation.y = 0
		thirdPersonCamera.global_rotation = tp_camera_original_rotation
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	firstPersonCamera.current = first_person
	thirdPersonCamera.current = not first_person
	$Body.set_first_person(first_person)
	%PauseMenu.set_p_mode(first_person)

func take_damage(damage_to_take):
	health -= damage_to_take
	#print("Player took damage: " + str(damage_to_take))


func _on_player_spawn_points_on_spawn_point_selected(point: Marker3D) -> void:
	if point is Marker3D:
		spawn_point = point
	else:
		push_error("Player: Invalid spawn point.")
