extends Node

signal backPressed

@onready var left_options = %LeftHandButton
@onready var right_options = %RightHandButton

@onready var Sword : Weapon = preload("res://src/Objects/Weapons/Blade1/Sword1.tres")
@onready var Hammer : Weapon = preload("res://src/Objects/Weapons/Hammer1/Hammer.tres")
@onready var Pesticide : Weapon = preload("res://src/Objects/Weapons/Gun1/Pesticide.tres")

@onready var AvailableWeapons := {
	"SWORD": Sword,
	"HAMMER": Hammer,
	"PESTICIDE": Pesticide
}

func _ready() -> void:
	_setup_option_button(left_options, "LEFT HAND")
	_setup_option_button(right_options, "RIGHT HAND")
	
	_select_random_default(left_options, true)
	_select_random_default(right_options, false)

func _setup_option_button(btn: OptionButton, title: String) -> void:
	btn.clear()
	
	btn.add_item(title)
	btn.set_item_disabled(0, true)
	btn.add_separator()
	
	for weapon_name in AvailableWeapons:
		btn.add_item(weapon_name)
		
		var idx = btn.item_count - 1
		var weapon_resource = AvailableWeapons[weapon_name]
		
		btn.set_item_metadata(idx, weapon_resource)
		
func _select_random_default(btn: OptionButton, is_left_hand: bool) -> void:
	if btn.item_count <= 2:
		return
		
	var random_index = randi_range(2, btn.item_count - 1)
	
	btn.selected = random_index
	
	var weapon_res = btn.get_item_metadata(random_index)
	
	if is_left_hand:
		PlayerData.left_hand_weapon = weapon_res
		print("Auto-selected Left: ", weapon_res)
	else:
		PlayerData.right_hand_weapon = weapon_res
		print("Auto-selected Right: ", weapon_res)

func _on_left_hand_button_item_selected(index: int) -> void:
	var selected_weapon = left_options.get_selected_metadata()
	
	if selected_weapon:
		PlayerData.left_hand_weapon = selected_weapon
	else:
		print("Invalid selection")

func _on_right_hand_button_item_selected(index: int) -> void:
	var selected_weapon = right_options.get_selected_metadata()
	
	if selected_weapon:
		PlayerData.right_hand_weapon = selected_weapon

func _on_button_level_one_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/LevelOne.tscn")

func _on_button_level_two_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/LevelTwo.tscn")

func _on_button_back_pressed() -> void:
	emit_signal("backPressed")
