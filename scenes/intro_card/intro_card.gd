extends Control

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Panel/Margin/VBox/Subtitle
@onready var intro_label: Label = $Panel/Margin/VBox/Intro
@onready var begin_button: Button = $Panel/Margin/VBox/BeginButton
@onready var menu_button: Button = $MenuButton
@onready var counter_label: Label = $CounterLabel

func _ready() -> void:
	var memory: Memory = GameState.current_memory()
	if memory == null:
		GameState.return_to_menu()
		return
	title_label.text = memory.title
	subtitle_label.text = memory.subtitle
	intro_label.text = memory.intro
	counter_label.text = "Memory %d of %d" % [GameState.current_memory_index + 1, MemoryRegistry.count()]
	begin_button.pressed.connect(GameState.enter_current_memory_scene)
	menu_button.pressed.connect(GameState.return_to_menu)
