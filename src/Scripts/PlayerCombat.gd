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
#@onready var AnimPlayer = $"../../AnimationPlayer"

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
	_handle_joycon()
	
	if using_first_person:
		if swing_freeze_L > 0:
			swing_freeze_L -= delta
		if swing_freeze_R > 0:
			swing_freeze_R -= delta
			
		fp_anim_time += delta
	else:
		_detect_input_attacks()

func _detect_input_attacks():
	if Input.is_action_just_pressed("attack_left"):
		if tp_left_hand.has_node("LeftWeapon"):
			tp_left_hand.get_node("LeftWeapon")._perform_standard_attack()
			
	if Input.is_action_just_pressed("attack_right"):
		if tp_right_hand.has_node("RightWeapon"):
			tp_right_hand.get_node("RightWeapon")._perform_standard_attack()
			#right_hand.get_node("WeaponInstance").start_motion_attack("diag_up_right", right_hand)
	
		
func _handle_joycon():
	while udp.get_available_packet_count() > 0:
		var packet = udp.get_packet().get_string_from_utf8().strip_edges()
		#print("Got packet:", packet)

		# Expect "L:roll, pitch, yaw" or "R:roll, pitch, yaw"
		var side_and_vals = packet.split(":")
		if side_and_vals.size() == 2:
			var side = side_and_vals[0]
			var vals = side_and_vals[1].split(",")
			if vals.size() == 3:
				var roll = float(vals[0])
				var pitch = float(vals[1])
				var yaw = float(vals[2])
				var rot_vec = Vector3(pitch, yaw, roll)
				
				if side == "L":
					recentPacketsL.append(rot_vec)
					if recentPacketsL.size() > PACKET_HISTORY_SIZE:
						recentPacketsL.pop_front()
						
				elif side == "R":
					recentPacketsR.append(rot_vec)
					if recentPacketsR.size() > PACKET_HISTORY_SIZE:
						recentPacketsR.pop_front()


	# Compute weighted average for left and right
	var avgL = _weighted_average_mod(recentPacketsL)
	#print("Average L: " ,avgL)
	var avgR = _weighted_average_mod(recentPacketsR)
	#print("Average R: " , avgR)
	
	filteredRotL = filteredRotL.lerp(avgL, 0.25)
	filteredRotR = filteredRotR.lerp(avgR, 0.25)
	
	var rot_vel_L = (filteredRotL - prevRotL).abs()
	var rot_vel_R = (filteredRotR - prevRotR).abs()
	prevRotL = filteredRotL
	prevRotR = filteredRotR
	
	if left_weapon and swing_freeze_L <= 0:
		var max_axis_L = rot_vel_L.max_axis_index()
		var speed_L = rot_vel_L[max_axis_L]
		
		if speed_L > SWING_THRESHOLD:
			swing_freeze_L = FREEZE_TIME
			
			var direction_L = _classify_swing_direction(rot_vel_L)
			fp_left_hand.get_node("LeftWeapon").start_motion_attack(direction_L, fp_left_hand)
	
	
	if right_weapon and swing_freeze_R <= 0:
		var max_axis_R = rot_vel_R.max_axis_index()
		var speed_R = rot_vel_R[max_axis_R]
		
		if speed_R > SWING_THRESHOLD:
			swing_freeze_R = FREEZE_TIME
			
			var direction_R = _classify_swing_direction(rot_vel_R)
			fp_right_hand.get_node("RightWeapon").start_motion_attack(direction_R, fp_right_hand)

	else:
		pass

func _classify_swing_direction(vel: Vector3) -> String:
	var dir_2d = Vector2(vel.y, -vel.x)  # horizontal/vertical projection
	if dir_2d.length() < 0.05:
		return "stab"
	dir_2d = dir_2d.normalized()
	var angle = dir_2d.angle()  # -PI..PI
	# Divide circle into 8 segments
	if angle < -7*PI/8: return "left"
	if angle < -5*PI/8: return "diag_down_left"
	if angle < -3*PI/8: return "down"
	if angle < -PI/8: return "diag_down_right"
	if angle < PI/8: return "right"
	if angle < 3*PI/8: return "diag_up_right"
	if angle < 5*PI/8: return "up"
	if angle < 7*PI/8: return "diag_up_left"
	return "left"

func _weighted_average_mod(history: Array) -> Vector3:
	if history.is_empty():
		return Vector3.ZERO

	var total_weight = 0.0
	var weighted_sum = Vector3.ZERO
	var count = history.size()

	var last_yaw_sign = sign(history[0].y)
	var stabilized_history: Array = []

	for i in range(count):
		var v = history[i]
		var current_sign = sign(v.y)

		# Detect a single-sample sign flip (likely noise)
		if abs(v.y) < 0.015:  # small deadzone near zero
			v.y = 0.0
		elif current_sign != 0 and current_sign != last_yaw_sign:
			# Smooth out the sudden sign flip
			v.y = (2*v.y + history[i - 1].y) / 2.0
			last_yaw_sign = current_sign
		stabilized_history.append(v)

	# Weighted average after stabilization
	for i in range(count):
		var weight = float(i + 1) / count
		if history[i].y < 0.1 and history[i].y>-0.1:
			history[i].y *= 10
		weighted_sum += stabilized_history[i] * weight
		total_weight += weight

	var avg = weighted_sum / total_weight

	# Keep yaw slightly alive even when near zero
	if abs(avg.y) < 0.1:
		avg.y = sign(avg.y) * 0.1 if avg.y != 0 else 0.1

	return avg

func _on_left_weapon_request_animation(anim_name: String) -> void:
	$"../AnimationTree"["parameters/conditions/%sleft" %anim_name] = true
	await get_tree().process_frame
	$"../AnimationTree"["parameters/conditions/%sleft" %anim_name] = false


func _on_right_weapon_request_animation(anim_name: String) -> void:
	$"../AnimationTree"["parameters/conditions/%sright" %anim_name] = true
	await get_tree().process_frame
	$"../AnimationTree"["parameters/conditions/%sright" %anim_name] = false
