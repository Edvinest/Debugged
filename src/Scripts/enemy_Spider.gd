extends CharacterBody3D

@onready var animation: AnimationPlayer = $"entity_spider/AnimationPlayer"
@onready var player: CharacterBody3D = $"../Player"

const DETECTION_DISTANCE = 10.0
const SPEED = 2.0

func _ready() -> void:
	animation.play("SpiderIdle")
	

func _physics_process(_delta: float) -> void:
	var distance = global_position.distance_to(player.global_position)
	
	if distance < DETECTION_DISTANCE:
		var target = player.global_position
		target.y = global_position.y
		look_at(target, Vector3.UP)
		rotate_y(30)
		if animation.current_animation != "SpiderWalkCycle":
			animation.play("SpiderWalkCycle")
		
		#Normalizing -> making it's length equal to 1, while keeping its direction the same.
		#The spider will move faster the farther the player is (since the vector gets longer).
		#The unit vector (1, 0, 0) -> it points where to go, not how far
		var direction = (target - global_position).normalized()
		#So this means the spider will always move at the same speed, no matter how far away the player is.
		velocity = direction * SPEED
		
		move_and_slide()
	else:
		
		velocity = Vector3.ZERO
		move_and_slide()
		
		if animation.current_animation != "SpiderIdle":
			animation.play("SpiderIdle")
