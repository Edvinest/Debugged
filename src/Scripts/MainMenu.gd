extends Node
@onready var popUp= %Window
@onready var popUpInf=%InformationsWindow

signal optionsPressed
signal startGamePressed
signal profilePressed

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_options_button_pressed() -> void:
		emit_signal("optionsPressed")

func _on_start_game_button_pressed() -> void:
	emit_signal("startGamePressed")
	
func _on_exit_button_pressed() -> void:
	popUp.show()

func _on_yes_button_pressed() -> void:
	get_tree().quit() 
	
	
func _on_no_button_pressed() -> void:
	popUp.hide()

func _on_log_out_button_pressed() -> void:
	popUp.hide()
	Firebase.Auth.logout()
	get_tree().change_scene_to_file("res://src/Scenes/Menu.tscn")
	
func _on_profile_button_pressed() -> void:
	emit_signal("profilePressed")

func _on_info_button_pressed() -> void:
	popUpInf.show()


func _on_inf_back_button_pressed() -> void:
	popUpInf.hide()
