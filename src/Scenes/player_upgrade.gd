@tool
class_name PlayerUpgrade
extends UIUpgrade

func _ready() -> void:
	if not Engine.is_editor_hint():
		get_upgrades()
		populate_panels()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and needs_update:
		get_upgrades()
		populate_panels()
		needs_update = false

func get_upgrades() -> void:
	upgrades.clear()

	var dir = DirAccess.open("res://src/Upgrade_resources/")
	if dir == null:
		push_warning("Failed to open resources")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource_path = "res://src/Upgrade_resources/" + file_name
			var resource = load(resource_path)

			if resource is BasePlayerStrategy:
				upgrades.append(resource)
		file_name = dir.get_next()

func populate_panels() -> void:
	upgrades_to_show.clear()

	if upgrades.is_empty():
		push_warning("populate_panels: no upgrades available. Make sure Upgrade_resources contains .tres resources.")
		return
	var panels: Array = get_children()
	var count = panels.size()

	for i in range(count):
		var p = panels[i]

		var vbox: VBoxContainer = null
		if p.has_node("VBoxContainer"):
			vbox = p.get_node("VBoxContainer") as VBoxContainer
		else:
			for c in p.get_children():
				if c is VBoxContainer:
					vbox = c
					break
		
		if vbox == null:
			continue

		var labels: Array = []
		var sprite: TextureRect = null
		for elem in vbox.get_children():
			if elem is Label:
				labels.append(elem)
			if elem is TextureRect:
				sprite = elem

		if labels.size() < 3:
			continue

		if sprite == null:
			continue

		var name_label = labels[0]
		var specs_label = labels[1]
		var cost_label = labels[2]

		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var rand_upgrd := rng.randi_range(0, upgrades.size() - 1)

		var info: BasePlayerStrategy = upgrades[rand_upgrd]
		upgrades_to_show.append(info)

		name_label.text = info.upgrade_name
		specs_label.text = info.upgrade_specs
		cost_label.text = "Cost: " + str(info.upgrade_cost)
		sprite.texture = info.texture

func initiate_upgrade(id: int) -> void:
	if id < 0 or id >= upgrades_to_show.size():
		push_warning("initiate_upgrade: index %d out of range (size=%d)" % [id, upgrades_to_show.size()])
		return

	var curr_upgrade: BasePlayerStrategy = upgrades_to_show[id]
	if curr_upgrade == null:
		push_warning("initiate_upgrade: upgrade is null at index %d" % id)
		return

	curr_upgrade.apply_upgrade()


func _on_upgrade_purchase_btn_clicked(id: int) -> void:
	var idx := id - 1
	if idx < 0:
		push_warning("_on_upgrade_purchase_btn_clicked: received invalid id %d" % id)
		return
	initiate_upgrade(idx)
