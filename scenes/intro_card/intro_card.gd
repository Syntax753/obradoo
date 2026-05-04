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
