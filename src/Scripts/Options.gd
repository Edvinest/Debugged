extends Node

signal backPressed

# --- NODES ---
@onready var fullscreen_button = $PanelContainer/MarginContainer/VBoxContainer/FullscreenButton
@onready var res_option_button = %ResolutionButton
@onready var volume_slider = %VolumeHSlider

# --- AUDIO ---
@export var audio_bus_name := "Master"
@onready var _bus := AudioServer.get_bus_index(audio_bus_name)

# --- RESOLUTION SETTINGS ---
var RenderScales := {
	"Full HD (1.5x)": 1.50,
	"HD (1.0x)": 1.00,
	"SD (0.75x)": 0.75,
	"Potato (0.50x)": 0.50
}

func _ready() -> void:
	add_resolutions() 
	_update_fullscreen_button_text()

	
	var current_db = AudioServer.get_bus_volume_db(_bus)
	var current_linear = db_to_linear(current_db)
	
	if volume_slider:
		volume_slider.value = current_linear


########################### FULLSCREEN #####################################

func _on_fullscreen_button_pressed() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_window: bool = mode != DisplayServer.WINDOW_MODE_FULLSCREEN
	
	if is_window:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	_update_fullscreen_button_text()

func _update_fullscreen_button_text() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen = mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	if is_fullscreen:
		fullscreen_button.text = "Fullscreen: ON"
	else:
		fullscreen_button.text = "Fullscreen: OFF"


####################################### VOLUME ######################################### 

func _on_volume_h_slider_value_changed(value: float) -> void:
	# Linear (0 to 1) converted to Decibels (-80 to 0)
	AudioServer.set_bus_volume_db(_bus, linear_to_db(value))


##################################### RESOLUTION ###################################### 

func add_resolutions():
	var saved_scale := load_settings()
	var id := 0
	
	res_option_button.clear()
	
	for label in RenderScales.keys():
		res_option_button.add_item(label)
		
		if is_equal_approx(RenderScales[label], saved_scale):
			res_option_button.select(id)
		
		id += 1
	
	apply_render_scale(saved_scale)

func apply_render_scale(scale: float) -> void:
	get_viewport().scaling_3d_scale = scale

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
