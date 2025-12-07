class_name HealthPlayerStrategy
extends BasePlayerStrategy

@export var max_health_increase: float = 0.0
@export var health_component: PlayerHealthComponent = null

func apply_upgrade():
    if max_health_increase != 0.0 and health_component != null:
        health_component.player_max_health += health_component.player_max_health * max_health_increase / 100
        print("Player max hp increased to: " + str(health_component.player_max_health))