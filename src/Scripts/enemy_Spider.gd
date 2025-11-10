extends CharacterBody3D

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody3D = $"../Player"

const DETECTION_DISTANCE = 10.0

func _physics_process(delta: float) -> void:
	var distance = global_position.distance_to(player.global_position)
	
	if distance < DETECTION_DISTANCE:
		var target = player.global_position
		target.y = global_position.y
		look_at(target, Vector3.UP)
		rotate_y(-50)
