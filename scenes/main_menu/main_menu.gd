extends Control

@onready var new_btn: Button = $CenterContainer/VBox/NewGameButton
@onready var continue_btn: Button = $CenterContainer/VBox/ContinueButton
@onready var quit_btn: Button = $CenterContainer/VBox/QuitButton

func _ready() -> void:
	continue_btn.disabled = not GameState.has_save()
	new_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)

func _on_new_game() -> void:
	GameState.start_new_game()

func _on_continue() -> void:
	GameState.continue_game()

func _on_quit() -> void:
	get_tree().quit()
