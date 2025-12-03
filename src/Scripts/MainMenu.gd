extends Node
@onready var popUp= %Window

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_options_button_pressed() -> void:
	print("stuff happens")
	get_tree().change_scene_to_file("res://src/Scenes/Options.tscn")


func _on_start_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/LevelSelection.tscn")

func _on_exit_button_pressed() -> void:
	popUp.show()

func _on_yes_button_pressed() -> void:
	get_tree().quit() 
	
	
func _on_no_button_pressed() -> void:
	popUp.hide()


func _on_profile_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/Profile.tscn")
