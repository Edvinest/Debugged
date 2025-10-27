extends CharacterBody3D

@onready var anim = $SpiderEnemy/entity_spider/AnimationPlayer
@export var speed: float = 4.0
@export var detection_range: float = 5.0  # How far the spider can "see" the player
@onready var player = get_node("/root/LevelOne/Player")  # Replace with your player path

func _physics_process(delta):
	if not player:
		return

	var direction = player.global_position - global_position
	var distance_to_player = direction.length()

	if distance_to_player <= detection_range:
		# Move towards player
		direction = direction.normalized()
		velocity = direction * speed
		move_and_slide()

		# Play walking animation
		anim.play("SpiderWalkCycle")

		# Rotate to face the player
		if direction.length() > 0.01:
			look_at(global_position + direction, Vector3.UP)
			rotate_y(deg_to_rad(-60))  # rotate 90 degrees around Y to match mesh forward
	else:
		# Idle when player is far
		velocity = Vector3.ZERO
		anim.play("idle")
