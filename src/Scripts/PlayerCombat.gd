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

@export var left_weapon : Weapon
@export var right_weapon : Weapon

@onready var right_hand = $RightHand
@onready var left_hand = $LeftHand
@onready var AnimPlayer = $"../../AnimationPlayer"

var using_first_person : bool = true

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
		if left_hand.has_node("WeaponInstance"):
			left_hand.get_node("WeaponInstance")._perform_standard_attack("left", )
			
	if Input.is_action_just_pressed("attack_right"):
		if right_hand.has_node("WeaponInstance"):
			#right_hand.get_node("WeaponInstance")._perform_standard_attack("right")
			right_hand.get_node("WeaponInstance").start_motion_attack("diag_up_right", right_hand)
	
		
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
			left_hand.get_node("WeaponInstance").start_motion_attack(direction_L, left_hand)
	
	
	if right_weapon and swing_freeze_R <= 0:
		var max_axis_R = rot_vel_R.max_axis_index()
		var speed_R = rot_vel_R[max_axis_R]
		
		if speed_R > SWING_THRESHOLD:
			swing_freeze_R = FREEZE_TIME
			
			var direction_R = _classify_swing_direction(rot_vel_R)
			right_hand.get_node("WeaponInstance").start_motion_attack(direction_R, right_hand)

		var sway_strength_rot = 0.03          
		var sway_strength_pos = 0.0003          
		var sway_speed = 2.0            

		# Smooth bobbing up/down
		var bob_offset = sin(fp_anim_time * sway_speed) * sway_strength_pos

		# Slight side-to-side sway using cosine
		var side_offset = cos(fp_anim_time * sway_speed) * sway_strength_pos

		# Slight rotation wiggle
		var rot_wiggle_x = sin(fp_anim_time * sway_speed) * sway_strength_rot
		var rot_wiggle_z = cos(fp_anim_time * sway_speed) * sway_strength_rot
		
		if using_first_person:
			if swing_freeze_L <= 0:
				left_hand.rotation = smoothRotL
				left_hand.rotation.x += rot_wiggle_x
				left_hand.rotation.z += rot_wiggle_z

				left_hand.position += Vector3(side_offset, bob_offset, 0)
				
			if swing_freeze_R <= 0:
				right_hand.rotation = smoothRotR
				right_hand.rotation.x += rot_wiggle_x
				right_hand.rotation.z += rot_wiggle_z

				right_hand.position += Vector3(-side_offset, bob_offset, 0)

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

func _on_weapon_instance_request_animation(anim_name: String) -> void:
	if AnimPlayer.has_animation(anim_name):
		AnimPlayer.play(anim_name)
		AnimPlayer.queue("RESET")
	else:
		print("Animation not found:", anim_name)
