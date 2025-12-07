extends Control

@onready var restart: Button = %RESTART
@onready var death_screen =%DEATH_SCREEN

func _on_restart_pressed() -> void:
	var tree := get_tree()
	var current_scene := tree.current_scene
	
	if current_scene == null:
		print("No current scene")
		return
		
	var left_weapon = $"..".left_weapon
	PlayerData.left_hand_weapon = left_weapon
	
	var right_weapon = $"..".right_weapon
	PlayerData.right_hand_weapon = right_weapon
		
	var packed_scene := current_scene.get_scene_file_path()
	tree.change_scene_to_file(packed_scene)
	tree.paused = false
	death_screen.hide()
