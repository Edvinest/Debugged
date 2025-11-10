extends MeshInstance3D


@onready var destination: MeshInstance3D = $"../MeshInstance3D2"
@onready var player: CharacterBody3D = $"../CharacterBody3D"


func _on_area_3d_body_entered(body: Node3D) -> void:
	player.global_position = destination.global_position
