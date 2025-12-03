extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var Highscore={}
var Leaderboard={}
var Achievemnts={}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/MainMenu.tscn") # Replace with function body.


func _on_leaderboard_button_pressed() -> void:
	pass # Replace with function body.


func _on_highscore_button_pressed() -> void:
	pass # Replace with function body.


func _on_achievements_button_pressed() -> void:
	pass # Replace with function body.
