@tool
extends Sprite3D

@onready var progress_bar: ProgressBar = $SubViewport/ProgressBar


func _ready() -> void:
	#progress_bar.value = 50
	#print("MOB: HP_BAR: ", progress_bar)
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.1, 0.1)
	style_bg.corner_radius_top_left = 8
	style_bg.corner_radius_top_right = 8
	style_bg.corner_radius_bottom_left = 8
	style_bg.corner_radius_bottom_right = 8

	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.8, 0.2, 0.2)
	style_fill.corner_radius_top_left = 8
	style_fill.corner_radius_top_right = 8
	style_fill.corner_radius_bottom_left = 8
	style_fill.corner_radius_bottom_right = 8

	progress_bar.add_theme_stylebox_override("background", style_bg)
	progress_bar.add_theme_stylebox_override("fill", style_fill)
