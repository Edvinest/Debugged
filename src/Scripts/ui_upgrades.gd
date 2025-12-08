class_name UIUpgrade
extends HBoxContainer

#Array type not defined here:
	#in WeaponUpgrade -> BaseWeaponStrategy
	#in PlayerUpgrade -> BasePlayerStrategy
var upgrades: Array = []
var upgrades_to_show: Array = []
@export var needs_update: bool = true


func get_upgrades():
	pass

func populate_panels() -> void:
	pass

func initiate_upgrade(_id: int) -> void:
	pass
