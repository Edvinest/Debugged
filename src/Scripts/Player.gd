extends CharacterBody3D

@export var speed := 10.0
@onready var firstPersonCamera = $FirstPersonCamera
@onready var thirdPersonCamera = $ThirdPersonCamera

@export var left_weapon : Weapon = null
@export var right_weapon : Weapon = null

@onready var Hands = $"PlayerBody/Hands"
var using_first_person : bool

var mouse_sensitivity := 0.002
var controller_sensitivity := 2.0
var gravity := 30

var tp_camera_original_rotation : Vector3

func _ready():
	Hands.set_weapons(left_weapon, right_weapon)
	tp_camera_original_rotation = thirdPersonCamera.global_rotation
	
	using_first_person = Input.get_connected_joypads().size() > 0
	
func _process(delta: float) -> void:
	if not using_first_person:
		return
		
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

func _third_person_controls():
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

func set_camera_mode(first_person: bool):
	using_first_person = first_person

	if first_person:
		rotation.y = $PlayerBody.rotation.y  
		$PlayerBody.global_rotation.y = global_rotation.y
		firstPersonCamera.rotation.x = 0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		rotation.y = 0
		thirdPersonCamera.global_rotation = tp_camera_original_rotation
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	firstPersonCamera.current = first_person
	thirdPersonCamera.current = not first_person
	
	$PlayerBody/Hands.using_first_person = first_person
