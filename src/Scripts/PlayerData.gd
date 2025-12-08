extends Node

var uid : String = ""
var highscore: int=0
var current_score : float = 0 
var achievements:Array=["a1"]

signal score_updated(new_score)

func reset_score():
	current_score = 0
	emit_signal("score_updated", 0)

@onready var Sword = preload("res://src/Objects/Weapons/Blade1/Sword1.tres")
var left_hand_weapon : Weapon = Sword 
var right_hand_weapon : Weapon = null
