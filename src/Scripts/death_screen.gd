extends CanvasLayer

@onready var restart: Button = $Control/RESTART


func _on_restart_pressed() -> void:
	var tree := get_tree()
	var current_scene := tree.current_scene
	
	if current_scene == null:
		print("No current scene")
		return
		
	var packed_scene := current_scene.get_scene_file_path()
	
	tree.change_scene_to_file(packed_scene)
