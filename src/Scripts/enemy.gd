class_name Enemy
extends RigidBody3D

# Signal for spawner to track kills
signal died(points)

# State machine
enum State {IDLE, TRACKING, ATTACKING, DODGE}
var state = State.IDLE

# References
var player: CharacterBody3D = null
var target = null

# Health system
var health: float
var max_health: float

# Movement parameters
var detection_range: float = 10.0
var normal_speed: float = 3.0
var retreat_speed: float = 5.0
var damage: float = 10.0
var points: int = 10

# Dodge system
var critical_hp: float = 20.0
var flag_dodge: int = 1  # 1 = dodge available, 0 = already used
var is_dodging: bool = false
var dodge_duration: float = 0.7

# Node references (to be set by child classes)
var animation_player: AnimationPlayer
var hp_bar: ProgressBar
var attack_cooldown: Timer
var dodge_timer: Timer
var entity_model: Node3D

func _ready() -> void:
	call_deferred("_find_player")
	if hp_bar and max_health > 0:
		hp_bar.value = max_health
		hp_bar.max_value = max_health
	health = max_health

func _find_player() -> void:
	player = get_tree().get_root().find_child("Player", true, false)
	if player == null:
		push_error("Player not found")
	else:
		print("Enemy: Player found: ", player)

func _physics_process(_delta: float) -> void:
	if player == null:
		return

	var distance = global_position.distance_to(player.global_position)

	if health <= 0:
		died.emit(points)
		queue_free()
		return

	# --- State selection ---
	if is_dodging:
		state = State.DODGE
	elif target != null and health <= critical_hp and flag_dodge == 1:
		is_dodging = true
		flag_dodge = 0
		dodge_timer.start(dodge_duration)
		state = State.DODGE
	elif target != null:
		state = State.ATTACKING
	elif distance <= detection_range:
		state = State.TRACKING
	else:
		state = State.IDLE

	# --- State actions ---
	match state:
		State.IDLE:
			linear_velocity = Vector3.ZERO
			_play_animation("idle")

		State.TRACKING:
			_tracking(player.global_position, normal_speed)
			_play_animation("walk")

		State.ATTACKING:
			deal_damage(target)

		State.DODGE:
			_dodge(player.global_position, retreat_speed)
			_play_animation("walk")

	if hp_bar:
		hp_bar.value = health

func _tracking(target_pos: Vector3, move_speed: float) -> void:
	var direction = global_position.direction_to(target_pos)
	direction.y = 0.0
	linear_velocity = direction * move_speed
	rotation.y = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP)

func _dodge(target_pos: Vector3, move_speed: float) -> void:
	var direction = (global_position - target_pos).normalized()
	direction.y = 0.0
	linear_velocity = direction * move_speed

func take_damage(damage_to_take: float) -> void:
	health -= damage_to_take
	if hp_bar:
		hp_bar.value = health
	if entity_model and entity_model.has_method("hurt"):
		entity_model.hurt()
	print("Enemy HP:", health)

func deal_damage(body: Node3D) -> void:
	if attack_cooldown.is_stopped():
		attack_cooldown.start()
		if body.has_method("take_damage"):
			body.take_damage(damage)

func _play_animation(anim_name: String) -> void:
	if animation_player:
		animation_player.play(anim_name)

func _on_hitbox_body_entered(body: Node3D) -> void:
	target = body

func _on_hitbox_body_exited(_body: Node3D) -> void:
	target = null

func _on_dodge_timer_timeout() -> void:
	is_dodging = false
	linear_velocity = Vector3.ZERO
