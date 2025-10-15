extends CharacterBody3D

@export var speed := 5.0
@export var jump_velocity := 4.5
@onready var firstPersonCamera = $FirstPersonCamera
@onready var thirdPersonCamera = $ThirdPersonCamera
var using_first_person : bool

var mouse_sensitivity := 0.002
@export var gravity := 20

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_camera_mode(using_first_person)
	
	if Input.get_connected_joypads().is_empty():
		using_first_person = false

func _process(delta: float) -> void:
	var right_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) # horizontal
	var right_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) # vertical

	# Deadzone
	if abs(right_x) < 0.2:
		right_x = 0
	if abs(right_y) < 0.2:
		right_y = 0

	# Apply to firstPersonCamera rotation
	firstPersonCamera.rotate_y(-right_x * delta * 2.0)  # yaw
	firstPersonCamera.rotate_x(-right_y * delta * 2.0)  # pitch
	firstPersonCamera.rotation.x = clamp(firstPersonCamera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

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

	if using_first_person:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
		if direction != Vector3.ZERO:
			var target_yaw = atan2(-direction.x, -direction.z)
			$PlayerBody.rotation.y = target_yaw # lerp_angle($PlayerBody.rotation.y, target_yaw, delta * 1.0)
			
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		

	#Added for test: Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	#Added for test: Respawn in case of falling out of map.	
	if global_transform.origin.y <= -10.0:
		global_transform.origin = Vector3(0, 5, 0)
	
	move_and_slide()

func set_camera_mode(first_person : bool):
	using_first_person = first_person
	firstPersonCamera.current = first_person
	thirdPersonCamera.current = not first_person
	$PlayerBody/Hands.using_first_person = first_person
	
	# Testing feature: Sync first person camera to character rotation.
	#Note: When snapping back to first person, camera does not align with the
	#third person direction of the character, instead the character snaps to 
	#the default FP camera direction.
	if first_person:
		# Align player body rotation to camera rotation to prevent inverted controls
		var cam_yaw = firstPersonCamera.rotation.y
		$PlayerBody.rotation.y = cam_yaw
