extends Node3D

var udp := PacketPeerUDP.new()

@onready var rightHand = $RightHand
@onready var leftHand = $LeftHand

var targetRotL := Vector3()
var smoothRotL := Vector3()

var targetRotR := Vector3()
var smoothRotR := Vector3()

var using_first_person : bool

func _ready():
	udp.bind(4243, "127.0.0.1")
	
	if Input.get_connected_joypads().is_empty():
		using_first_person = false

func _process(_delta):
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
		leftHand.rotation = smoothRotL
		rightHand.rotation = smoothRotR
		
	else:
		pass
