extends Control
@onready var popUp= %PauseWindow
@onready var pb_up=%ButtonPanelContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_p_mode(param:bool)->void:
		if param==true:
			pb_up.hide()
		if param==false:
			pb_up.show()
		
func pause() -> void:
	get_tree().paused=true
	popUp.show()
  
func resume() -> void:
	get_tree().paused=false
	popUp.hide()

func _process(delta: float)-> void:
	if Input.is_action_just_pressed("paused") and get_tree().paused==false:
		pause()
		
	elif Input.is_action_just_pressed("paused") and get_tree().paused==true:
		resume()
		


func _on_quit_to_mm_button_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://src/Scenes/Menu.tscn")


func _on_continue_button_pressed() -> void:
	resume()


func _on_pause_button_pressed() -> void:
	pause()
