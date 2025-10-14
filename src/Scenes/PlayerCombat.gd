extends Node

@export var left_weapon : Weapon
@export var right_weapon : Weapon

@onready var right_hand = $PlayerBody/RightHand

var using_first_person : bool = true

func _process(delta: float) -> void:
	if using_first_person:
		#_detect_imu_attacks()
		pass
	else:
		_detect_input_attacks()
		
func _detect_input_attacks():
	if Input.is_action_just_pressed("attack_left"):
		trigger_attack("L", "slash")
	if Input.is_action_just_pressed("attack_right"):
		trigger_attack("R", "slash")
		
func trigger_attack(hand : String, attack_type : String) -> void:
	pass
