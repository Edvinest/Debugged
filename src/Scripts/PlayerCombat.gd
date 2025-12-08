extends Node

var udp := PacketPeerUDP.new()

var targetRotL := Vector3()
var smoothRotL := Vector3()
var recentPacketsL : Array = []
var filteredRotL := Vector3()
var prevRotL : Vector3 = Vector3.ZERO
var swing_freeze_L : float = 0.0

var targetRotR := Vector3()
var smoothRotR := Vector3()
var recentPacketsR : Array = []
var filteredRotR := Vector3()
var prevRotR : Vector3 = Vector3.ZERO
var swing_freeze_R : float = 0.0

var fp_anim_time : float = 0.0

const SWING_THRESHOLD : float = 1.2
const FREEZE_TIME : float = 0.18
const PACKET_HISTORY_SIZE = 8

var left_weapon : Weapon = null
var right_weapon : Weapon = null

@onready var fp_right_hand = $FirstPersonModel/Hands/RightHand
@onready var tp_right_hand = $ThirdPersonModel/Player/Skeleton3D/RightHand
@onready var fp_left_hand = $FirstPersonModel/Hands/LeftHand
@onready var tp_left_hand = $ThirdPersonModel/Player/Skeleton3D/LeftHand

const SHOULDER_OFFSET_R = Vector3(-0.25, -0.25, -0.3)
const SHOULDER_OFFSET_L = Vector3(0.25, -0.25, -0.3)

var ARM_LENGTH = 0.0        # How far out the hand is
var ROTATION_SPEED = 15    # Sensitivity Multiplier
var SWAY_INTENSITY = 0.1   # How much the sword "lags" (Visual Weight)
var SMOOTHING = 15.0        # Higher = Snappier, Lower = Smoother/Laggier

var target_rot_L := Vector3.ZERO # Accumulated Euler Angles (Pitch, Yaw, Roll)
var target_rot_R := Vector3.ZERO

var sway_target_L := Vector3.ZERO
var sway_target_R := Vector3.ZERO

var current_sway_L := Vector3.ZERO
var current_sway_R := Vector3.ZERO

var using_first_person : bool = true

func _ready():
	udp.bind(4243, "127.0.0.1")
	

func set_first_person(fp : bool) -> void:
	using_first_person = fp
	
func set_weapons(left : Weapon, right: Weapon):
	left_weapon = left
	right_weapon = right
	
	if fp_right_hand.has_node("RightWeapon"):
		fp_right_hand.get_node("RightWeapon").set_weapon_data(right_weapon)
		
	if fp_left_hand.has_node("LeftWeapon"):
		fp_left_hand.get_node("LeftWeapon").set_weapon_data(left_weapon)
		
	if tp_right_hand.has_node("RightWeapon"):
		tp_right_hand.get_node("RightWeapon").set_weapon_data(right_weapon)
		
	if tp_left_hand.has_node("LeftWeapon"):
		tp_left_hand.get_node("LeftWeapon").set_weapon_data(left_weapon)

func _process(delta: float) -> void:
	_handle_joycon(delta)
	
	if using_first_person:
		pass
		#if fp_right_hand:
			#current_sway_R = current_sway_R.lerp(sway_target_R, 5.0 * delta)
			#_apply_arm_model(fp_right_hand, target_rot_R, current_sway_R, SHOULDER_OFFSET_R, delta)
			#
		#if fp_left_hand:
			#current_sway_L = current_sway_L.lerp(sway_target_L, 5.0 * delta)
			#_apply_arm_model(fp_left_hand, target_rot_L, current_sway_L, SHOULDER_OFFSET_L, delta)
	else:
		_detect_input_attacks()
		
	if Input.is_action_just_pressed("recenter_hands"):
		targetRotL = Vector3.ZERO
		targetRotR = Vector3.ZERO

func _detect_input_attacks():
	if Input.is_action_just_pressed("attack_left"):
		if tp_left_hand.has_node("LeftWeapon"):
			tp_left_hand.get_node("LeftWeapon")._perform_standard_attack()
			
	if Input.is_action_just_pressed("attack_right"):
		if tp_right_hand.has_node("RightWeapon"):
			tp_right_hand.get_node("RightWeapon")._perform_standard_attack()

