class_name PlayerSpawnPoint
extends Node3D

var spawn_points: Array = []

signal on_spawn_point_selected(point: Marker3D)

func choose_spawn_point():
	spawn_points.clear()
	spawn_points = self.get_children()

	for i in range(spawn_points.size() - 1, -1, -1):
		if not (spawn_points[i] is Marker3D):
			spawn_points.pop_at(i)

	if spawn_points.is_empty():
		push_error("No valid spawn points!")
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var rand := rng.randi_range(0, spawn_points.size() - 1)

	if is_instance_valid(spawn_points[rand]):
		on_spawn_point_selected.emit(spawn_points[rand])
	else:
		push_error("Chosen spawn point is not valid")

func _ready() -> void:
	choose_spawn_point()
