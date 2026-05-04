extends Control

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Panel/Margin/VBox/Subtitle
@onready var intro_label: Label = $Panel/Margin/VBox/Intro
@onready var begin_button: Button = $Panel/Margin/VBox/BeginButton
@onready var back_button: Button = $BackButton

func _ready() -> void:
	var memory: Memory = GameState.active_memory()
	if memory == null:
		GameState.enter_world()
		return
	title_label.text = memory.title
	subtitle_label.text = memory.subtitle
	intro_label.text = memory.intro
	begin_button.pressed.connect(GameState.enter_active_memory_scene)
	back_button.pressed.connect(GameState.return_to_world)
