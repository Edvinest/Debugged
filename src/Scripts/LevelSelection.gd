extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_button_level_one_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/LevelOne.tscn")
	

func _on_button_level_two_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/LevelTwo.tscn")
	
	
func _on_button_back_pressed() -> void:
		get_tree().change_scene_to_file("res://src/Scenes/MainMenu.tscn")
