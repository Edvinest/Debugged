extends Control
signal backPressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var Highscore={}
var Leaderboard={}
var Achievemnts={}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	emit_signal("backPressed")


func _on_leaderboard_button_pressed() -> void:
	%Highscore.hide()
	%Achievements.hide()
	%Leaderboard.show()


func _on_highscore_button_pressed() -> void:
	%Achievements.hide()
	%Leaderboard.hide()
	%Highscore.show()

func _on_achievements_button_pressed() -> void:
	%Highscore.hide()
	%Leaderboard.hide()
	%Achievements.show()
