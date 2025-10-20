extends Node

@export var left_weapon : Weapon
@export var right_weapon : Weapon

@onready var right_hand = $PlayerBody/RightHand
@onready var left_hand = $PlayerBody/LeftHand

var using_first_person : bool = true
var attack_cooldown_left : float = 0.0
var attack_cooldown_right : float = 0.0

func _process(delta: float) -> void:
	if attack_cooldown_left > 0:
		attack_cooldown_left -= delta
	if attack_cooldown_right > 0:
		attack_cooldown_right -= delta
		
	if using_first_person:
		# TODO: implement IMU-based attacks
		pass
	else:
		_detect_input_attacks()

func _detect_input_attacks():
	if Input.is_action_just_pressed("attack_left"):
		_perform_attack(left_weapon, left_hand, "L")
	if Input.is_action_just_pressed("attack_right"):
		_perform_attack(right_weapon, right_hand, "R")

func _perform_attack(weapon: Weapon, hand: Node3D, hand_side: String):
	if weapon == null:
		return

	match weapon.weapon_type:
		"blade":
			_attack_slash(weapon, hand)
		"hammer":
			_attack_slam(weapon, hand)
		"gun":
			_attack_shoot(weapon, hand)

func _attack_slash(weapon: Weapon, hand: Node3D):
	# TODO: Implement it later
	pass

func _attack_slam(weapon: Weapon, hand: Node3D):
	# TODO: Implement it later
	pass

func _attack_shoot(weapon: Weapon, hand: Node3D):
	# TODO: Implement it later
	pass
