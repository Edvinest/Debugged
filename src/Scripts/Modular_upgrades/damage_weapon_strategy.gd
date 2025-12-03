class_name DamageWeaponStrategy
extends BaseWeaponStrategy

@export var damage_increase: float = 5.0

func apply_upgrade(weapon: Weapon):
    weapon.damage += weapon.damage * damage_increase / 100
    print(weapon.name + " DAMAGE updated: " + str(weapon.damage))

