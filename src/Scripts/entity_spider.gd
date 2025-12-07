extends Node3D
@onready var animation_tree: AnimationTree = $AnimationTree

func hurt():
	animation_tree.set("parameters/OneShot/request", 1) #to choose the fire property
