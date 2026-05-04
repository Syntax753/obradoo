extends Control

# Placeholder memory scene reused by every Memory .tres for now.
# When real timeline gameplay arrives, each Memory will point to its own
# .tscn (which can still call GameState.conclude_current_memory() to advance).

@onready var title_label: Label = $CenterContainer/VBox/Title
@onready var note_label: Label = $CenterContainer/VBox/Note
@onready var conclude_button: Button = $CenterContainer/VBox/ConcludeButton
@onready var menu_button: Button = $MenuButton

func _ready() -> void:
	var memory: Memory = GameState.current_memory()
	if memory == null:
		GameState.return_to_menu()
		return
	title_label.text = "[ %s ]" % memory.title.to_upper()
	note_label.text = (
		"Memory placeholder.\n\n"
		+ "Once built out, the player would scrub a frozen-action timeline here, "
		+ "inspecting actors and props turn-by-turn. For now, conclude to advance "
		+ "the recollection."
	)
	conclude_button.pressed.connect(GameState.conclude_current_memory)
	menu_button.pressed.connect(GameState.return_to_menu)
