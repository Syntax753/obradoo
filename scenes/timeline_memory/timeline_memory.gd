extends Control

@onready var grid_view: GridView = $HBox/Left/ScrollContainer/GridView
@onready var title_label: Label = $HBox/Right/Header/Title
@onready var turn_label: Label = $HBox/Right/Header/TurnLabel
@onready var events_text: RichTextLabel = $HBox/Right/EventsPanel/Margin/EventsText
@onready var inspect_text: RichTextLabel = $HBox/Right/InspectPanel/Margin/InspectText
@onready var prev_btn: Button = $Bottom/PrevButton
@onready var next_btn: Button = $Bottom/NextButton
@onready var slider: HSlider = $Bottom/Slider
@onready var conclude_btn: Button = $Top/ConcludeButton
@onready var menu_btn: Button = $Top/MenuButton

var _timeline: Dictionary = {}
var _current_turn: int = 0
var _inspected: String = ""

func _ready() -> void:
	var memory: Memory = GameState.current_memory()
	if memory == null or memory.timeline_id == "":
		GameState.return_to_menu()
		return
	var script_path := "res://data/timelines/%s.gd" % memory.timeline_id
	var script_res := load(script_path)
	if script_res == null:
		push_error("Timeline script not found: %s" % script_path)
		GameState.return_to_menu()
		return
	_timeline = script_res.new().build()
	title_label.text = _timeline.title
	grid_view.set_timeline(_timeline)
	grid_view.actor_clicked.connect(_on_actor_clicked)

	var n: int = _timeline.turns.size()
	slider.min_value = 0
	slider.max_value = max(n - 1, 0)
	slider.step = 1
	slider.value_changed.connect(func(v): _show_turn(int(v)))
	prev_btn.pressed.connect(func(): _show_turn(_current_turn - 1))
	next_btn.pressed.connect(func(): _show_turn(_current_turn + 1))
	conclude_btn.pressed.connect(GameState.conclude_current_memory)
	menu_btn.pressed.connect(GameState.return_to_menu)

	_show_turn(0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT:
			_show_turn(_current_turn - 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_RIGHT:
			_show_turn(_current_turn + 1)
			get_viewport().set_input_as_handled()

func _show_turn(idx: int) -> void:
	var n: int = _timeline.turns.size()
	if n == 0:
		return
	idx = clamp(idx, 0, n - 1)
	_current_turn = idx
	var turn: Dictionary = _timeline.turns[idx]
	grid_view.show_turn(turn)
	turn_label.text = "Turn %d / %d" % [idx + 1, n]
	slider.set_value_no_signal(idx)
	prev_btn.disabled = (idx == 0)
	next_btn.disabled = (idx == n - 1)
	_refresh_events(turn)
	_refresh_inspect(turn)

func _refresh_events(turn: Dictionary) -> void:
	var lines: Array[String] = []
	for ev in turn.events:
		match ev.kind:
			"narration":
				lines.append("[i][color=#a89e88]%s[/color][/i]" % ev.text)
			"dialogue":
				lines.append("[b][color=#e8dcbe]Actor %s[/color][/b]   \"%s\"" % [_label_for(ev.actor_id), ev.text])
			"action":
				lines.append("[color=#9c9686]Actor %s — %s[/color]" % [_label_for(ev.actor_id), ev.text])
			_:
				lines.append(str(ev.get("text", "")))
	if lines.is_empty():
		events_text.text = "[i][color=#6c6658](nothing spoken this turn)[/color][/i]"
	else:
		events_text.text = "\n\n".join(lines)

func _refresh_inspect(turn: Dictionary) -> void:
	if _inspected == "":
		inspect_text.text = "[i][color=#6c6658]Click an actor on the grid to inspect.[/color][/i]"
		grid_view.set_highlight("")
		return
	grid_view.set_highlight(_inspected)
	var st = turn.actor_states.get(_inspected, null)
	if st == null:
		inspect_text.text = "[i]Not present this turn.[/i]"
		return
	var lines: Array[String] = []
	lines.append("[b][color=#e8dcbe]Actor %s[/color][/b]" % _label_for(_inspected))
	if st.has("action") and st.action != "":
		lines.append("[color=#bcb29c]action:[/color]   %s" % st.action)
	if st.has("holding") and st.holding != "":
		lines.append("[color=#bcb29c]holding:[/color]   %s" % st.holding)
	if st.has("facing") and st.facing != "":
		lines.append("[color=#bcb29c]facing:[/color]   %s" % st.facing)
	if st.has("pos"):
		lines.append("[color=#bcb29c]position:[/color]   (%d, %d)" % [st.pos.x, st.pos.y])
	inspect_text.text = "\n".join(lines)

func _on_actor_clicked(actor_id: String) -> void:
	_inspected = actor_id
	_refresh_inspect(_timeline.turns[_current_turn])

func _label_for(actor_id: String) -> String:
	for a in _timeline.actors:
		if a.id == actor_id:
			return a.label
	return "?"
