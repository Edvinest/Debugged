extends Node2D

@onready var continue_btn: Button = %Continue_btn
@onready var wave_timer: Timer = %Timer
@onready var label_timer: Label = %show_timer
@onready var upgrade_element: CanvasLayer = %UPGRADE_element

var wave_counter: int = 2

@export var time_between_waves: float = 2.0

func _ready() -> void:
	upgrade_element.hide()

	wave_timer.wait_time = time_between_waves
	wave_timer.start()
	label_timer.text = "Next Wave In: " + str(time_between_waves)

func _process(delta: float) -> void:
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
	wave_counter += 1
