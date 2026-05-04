extends Control

@onready var new_btn: Button = $CenterContainer/VBox/NewGameButton
@onready var continue_btn: Button = $CenterContainer/VBox/ContinueButton
@onready var quit_btn: Button = $CenterContainer/VBox/QuitButton

func _ready() -> void:
	continue_btn.disabled = not GameState.has_save()
	new_btn.pressed.connect(GameState.start_new_game)
	continue_btn.pressed.connect(GameState.continue_game)
	quit_btn.pressed.connect(get_tree().quit)
