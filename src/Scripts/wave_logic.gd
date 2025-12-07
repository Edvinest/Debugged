class_name WaveLogic
extends Node2D

@export var debug_score:= 0.0
@export var incr_dif := 0.0

@onready var INSUFICIENT_SCORE: CanvasLayer = %WarningInsuficientScore
@onready var continue_btn: Button = %Continue_btn
@onready var wave_timer: Timer = %Timer
@onready var warning_timer: Timer = %WarningTimer
@onready var label_timer: Label = %show_timer
@onready var label_score: Label = %show_score
@onready var upgrade_element: CanvasLayer = %UPGRADE_element
@onready var player: Player =  null

var wave_counter: int = 1
var score := 0.0

@export var time_between_waves: float = 2.0

func _find_player():
	player = get_tree().get_root().find_child("Player", true, false)
	if player == null:
		push_error("WaveManager: Player not found")
	else:
		print("WaveManager: Player found: ", player)
		start_wave()

func _ready() -> void:
	call_deferred("_find_player")

	score = debug_score
	upgrade_element.hide()
	INSUFICIENT_SCORE.hide()

	warning_timer.start()

	wave_timer.wait_time = time_between_waves
	wave_timer.start()
	label_timer.text = "Next Wave In: " + str(time_between_waves)

func _process(_delta: float) -> void:

	label_score.text = "Score: " + str(score)

	continue_btn.text = "Continue to wave " + str(wave_counter)

	if wave_timer.time_left > 0:
		label_timer.text = "Next Wave In:" + str(int(ceil(wave_timer.time_left)))
	else:
		label_timer.text = "Wave Incoming!"

func _find_spawners():
	var spawners: Array = []
	for child in self.get_children():
		if child.is_in_group("spawner"):
			if wave_counter <= 3 and child.GRADE > 0:
				continue
			spawners.append(child)

	if spawners.is_empty():
		push_error("Wave manager: No spawners found")
		return

	return spawners

#End wave
func _on_timer_timeout() -> void:
	upgrade_element.show()
	player.pause_fl = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var spawners = _find_spawners()
	for sp in spawners:
		sp.curr_spawns = 0
		var temp = sp.get_children()
		for i in temp:
			if i.is_in_group("enemy"):
				i.queue_free()
	
#Start wave
func _on_button_pressed() -> void:
	upgrade_element.hide()
	start_wave()

func start_wave():
	wave_timer.start()
	player.pause_fl = false
	player.reset_health()
	wave_counter += 1
	get_tree().paused = false

	init_wave_properties()

func init_wave_properties():

	time_between_waves += time_between_waves * incr_dif / 100
	wave_timer.wait_time = time_between_waves

	var spawners = _find_spawners()

	for sp in spawners:
		print("Wave manager: Spawner found: ", sp)
		sp.max_spawns += sp.max_spawns * incr_dif / 100
		sp.spawning_intervals_sec -= sp.spawning_intervals_sec * incr_dif / 100
		sp.spawn_fl = true

	if wave_counter % 5 == 0:
		incr_dif += 1


func _on_spawner_enemy_defeated(points: float) -> void:
	PlayerData.highscore += points
	print("Enemy killed: Score: ", score)



func _on_weapon_upgrades_weapon_upgrade_purchased(cost: float, upgrade: BaseWeaponStrategy, weapon: Weapon) -> void:
	if PlayerData.highscore >= cost:
		PlayerData.highscore -= cost
		if upgrade.has_method("apply_upgrade"):
			upgrade.apply_upgrade(weapon)
	else:
		INSUFICIENT_SCORE.show()
		warning_timer.start()


func _on_player_upgrades_player_upgrade_purchased(cost: float, upgrade: BasePlayerStrategy) -> void:
	if score >= cost:
		score -= cost
		if upgrade.has_method("apply_upgrade"):
			upgrade.apply_upgrade()
	else:
		INSUFICIENT_SCORE.show()
		warning_timer.start()


func _on_warning_timer_timeout() -> void:
	INSUFICIENT_SCORE.hide()


func _on_player_player_died() -> void:
	wave_timer.stop()
	set_process(false)
