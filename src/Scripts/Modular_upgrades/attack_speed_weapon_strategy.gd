class_name AttackSpeedWeaponStrategy
extends BaseWeaponStrategy

@export var attack_speed_increase: float = 0.0

func apply_upgrade(weapon: Weapon):
    weapon.attack_speed -= weapon.attack_speed * attack_speed_increase / 100
    print(weapon.name +  " ATTACK SPEED updated: " + str(weapon.attack_speed))