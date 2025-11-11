extends CanvasLayer

@onready var hp_bar: ProgressBar = $Control/ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hp_bar.value = 100
	hp_bar.show_percentage = true
	

var curr = 100
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	curr -= hp_bar.step
	update_hp()
	
func update_hp():
	hp_bar.value = curr
