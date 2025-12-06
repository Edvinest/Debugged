class_name UIUpgrade
extends HBoxContainer

#Array type not defined here:
    #in WeaponUpgrade -> BaseWeaponStrategy
    #in PlayerUpgrade -> BasePlayerStrategy
var upgrades: Array = []
var upgrades_to_show: Array = []
@export var needs_update: bool = true

@onready var tween := create_tween()

func _process(delta: float) -> void:
    pass

func get_upgrades():
    pass

func populate_panels() -> void:
    pass

func initiate_upgrade(id: int) -> void:
    pass