class_name SpeedPlayerStrategy
extends BasePlayerStrategy

@export var speed_increase: float = 0.0
@export var speed_component: PlayerSpeedComponent = null

func apply_upgrade():
    if speed_increase != 0.0 and speed_component != null:
        speed_component.player_speed += speed_component.player_speed * speed_increase / 100
        print("Player speed increased to: " + str(speed_component.player_speed))