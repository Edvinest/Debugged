extends RigidBody3D

#Instances
var player: CharacterBody3D = null
@onready var animation_player: AnimationPlayer = $entity_spider/AnimationPlayer
@onready var hp_bar: ProgressBar = $HP_bar/SubViewport/ProgressBar
@onready var attack_cooldown: Timer = $Timer

#Constants
const DETECTION_RANGE = 10.0
const MAX_HEALTH = 100
const CRITICAL_HP = 20
const NORMAL_SPEED = 3.0
const RETREAT_SPEED = 5.0
const MAX_DODGE = 1.0
const DODGE_RANGE = 10.0

#Properties
var speed = NORMAL_SPEED
var health = MAX_HEALTH
var damage: float = 10
var target = null
var dodge_count = MAX_DODGE

#State machine
enum State {IDLE, TRACKING, ATTACKING, DODGE}
var state = State.IDLE

func _find_player():
	player = get_tree().get_root().find_child("Player", true, false)
	if player == null:
		push_error("Player not found")
	else:
		print("Enemy: Player found: ", player)
	
func _ready() -> void:
	call_deferred("_find_player")
	hp_bar.value = MAX_HEALTH

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if health <= 0:
		queue_free()
		return
	elif health <= CRITICAL_HP:
		state = State.DODGE
	elif distance <= DETECTION_RANGE:
		state = State.TRACKING
	elif target != null:
		state = State.ATTACKING
	else:
		state = State.IDLE
	
	match state:
		State.IDLE:
			linear_velocity = Vector3.ZERO
			animation_player.play("SpiderIdle")
		State.TRACKING:
			_tracking(player.global_position, NORMAL_SPEED)
			animation_player.play("SpiderWalkCycle")
		State.ATTACKING:
			deal_damage(target)
		State.DODGE:
			_dodge(player.global_position, RETREAT_SPEED)
			animation_player.play("SpiderWalkCycle")
	
	hp_bar.value = health
	
func _tracking(target_pos: Vector3, move_speed: float):
	var direction = global_position.direction_to(target_pos)
	direction.y = 0.0
	linear_velocity = direction * move_speed
	rotation.y = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP)
	rotate_y(30)
	
func _dodge(target_pos: Vector3, move_speed: float):
	
	if dodge_count <= 0:
		return
	
	dodge_count -= 1.0
	
	var direction = (global_position - target_pos).normalized()
	direction.y = 0.0
	
	var dodge_target = global_position + direction * DODGE_RANGE
	linear_velocity  = (dodge_target - global_position).normalized() * move_speed
	rotation.y = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP)
	rotate_y(30)

func take_damage(damage_to_take):
	health -= damage_to_take
	print("Enemy HP:", health)
	

func deal_damage(body):
	if attack_cooldown.is_stopped():
		attack_cooldown.start()
		if body.has_method("take_damage"):
			body.take_damage(damage)

func _on_hitbox_body_entered(body: Node3D) -> void:
	target = body
	

func _on_hitbox_body_exited(body: Node3D) -> void:
	target = null
