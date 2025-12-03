extends PanelContainer

var _tween: Tween
var _original_z := 0

func _ready() -> void:
    mouse_entered.connect(_on_hover)
    mouse_exited.connect(_on_leave)
    _original_z = z_index


func _make_tween() -> Tween:
    # Always kill old tween safely
    if _tween and _tween.is_valid():
        _tween.kill()

    _tween = create_tween()
    return _tween


func _on_hover():
    z_as_relative = false
    z_index = 1  # bring to front

    var tween = _make_tween()
    tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)\
         .set_trans(Tween.TRANS_SINE)\
         .set_ease(Tween.EASE_OUT)


func _on_leave():
    z_index = _original_z

    var tween = _make_tween()
    tween.tween_property(self, "scale", Vector2(1, 1), 0.15)\
         .set_trans(Tween.TRANS_SINE)\
         .set_ease(Tween.EASE_OUT)
