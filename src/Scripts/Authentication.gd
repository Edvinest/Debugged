extends Control
signal successfulLogin
@onready var users_collection = Firebase.Firestore.collection("users") 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.signup_failed.connect(on_signup_failed)
	Firebase.Auth.userdata_received.connect(on_profile_data_received)

	check_auto_login()
	
	#hiding password
	%PasswordLineEdit.secret=true

func check_auto_login():
	if Firebase.Auth.check_auth_file():
		%StateLabel.text = "Found saved session. Verifying.."
	else:
		%StateLabel.text = "Please log in"

func on_profile_data_received(userdata : FirebaseUserData):
	var uid = userdata.local_id
	
	if uid == "" or uid == null:
		_handle_session_error("Couldn't load saved session")
		return
	
	var user_doc = await users_collection.get_doc(uid)
	if user_doc == null or user_doc.document == null:
		print("Firestore profile missing")
		_handle_session_error("User not found. Log in again")
	
	var username = user_doc.get_value("user_name")
	if username == null:
		username = "Unknown"
	
	%StateLabel.text = "Welcome back, %s!" % username
	emit_signal("successfulLogin")

func _on_sign_up_button_pressed() -> void:
	var email = %EmailLineEdit.text
	var username = $%UserNameLineEdit.text
	var password= %PasswordLineEdit.text
	
	if email == "" or password == "" or username == "":
		%StateLabel.text = "Please fill in all fields"
		return
		
	Firebase.Auth.signup_with_email_and_password(email,password)
	%StateLabel.text="Signing up"

func _handle_session_error(reason: String):
	Firebase.Auth.logout()
	%StateLabel.text = reason

func _on_log_in_button_pressed() -> void:
	var email = %EmailLineEdit.text
	var password= %PasswordLineEdit.text
	
	if email == "" or password == "":
		%StateLabel.text = "Please enter email and password"
		return
		
	Firebase.Auth.login_with_email_and_password(email,password)
	%StateLabel.text="Logging in"
	
	
func on_login_succeeded(auth)->void:
	print(auth)
	%StateLabel.text="Login succeeded"
	Firebase.Auth.save_auth(auth)
	Firebase.Auth.get_user_data()

func on_signup_succeeded(auth)->void:
	print("Auth response:", auth)
	%StateLabel.text="Signup succeeded"
	
	Firebase.Auth.save_auth(auth)
	
	var uid=auth.get("localid")
	var email=auth.get("email")
	var username= %UserNameLineEdit.text
	
	var user_data ={
		"user_name":username,
		"email":email,
		"u_id":uid
	}
	

	await users_collection.add(uid, user_data)
	%StateLabel.text = "Signup successful! You can now log in."
func _on_show_button_pressed() -> void:
	if 	%PasswordLineEdit.secret==true:
			%PasswordLineEdit.secret=false
			%ShowButton.text="HIDE"
	else: 	
		%PasswordLineEdit.secret=true
		%ShowButton.text="SHOW"

func on_login_failed():
	pass

func on_signup_failed():
	pass
