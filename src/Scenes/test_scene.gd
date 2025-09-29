extends Node

var py_process_id := 0

func _ready():
	# Start the Python script (non-blocking)
	# Returns an int process ID, not a Process object
	var args = ["-u", "joyconserver.py"]
	py_process_id = OS.create_process("python3", args)
	print("Joy-Con server started, PID:", py_process_id)


func _exit_tree():
	# Kill Python script when game closes
	if py_process_id != 0:
		OS.kill(py_process_id)
		print("Joy-Con server stopped")
