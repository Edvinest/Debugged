extends Control
signal backPressed

@onready var stats = Firebase.Firestore.collection("Stats")
@onready var ach = Firebase.Firestore.collection("Achievements")
@onready var highscore_label = %HighscoreLabel

var highscore : int
var achievements : Array
var achievement_descriptions : Array = []

func load_profile_data(uid: String) -> void:
	# Dokumentum lekérése
	var doc = await stats.get_doc(uid)
	if doc == null or doc.document == null:
		print("Stats not found for user ", uid)
		return
	
	highscore = doc.get_value("highscore")
	achievements = doc.get_value("achievements")
	highscore_label.text = "Your highscore: %s" % highscore
			
	for ach_id in achievements:
		var ach_id_clean = str(ach_id).strip_edges()
		var ach_doc = await ach.get_doc(ach_id_clean)
	
		var description = ""
		if ach_doc.get("description") != null:
			description = str(ach_doc.get("description"))
		else:
			description = "Unknown achievement"
	
		achievement_descriptions.append(description+"\n")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


		
func _on_back_button_pressed() -> void:
	emit_signal("backPressed")


func _on_highscore_button_pressed() -> void:
	highscore_label.text = "Your highscore: %s" % highscore
	%Achievements.hide()
	%Leaderboard.hide()
	%Highscore.show()

func _on_achievements_button_pressed() -> void:
	%Highscore.hide()
	%Leaderboard.hide()
	%Achievements.show()
	%AchievementsText.text = "Achievements:\n" + "".join(achievement_descriptions.map(str))

# stats beolvasása