func _apply_arm_model(hand_node: Node3D, rot_euler: Vector3, cur_sway: Vector3, shoulder_offset: Vector3, delta: float):
	# A. ROTATION
	# Convert our accumulated Euler angles (X, Y, Z) into a Quaternion for the node
	var target_quat = Quaternion.from_euler(Vector3(rot_euler.x, rot_euler.y, rot_euler.z))
	hand_node.quaternion = hand_node.quaternion.slerp(target_quat, SMOOTHING * delta)
	
	# B. POSITION (Forward Kinematics)
	# Find where the "Hand" is based on rotation
	# We take the Hand's Basis Z vector (Forward) and project it out by ARM_LENGTH
	var forward_dir = hand_node.transform.basis.z 
	# Note: Depending on your model export, Forward might be -Z. Flip if sword points backwards.
	var arm_pos = -forward_dir * ARM_LENGTH 
	
	# C. COMPOSITION
	# Final Pos = Shoulder + Arm Extension + Sway
	var final_pos = shoulder_offset + arm_pos + cur_sway
	
	# Lerp position for smoothness
	hand_node.position = hand_node.position.lerp(final_pos, SMOOTHING * delta)

func _handle_joycon(delta: float):
	while udp.get_available_packet_count() > 0:
		var packet = udp.get_packet().get_string_from_utf8().strip_edges()
		#print("Got packet:", packet)
		
		var parts = packet.split(":")
		if parts.size() < 2: continue
		
		# L or R
		var side = parts[0]
		var data = parts[1].split(',')
		
		if left_weapon.type == Weapon.WeaponType.GUN:
			if Input.is_action_just_pressed("joy_shoot_left"):
				fp_left_hand.get_node("LeftWeapon")._imu_gun_shoot("L")
		if right_weapon.type == Weapon.WeaponType.GUN:
			if Input.is_action_just_pressed("joy_shoot_right"):
				fp_right_hand.get_node("RightWeapon")._imu_gun_shoot("R")
		
		# Expect "gx, gy, gz, ax, ay, az, motion_name"
		if data.size() >= 7:
			var gx = float(data[0]) * ROTATION_SPEED
			var gy = float(data[1]) * ROTATION_SPEED
			var gz = float(data[2]) * ROTATION_SPEED
			var ax = float(data[3])
			var ay = float(data[4])
			
			var motion_name = data[6]
			
				
			if side == "L":
				target_rot_L.x += gx * delta
				target_rot_L.y += gy * delta
				target_rot_L.z += gz * delta
				
				sway_target_L = Vector3(-ax, -ay, 0) * SWAY_INTENSITY
				
				if motion_name != "none" and left_weapon:
					fp_left_hand.get_node("LeftWeapon").start_motion_attack(motion_name, "L")
					
				elif side == "R":
					# Accumulate Rotation (Integration)
					target_rot_R.x += gx * delta # Pitch
					target_rot_R.y += gy * delta # Yaw
					target_rot_R.z += gz * delta # Roll
				
					# Set Sway (Inverted Accel feels like weight lag)
					sway_target_R = Vector3(-ax, -ay, 0) * SWAY_INTENSITY
					if motion_name != "none" and right_weapon:
						fp_right_hand.get_node("RightWeapon").start_motion_attack(motion_name, "R")
		

func _on_left_weapon_request_animation(anim_name: String) -> void:
	$"../AnimationTree"["parameters/conditions/%sleft" %anim_name] = true
	await get_tree().process_frame
	$"../AnimationTree"["parameters/conditions/%sleft" %anim_name] = false


func _on_right_weapon_request_animation(anim_name: String) -> void:
	$"../AnimationTree"["parameters/conditions/%sright" %anim_name] = true
	await get_tree().process_frame
	$"../AnimationTree"["parameters/conditions/%sright" %anim_name] = false


func _on_right_weapon_request_fp_animation(anim_name: String) -> void:
	if $FirstPersonModel/AnimationPlayer.has_animation(anim_name):
		$FirstPersonModel/AnimationPlayer.play(anim_name)
		$FirstPersonModel/AnimationPlayer.queue("RESET")
	else:
		print("Animation not found")

func _on_left_weapon_request_fp_animation(anim_name: String) -> void:
	if $FirstPersonModel/AnimationPlayer.has_animation(anim_name):
		$FirstPersonModel/AnimationPlayer.play(anim_name)
		$FirstPersonModel/AnimationPlayer.queue("RESET")
	else:
		print("Animation not found")
