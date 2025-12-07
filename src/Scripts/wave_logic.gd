class_name WaveLogic
extends Node2D

@export var debug_score:= 0.0

@onready var INSUFICIENT_SCORE: CanvasLayer = %WarningInsuficientScore
@onready var continue_btn: Button = %Continue_btn
@onready var wave_timer: Timer = %Timer
@onready var warning_timer: Timer = %WarningTimer
@onready var label_timer: Label = %show_timer
@onready var label_score: Label = %show_score
@onready var upgrade_element: CanvasLayer = %UPGRADE_element

var wave_counter: int = 1
var score := 0.0

@export var time_between_waves: float = 2.0

func _ready() -> void:
	score = debug_score
	upgrade_element.hide()
	INSUFICIENT_SCORE.hide()

	warning_timer.start()

	wave_timer.wait_time = time_between_waves
	wave_timer.start()
	label_timer.text = "Next Wave In: " + str(time_between_waves)

func _process(delta: float) -> void:

	label_score.text = "Score: " + str(score)

	continue_btn.text = "Continue to wave " + str(wave_counter)

	if wave_timer.time_left > 0:
		label_timer.text = "Next Wave In:" + str(int(ceil(wave_timer.time_left)))
	else:
		label_timer.text = "Wave Incoming!"


func _on_timer_timeout() -> void:
	upgrade_element.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

func _on_button_pressed() -> void:
	upgrade_element.hide()
	wave_timer.start()
	wave_counter += 1

func _on_spawner_enemy_defeated(points: float) -> void:
	score += points
	print("Enemy killed: Score: ", score)



func _on_weapon_upgrades_weapon_upgrade_purchased(cost: float, upgrade: BaseWeaponStrategy, weapon: Weapon) -> void:
	if score >= cost:
		score -= cost
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
