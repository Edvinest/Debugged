extends Node
signal backPressed

@onready var left_options = %LeftHandButton
@onready var right_options = %RightHandButton
@onready var Weapons : Array[String] = ["Sword","Hammer","Pesticide"]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%LeftHandButton.add_item("LEFT HAND") # ez lesz a cím
	%LeftHandButton.add_separator()

	for name in LeftHandOptions.keys():
		%LeftHandButton.add_item(name)

	# RIGHT HAND BUTTON
	%RightHandButton.add_item("RIGHT HAND")
	%RightHandButton.add_separator()

	for name in RightHandOptions.keys():
		%RightHandButton.add_item(name)

	
var LeftHandOptions := {
	"SWORD": "res://src/Objects/Weapons/Blade1/Sword1.tres",
	"HAMMER": "res://src/Objects/Weapons/Hammer1/Hammer.tres",
	"PESTICIDE": "res://src/Objects/Weapons/Gun1/Pesticide.tres"
}

var RightHandOptions := {
	"SWORD": "res://src/Objects/Weapons/Blade1/Sword1.tres",
	"HAMMER": "res://src/Objects/Weapons/Hammer1/Hammer.tres",
	"PESTICIDE": "res://src/Objects/Weapons/Gun1/Pesticide.tres"
}
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_button_level_one_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/LevelOne.tscn")
	

func _on_button_level_two_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/LevelTwo.tscn")
	
	
func _on_button_back_pressed() -> void:
	emit_signal("backPressed")

###########   WEAPON SELECTION ##########
func _on_left_hand_button_item_selected(index: int) -> void:
	if index <= 1:
		var chosen_path = LeftHandOptions[2]
		
	var key = LeftHandOptions.keys()[index - 2]
	var chosen_path = LeftHandOptions[key]
	print("Bal kéz választva:", chosen_path)# Replace with function body.
	PlayerData.left_hand_weapon = LeftHandOptions[key]


func _on_right_hand_button_item_selected(index: int) -> void:
	if index <= 1:
		var chosen_path = RightHandOptions[2]

	var key = RightHandOptions.keys()[index - 2]
	var chosen_path = RightHandOptions[key]
	print("Jobb kéz választva:", chosen_path)
	PlayerData.right_hand_weapon = RightHandOptions[key]
