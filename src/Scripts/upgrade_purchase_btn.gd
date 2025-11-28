## Upgrade Purchase Button Tool Script
## 
## Purpose: Automatically extracts button ID from the parent's parent node name.
## This allows each upgrade button to pass its unique ID through the btn_clicked signal.
## The script is triggered by changing the name of the prarent's parent node (hierarchy is explained down below). 
##
## NOTE: The button node should not be more than two levels deep from the Upgrade Panel node.
## Expected hierarchy: UpgradePanel -> Container -> UpgradeButton (max 2 levels)

@tool
extends Button

signal btn_clicked(id: int)

@export var btn_id: int
var last_name: String = ""

func _ready():
    if not Engine.is_editor_hint():
        pressed.connect(_on_button_pressed)
    _get_btn_id()

func _process(_delta: float) -> void:
    if Engine.is_editor_hint() and get_parent().get_parent().name != last_name:
        _get_btn_id()
        last_name = get_parent().get_parent().name

func _get_btn_id():
    var node_name = get_parent().get_parent().name
    print(node_name)
    var regex = RegEx.new()
    regex.compile("-?\\d+")
    var result = regex.search(node_name)

    if result:
        btn_id = result.get_string().to_int()
        print("Button ID set to: ", btn_id)

func _on_button_pressed():
    btn_clicked.emit(btn_id)
