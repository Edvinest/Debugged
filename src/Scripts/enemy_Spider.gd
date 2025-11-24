extends RigidBody3D

#Instances
var player: CharacterBody3D = null
@onready var animation_player: AnimationPlayer = $entity_spider/AnimationPlayer
@onready var hp_bar: ProgressBar = $HP_bar/SubViewport/ProgressBar
@onready var attack_cooldown: Timer = $Timer

#Constants
const DETECTION_RANGE = 20
const MAX_HEALTH = 100

#Properties
var speed = randf_range(2.0, 4.0)
var health: float
var damage: float = 10
var target = null

func _find_player():
	player = get_tree().get_root().find_child("Player", true, false)
	if player == null:
		push_error("Player not found")
	else:
		print("Enemy: Player found: ", player)
	
func _ready() -> void:
	call_deferred("_find_player")
	health = MAX_HEALTH
	hp_bar.value = MAX_HEALTH

func tracking():
	var direction = global_position.direction_to(player.global_position)
	direction.y = 0.0
	linear_velocity = direction * speed
	rotation.y = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP)
	rotate_y(30)

func _process(delta: float) -> void:
	if health <= 0:
		queue_free()
	hp_bar.value = health
	if target != null and attack_cooldown.is_stopped():
		deal_damage(target)

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= DETECTION_RANGE:
		tracking()
		animation_player.play("SpiderWalkCycle")
	else:
		animation_player.play("SpiderIdle")
		
func take_damage(damage_to_take):
	health -= damage_to_take
	print(health)
	

func deal_damage(body):
	attack_cooldown.start()
	if body.has_method("take_damage"):
		body.take_damage(damage)

func _on_hitbox_body_entered(body: Node3D) -> void:
	target = body
	

func _on_hitbox_body_exited(body: Node3D) -> void:
	target = null
