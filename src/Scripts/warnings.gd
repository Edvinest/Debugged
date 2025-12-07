extends CanvasLayer

@onready var warning_timer: Timer = %WarningTimer
@onready var time_left: Label = %Close

func _process(delta):
    if not warning_timer.is_stopped():
        time_left.text = "This window closes automatically. (" + str(int(ceil(warning_timer.time_left))) + ")"