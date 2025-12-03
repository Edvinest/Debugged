extends CharacterBody3D

@onready var firstPersonCamera = $FirstPersonCamera
@onready var thirdPersonCamera = $ThirdPersonCamera

@export var left_weapon : Weapon = null
@export var right_weapon : Weapon = null

@onready var Hands = $"PlayerBody/Hands"
var using_first_person : bool

var mouse_sensitivity := 0.002
var controller_sensitivity := 2.0
var gravity := 30

#Speed component
@export var speed_component : PlayerSpeedComponent = null
var speed: float

#Health component
@export var health_component: PlayerHealthComponent = null
var MAX_HEALTH: float
var health: float

@onready var hp_bar: ProgressBar = $HUD/Control/ProgressBar
@onready var death_screen: CanvasLayer = %DEATH_SCREEN

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
	Hands.set_weapons(left_weapon, right_weapon)
	
	if using_first_person:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		set_camera_mode(using_first_person)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_connected_joypads().is_empty():
		using_first_person = false
	else:
		using_first_person = true
		
func _process(delta: float) -> void:
	MAX_HEALTH = health_component.player_max_health
	hp_bar.max_value = MAX_HEALTH
	#print(hp_bar.max_value)
	speed = speed_component.player_speed
	hp_bar.value = health
	if health <= 0:
		death_screen.show()
	
	var right_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var right_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)

	# Deadzone
	if abs(right_x) < 0.2:
		right_x = 0
	if abs(right_y) < 0.2:
		right_y = 0

	if using_first_person:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		set_camera_mode(using_first_person)

		# Apply controller look (same logic as mouse)
		rotate_y(-right_x * delta * controller_sensitivity)  # yaw on player
		firstPersonCamera.rotate_x(-right_y * delta * controller_sensitivity)  # pitch on camera
		firstPersonCamera.rotation.x = clamp(firstPersonCamera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event):
	if event is InputEventMouseMotion and using_first_person:
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

	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if not using_first_person:
		var mousePosition = get_viewport().get_mouse_position()
		var from = thirdPersonCamera.project_ray_origin(mousePosition)
		var to = from + thirdPersonCamera.project_ray_normal(mousePosition) * 1000
		
		var query = PhysicsRayQueryParameters3D.new()
		query.from = from
		query.to = to
		query.exclude = [self]
		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(query)
		
		if result:
			var target_pos = result.position
			var lookDir = target_pos - global_transform.origin
			lookDir.y = 0
			
			if lookDir.length() > 0.01:
				var target_angle = atan2(-lookDir.x, -lookDir.z)
				$PlayerBody.rotation.y = target_angle
			
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func set_camera_mode(first_person : bool):
	using_first_person = first_person
	firstPersonCamera.current = first_person
	thirdPersonCamera.current = not first_person
	$PlayerBody/Hands.using_first_person = first_person

func take_damage(damage_to_take):
	health -= damage_to_take
	print("Player took damage: " + str(damage_to_take))


func _on_player_spawn_points_on_spawn_point_selected(point: Marker3D) -> void:
	if point is Marker3D:
		spawn_point = point
	else:
		push_error("Player: Invalid spawn point.")
