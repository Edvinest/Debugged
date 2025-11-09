extends Node

var udp := PacketPeerUDP.new()

var targetRotL := Vector3()
var smoothRotL := Vector3()

var targetRotR := Vector3()
var smoothRotR := Vector3()

@export var left_weapon : Weapon
@export var right_weapon : Weapon

@onready var right_hand = $RightHand
@onready var left_hand = $LeftHand
@onready var AnimPlayer = $"../../AnimationPlayer"

var using_first_person : bool = true
var attack_cooldown_left : float = 0.0
var attack_cooldown_right : float = 0.0

func _ready():
	if right_hand.has_node("WeaponInstance"):
		right_hand.get_node("WeaponInstance").set_weapon_data(right_weapon)
		
	if left_hand.has_node("WeaponInstance"):
		left_hand.get_node("WeaponInstance").set_weapon_data(left_weapon)
		
	udp.bind(4243, "127.0.0.1")
	
	if Input.get_connected_joypads().is_empty():
		using_first_person = false

func _process(delta: float) -> void:
	_handle_joycon()
	
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
		if left_hand.has_node("WeaponInstance"):
			left_hand.get_node("WeaponInstance").start_attack(using_first_person, "left", )
			
	if Input.is_action_just_pressed("attack_right"):
		if right_hand.has_node("WeaponInstance"):
			right_hand.get_node("WeaponInstance").start_attack(using_first_person, "right")
	
		
func _handle_joycon():
	while udp.get_available_packet_count() > 0:
		var packet = udp.get_packet().get_string_from_utf8().strip_edges()
		print("Got packet:", packet)

		# Expect "L:roll,pitch" or "R:roll,pitch"
		var side_and_vals = packet.split(":")
		if side_and_vals.size() == 2:
			var side = side_and_vals[0]
			var vals = side_and_vals[1].split(",")
			if vals.size() == 2:
				var roll = float(vals[0])
				var pitch = float(vals[1])

				if side == "L":
					targetRotL.x = pitch
					targetRotL.z = roll
				elif side == "R":
					targetRotR.x = pitch
					targetRotR.z = roll

	if using_first_person:
		# Smooth interpolation
		smoothRotL = smoothRotL.lerp(-targetRotL, 0.1)
		smoothRotR = smoothRotR.lerp(-targetRotR, 0.1)

		# Apply to hands
		left_hand.rotation = smoothRotL
		right_hand.rotation = smoothRotR
		
	else:
		pass


func _on_weapon_instance_request_animation(anim_name: String) -> void:
	if AnimPlayer.has_animation(anim_name):
		AnimPlayer.play(anim_name)
		AnimPlayer.queue("RESET")
	else:
		print("Animation not found:", anim_name)
