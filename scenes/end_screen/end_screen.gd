extends Control

@onready var menu_button: Button = $CenterContainer/VBox/MenuButton

func _ready() -> void:
	menu_button.pressed.connect(GameState.return_to_menu)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		_open_casebook()

func _open_casebook() -> void:
	if has_node("Casebook"):
		return
	var scene := load("res://scenes/casebook/casebook.tscn") as PackedScene
	if scene == null:
		return
	var inst := scene.instantiate()
	inst.name = "Casebook"
	add_child(inst)
