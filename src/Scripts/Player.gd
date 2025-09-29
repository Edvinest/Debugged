extends CharacterBody3D

@export var speed := 5.0
@export var jump_velocity := 4.5
@onready var camera = $Camera3D

var mouse_sensitivity := 0.002
var gravity := 30

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	# Right stick is typically on JoyCon-R
	var right_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) # horizontal
	var right_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) # vertical

	# Deadzone
	if abs(right_x) < 0.2:
		right_x = 0
	if abs(right_y) < 0.2:
		right_y = 0

	# Apply to camera rotation
	camera.rotate_y(-right_x * delta * 2.0)  # yaw
	camera.rotate_x(-right_y * delta * 2.0)  # pitch
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if not is_on_floor():
		velocity.y -= gravity * delta

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
