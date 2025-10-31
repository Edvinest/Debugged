extends Node3D

@export var weapon_data : Weapon
@onready var model_holder : Node3D = $ModelHolder

func _ready():
	if weapon_data.mesh:
		_load_model(weapon_data.mesh)
	else:
		push_warning("No weapon")

func _load_model(scene: PackedScene):
	for c in model_holder.get_children():
		c.queue_free()
		
	var instance = scene.instantiate()
	model_holder.add_child(instance)

	instance.transform = Transform3D.IDENTITY
