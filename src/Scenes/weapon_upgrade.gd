@tool
class_name WeaponUpgrade
extends UIUpgraged

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and needs_update:
		get_upgrades()
		populate_panels()
		needs_update = false

func get_upgrades() -> void:
	upgrades.clear()

	var dir = DirAccess.open("res://src/Upgrade_resources/")
	if dir == null:
		push_warning("Failed to open resources.")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource_path = "res://src/Upgrade_resources/" + file_name
			var resource = load(resource_path)

			if resource is BaseWeaponStrategy:
				upgrades.append(resource)
		file_name = dir.get_next()

func populate_panels() -> void:
	
	upgrades_to_show.clear()
	var panels: Array = get_children()
	var count = panels.size()

    #TO-DO: by creating a duplication of the upgrades, then pop the used one there won't
        #be displayed the same upgrade twice
    #Use shufle on them:
        #   var shuffled_upgrades = upgrades.duplicate()
        #   shuffled_upgrades.shuffle()

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

		if labels.size() < 4:
			continue

		if sprite == null:
			continue

		var name_label = labels[0]
		var specs_label = labels[1]
		var cost_label = labels[3]
		var applies_label = labels[2]

		var rand_upgrd = int(randf_range(0, upgrades.size()))

		var info: BaseWeaponStrategy = upgrades[rand_upgrd]
		name_label.text = info.upgrade_name
		specs_label.text = info.upgrade_specs
		applies_label.text = "Applies to: " + ", ".join(info.allowed_weapon_types.map(func(w): return str(w)))
		cost_label.text = "Cost: " + str(info.upgrade_cost)
		sprite.texture = info.texture