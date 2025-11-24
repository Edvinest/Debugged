extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	Firebase.Auth.signup_failed.connect(on_login_failed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_sign_up_button_pressed() -> void:
	var email = %EmailLineEdit.text
	var password= %PasswordLineEdit.text
	Firebase.Auth.signup_with_email_and_password(email,password)
	%StateLabel.text="Signing up"

func _on_log_in_button_pressed() -> void:
	var email = %EmailLineEdit.text
	var password= %PasswordLineEdit.text
	Firebase.Auth.login_with_email_and_password(email,password)
	%StateLabel.text="Logging in"
	
	
func on_login_succeeded(auth)->void:
	print(auth)
	%StateLabel.text="Login succeeded"
	Firebase.Auth.save_auth(auth)
	var uid=auth["localid"]
	var email=auth["email"]
	var users_collection=Firebase.Firestore.collection("users")
	var user_doc=await users_collection.get_doc(uid)
   
	if user_doc == null:
		push_error("No user document found for UID: %s" % uid)
		return
	var username = user_doc.get("user_name")
	%StateLabel.text = "Welcome back, %s!" % username	

func on_signup_succeeded(auth)->void:
	print("Auth response:", auth)
	%StateLabel.text="Login succeeded"
	Firebase.Auth.save_auth(auth)
	var uid=auth["localid"]
	var email=auth["email"]
	var username= %UserNameLineEdit.text
	
	var user_data ={
		"user_name":username,
		"email":email,
		"u_id":uid
	}
	
	var users_collection = Firebase.Firestore.collection("users")
	await users_collection.add(uid, user_data)
	%StateLabel.text = "Signup successful! You can now log in."
	
	
func on_login_failed(error_code, message)->void:
	print(error_code)
	print(message)
	%StateLabel.text="Login failed %s" % message
	
func on_signup_failed(error_code, message)->void:
	print(error_code)
	print(message)
	%StateLabel.text="Signup failed %s" % message
