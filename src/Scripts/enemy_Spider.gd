extends RigidBody3D

#For spawner to know how many are 
signal died(points)

# Instances
var player: CharacterBody3D = null
@onready var animation_player: AnimationPlayer = $entity_spider/AnimationPlayer
@onready var animation_tree: AnimationTree = $entity_spider/AnimationTree
@onready var hp_bar: ProgressBar = $HP_bar/SubViewport/ProgressBar
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var dodge_timer: Timer = $DodgeTimer
@onready var entity_spider: Node3D = $entity_spider


# Constants
const DETECTION_RANGE = 10.0
const MAX_HEALTH = 50
const CRITICAL_HP = 20
const NORMAL_SPEED = 3.0
const RETREAT_SPEED = 5.0
const DODGE_DURATION = .7  # Duration of retreat in seconds
#Point to give player upon killing it.
const POINT = 10

# Properties
var health = MAX_HEALTH
var damage: float = 10
var target = null

# Dodge control
var flag_dodge = 1      # 1 = dodge available, 0 = already used
var is_dodging = false  # locks DODGE state during timer

# State machine
enum State {IDLE, TRACKING, ATTACKING, DODGE}
var state = State.IDLE

func _ready() -> void:
	call_deferred("_find_player")
	hp_bar.value = MAX_HEALTH
	hp_bar.max_value = MAX_HEALTH

func _find_player():
	player = get_tree().get_root().find_child("Player", true, false)
	if player == null:
		push_error("Player not found")
	else:
		print("Enemy: Player found: ", player)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var distance = global_position.distance_to(player.global_position)

	if health <= 0:
		died.emit(POINT)
		queue_free()
		return

	# --- State selection ---
	if is_dodging:
		state = State.DODGE
	elif target != null and health <= CRITICAL_HP and flag_dodge == 1:
		is_dodging = true
		flag_dodge = 0
		dodge_timer.start(DODGE_DURATION)
		state = State.DODGE
	elif target != null:
		state = State.ATTACKING
	elif distance <= DETECTION_RANGE:
		state = State.TRACKING
	else:
		state = State.IDLE

	# --- State actions ---
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

func _dodge(target_pos: Vector3, move_speed: float):
	var direction = (global_position - target_pos).normalized()
	direction.y = 0.0
	linear_velocity = direction * move_speed


func take_damage(damage_to_take):
	health -= damage_to_take
	hp_bar.value = health
	entity_spider.hurt()
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

# --- Dodge timer callback ---
func _on_dodge_timer_timeout() -> void:
	# Unlock DODGE state after timer ends
	is_dodging = false
	linear_velocity = Vector3.ZERO
