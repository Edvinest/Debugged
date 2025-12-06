extends Node
signal backPressed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_fullscreen_button() # Fullscreen
	var value = db_to_linear(AudioServer.get_bus_volume_db(_bus)) #Volume
	add_resolutions() #Resolutions
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
###########################FULLSCREEN#####################################

@onready var fullscreenButton=get_node("PanelContainer/MarginContainer/VBoxContainer/FullscreenButton")
var mode := DisplayServer.window_get_mode()	
var is_window: bool = mode != DisplayServer.WINDOW_MODE_FULLSCREEN

func _on_fullscreen_button_pressed() -> void:
	
	if is_window:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		is_window = false
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		is_window = true

	_update_fullscreen_button()
	
	
func _update_fullscreen_button() -> void:
	if not is_window:
		fullscreenButton.text="Fullscreen:ON"
	else:
		fullscreenButton.text="Fullscreen:OFF"
		

####################################### VOLUME ######################################### 

func _on_volume_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_bus, linear_to_db(value))
	

func _on_volume_h_slider_mouse_exited() -> void:
	pass # Replace with function body.

func _release_focus() -> void:
	pass # Replace with function body.
	
@export var audio_bus_name := "Master"
@onready var _bus := AudioServer.get_bus_index(audio_bus_name)
	
##################################### RESOLUTION ######################################	

@onready var res_option_button = %ResolutionButton

var RenderScales := {
	"4k": 1.50,
	"2K": 1.25,
	"Full HD": 1.00,
	"HD": 0.75,
	"Potato": 0.50
}


func add_resolutions():
	var saved_scale := load_settings()
	var id := 0
	
	for label in RenderScales.keys():
		res_option_button.add_item(label)
		
		if RenderScales[label] == saved_scale:
			res_option_button.select(id)
		
		id += 1
	
	apply_render_scale(saved_scale)


func apply_render_scale(scale: float) -> void:
	get_tree().root.content_scale_factor = scale


func _on_resolution_button_item_selected(index: int) -> void:
	var label = res_option_button.get_item_text(index)
	var scale = RenderScales[label]
	
	apply_render_scale(scale)
	save_settings(scale)


func save_settings(scale: float) -> void:
	var config := ConfigFile.new()
	config.set_value("Graphics", "render_scale", scale)
	config.save("user://settings.cfg")
	

func load_settings() -> float:
	var config := ConfigFile.new()
	var err := config.load("user://settings.cfg")
	
	if err == OK:
		return config.get_value("Graphics", "render_scale", 1.0)
	
	return 1.0

################################### BACK #############################

func _on_back_button_pressed() -> void:
	emit_signal("backPressed")
