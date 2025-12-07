@tool
class_name WeaponUpgrade
extends UIUpgrade

signal weapon_upgrade_purchased(cost: float, upgrade: BaseWeaponStrategy, weapon: Weapon)

func _ready() -> void:
	# Populate upgrades at runtime (not only editor) so upgrades_to_show is available during play
	if not Engine.is_editor_hint():
		get_upgrades()
		populate_panels()

func _process(_delta: float) -> void:
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
	# If we have no loaded upgrades, there's nothing to populate.
	if upgrades.is_empty():
		push_warning("populate_panels: no upgrades available. Make sure Upgrade_resources contains .tres resources.")
		return
	var panels: Array = get_children()
	var count = panels.size()

	#TO-DO: by creating a duplication of the upgrades, then pop the used one there won't
		#be displayed the same upgrade twice
	#Use shufle on them:
	var shuffled_upgrades = upgrades.duplicate()
	shuffled_upgrades.shuffle()

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

		# Pick a safe random index from 0..upgrades.size()-1
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var rand_upgrd := rng.randi_range(0, upgrades.size() - 1)

		var info: BaseWeaponStrategy = shuffled_upgrades.pop_at(rand_upgrd)
		upgrades_to_show.append(info)
		name_label.text = info.upgrade_name

		var modification_value
		if info is DamageWeaponStrategy:
			modification_value = info.damage_increase
		elif info is AttackSpeedWeaponStrategy:
			modification_value = info.attack_speed_decrease
		specs_label.text = info.upgrade_specs + " " + str(modification_value) + "%"

		#applies_label.text = "Applies to: " + ", ".join(info.allowed_weapon_types.map(func(w): return str(w.name)))
		applies_label.text = "Applies to: " + info.allowed_weapon_type.name
		cost_label.text = "Cost: " + str(info.upgrade_cost)
		sprite.texture = info.texture


func initiate_upgrade(id: int) -> void:
	# Ensure index is within range to avoid out of bounds access
	if id < 0 or id >= upgrades_to_show.size():
		push_warning("initiate_upgrade: index %d out of range (size=%d)" % [id, upgrades_to_show.size()])
		return

	var curr_upgrade: BaseWeaponStrategy = upgrades_to_show[id]
	if curr_upgrade == null:
		push_warning("initiate_upgrade: upgrade is null at index %d" % id)
		return

	if curr_upgrade.allowed_weapon_types.is_empty():
		push_warning("initiate_upgrade: upgrade at index %d has no applicable weapon types" % id)
		return

	weapon_upgrade_purchased.emit(curr_upgrade.upgrade_cost, curr_upgrade, curr_upgrade.allowed_weapon_type)

func _on_upgrade_purchase_btn_clicked(id: int) -> void:
	# Buttons are expected to provide 1-based IDs in the editor (e.g. "UpgradeButton1").
	# Convert to 0-based index and validate before calling initiate_upgrade.
	var idx := id - 1
	if idx < 0:
		push_warning("_on_upgrade_purchase_btn_clicked: received invalid id %d" % id)
		return
	initiate_upgrade(idx)
