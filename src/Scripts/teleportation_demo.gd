extends MeshInstance3D

@export var pad_id: int
@export var target_id: int

var destination : MeshInstance3D
@onready var player: CharacterBody3D = $"../../Player"

@onready var timer: Timer = Timer.new()
const DEF_COOLDOWN := 2.0

var can_teleport := true

var label = Label3D.new()

func init_label():
	add_child(label)
	label.pixel_size = 0.02
	label.offset = Vector2(0, 50)
	label.text = "Ready"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func init_timer():
	add_child(timer)
	timer.wait_time = DEF_COOLDOWN
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	
func _ready() -> void:
	init_label()
	init_timer()
	
	for node in get_tree().get_nodes_in_group("teleport_pads"):
		if node is MeshInstance3D and node.pad_id == target_id:
			destination = node
			break

func _process(_delta: float) -> void:
	label.text = "Ready" if can_teleport else str("%.1f" % timer.time_left)

func _on_area_3d_body_entered(_body: Node3D) -> void:
	if can_teleport:
		player.global_position = destination.global_position
		can_teleport = false
		destination.can_teleport = false
	
	#Wait
	if timer.is_stopped():
		timer.start()
		if destination.timer:
			destination.timer.start()


func _on_timer_timeout() -> void:
	can_teleport = true
	if destination:
		destination.can_teleport = true
