extends Node

var uid : String = ""
var highscore: int=0 
var achievements:Array=["a1"]

@onready var Sword = preload("res://src/Objects/Weapons/Blade1/Sword1.tres")
var left_hand_weapon : Weapon = Sword 
var right_hand_weapon : Weapon = null
