extends Control

@onready var menu_button: Button = $CenterContainer/VBox/MenuButton

func _ready() -> void:
	menu_button.pressed.connect(GameState.return_to_menu)
