extends Control


func _on_login_screen_successful_login() -> void:
	$LoginScreen.queue_free()
	$MainMenu.show()


func _on_main_menu_options_pressed() -> void:
	$MainMenu.hide()
	$Options.show()


func _on_main_menu_profile_pressed() -> void:
	$MainMenu.hide()
	$Profile.show()

func _on_main_menu_start_game_pressed() -> void:
	$MainMenu.hide()
	$LevelSelection.show()


func _on_options_back_pressed() -> void:
	$Options.hide()
	$MainMenu.show()


func _on_level_selection_back_pressed() -> void:
	$LevelSelection.hide()
	$MainMenu.show()

func _on_profile_back_pressed() -> void:
	$Profile.hide()
	$MainMenu.show()
