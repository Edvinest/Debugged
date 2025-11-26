@tool
class_name PlayerUpgrade
extends UIUpgraged

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and needs_update:
		needs_update = false

func get_upgrades() -> void:
	super()

func populate_panels() -> void:
	super()


