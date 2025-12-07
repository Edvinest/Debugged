class_name Spawner
extends Node3D

signal enemy_defeated(points: float)

@onready var marker_3d: Marker3D = %Marker3D
@onready var timer: Timer = %Timer

@export var mob_to_spawn: PackedScene
@export var max_spawns = 1
@export var spawning_intervals_sec = 1.0
var curr_spawns = 0
var spawn_area_clear = true

func _ready() -> void:
	timer.wait_time = spawning_intervals_sec

func _on_timer_timeout() -> void:
	if curr_spawns < max_spawns and spawn_area_clear:
		curr_spawns += 1
		spawn_area_clear = false
		var new_mob = mob_to_spawn.instantiate()
		add_child(new_mob)
		new_mob.global_position = marker_3d.global_position
		new_mob.died.connect(_on_enemy_died)


func _on_enemy_died(point) -> void:
	curr_spawns -= 1
	enemy_defeated.emit(point)



func _on_area_3d_body_exited(body: Node3D) -> void:
	spawn_area_clear = true
