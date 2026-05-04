extends CanvasLayer

# Casebook overlay — opened with Tab from the manor or the timeline view.
# Pauses the tree, shows the cast (with a per-actor name dropdown for
# deduction) and the discovered memories with intro + transcript.
# All UI is built in code so the .tscn stays trivial.

const PORTRAIT_SIZE := 76

var _name_dropdowns: Dictionary = {}    # actor_id -> OptionButton
var _role_dropdowns: Dictionary = {}    # actor_id -> OptionButton
var _cast_marks: Dictionary = {}        # actor_id -> Label (status / correctness)
var _status_label: Label
var _conclude_button: Button
var _prev_mouse_mode: int = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() != "headless":
		_prev_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if get_tree() != null:
		get_tree().paused = true
	_build_ui()
	_refresh_status()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		close()
		get_viewport().set_input_as_handled()

func close() -> void:
	if get_tree() != null:
		get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = _prev_mouse_mode
	queue_free()

# ---------- UI construction ----------

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.78)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var panel_bg := StyleBoxFlat.new()
	panel_bg.bg_color = Color(0.07, 0.06, 0.05, 0.98)
	panel_bg.border_color = Color(0.45, 0.38, 0.28)
	panel_bg.border_width_left = 1
	panel_bg.border_width_top = 1
	panel_bg.border_width_right = 1
	panel_bg.border_width_bottom = 1
	panel_bg.content_margin_left = 22
	panel_bg.content_margin_right = 22
	panel_bg.content_margin_top = 16
	panel_bg.content_margin_bottom = 16

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_bg)
	margin.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	vbox.add_child(_build_header())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 22)
	scroll.add_child(content)

	content.add_child(_build_cast_section())
	content.add_child(_build_memory_section())

func _build_header() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = "Casebook"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.93, 0.88, 0.76))
	h.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.72, 0.66, 0.52))
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(_status_label)

	_conclude_button = Button.new()
	_conclude_button.text = "Conclude"
	_conclude_button.pressed.connect(_on_conclude_pressed)
	h.add_child(_conclude_button)

	var close_btn := Button.new()
	close_btn.custom_minimum_size = Vector2(36, 0)
	close_btn.text = "✕"
	close_btn.pressed.connect(close)
	h.add_child(close_btn)

	return h

# ---------- Cast section ----------

func _build_cast_section() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)

	var header := Label.new()
	header.text = "Cast"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	v.add_child(header)

	var hint := Label.new()
	hint.text = "Each guest carries a number. Name them and place their role from what you've seen and overheard. Three correct deductions confirm themselves."
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.55, 0.5, 0.42))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)

	for actor_id in Cast.IDS:
		row.add_child(_build_cast_card(actor_id))

	return v

func _build_cast_card(actor_id: String) -> Control:
	var card_bg := StyleBoxFlat.new()
	card_bg.bg_color = Color(0.10, 0.08, 0.06)
	card_bg.border_color = Color(0.30, 0.24, 0.18)
	card_bg.border_width_left = 1
	card_bg.border_width_top = 1
	card_bg.border_width_right = 1
	card_bg.border_width_bottom = 1
	card_bg.content_margin_left = 12
	card_bg.content_margin_right = 12
	card_bg.content_margin_top = 12
	card_bg.content_margin_bottom = 12
	card_bg.corner_radius_top_left = 4
	card_bg.corner_radius_top_right = 4
	card_bg.corner_radius_bottom_left = 4
	card_bg.corner_radius_bottom_right = 4

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", card_bg)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(180, 0)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var portrait_row := HBoxContainer.new()
	portrait_row.add_theme_constant_override("separation", 10)
	v.add_child(portrait_row)

	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait.draw.connect(func(): _draw_portrait(portrait, actor_id))
	portrait_row.add_child(portrait)

	var label_v := VBoxContainer.new()
	label_v.add_theme_constant_override("separation", 3)
	label_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_row.add_child(label_v)

	var label := Label.new()
	label.text = "Actor %s" % Cast.label_for(actor_id)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.93, 0.88, 0.76))
	label_v.add_child(label)

	var mark := Label.new()
	mark.add_theme_font_size_override("font_size", 12)
	mark.text = ""
	mark.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_v.add_child(mark)
	_cast_marks[actor_id] = mark

	v.add_child(_make_field_label("name"))
	var name_dd := _build_dropdown(actor_id, "name", Cast.all_names(), GameState.actor_guesses.get(actor_id, ""))
	v.add_child(name_dd)
	_name_dropdowns[actor_id] = name_dd

	v.add_child(_make_field_label("role"))
	var role_dd := _build_dropdown(actor_id, "role", Cast.all_roles(), GameState.actor_role_guesses.get(actor_id, ""))
	v.add_child(role_dd)
	_role_dropdowns[actor_id] = role_dd

	_refresh_card(actor_id)
	return panel

func _make_field_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42))
	return l

func _build_dropdown(actor_id: String, field: String, options: Array[String], current: String) -> OptionButton:
	var dd := OptionButton.new()
	dd.add_item("(unknown)", 0)
	var i := 1
	for opt in options:
		dd.add_item(opt, i)
		i += 1
	if current != "":
		var idx := options.find(current)
		if idx >= 0:
			dd.select(idx + 1)
	dd.item_selected.connect(_on_dropdown_changed.bind(actor_id, field, dd))
	return dd

func _draw_portrait(node: Control, actor_id: String) -> void:
	var center: Vector2 = node.size / 2.0
	var radius: float = min(node.size.x, node.size.y) * 0.42
	var color := Cast.color_for(actor_id)
	node.draw_circle(center, radius, color)
	node.draw_arc(center, radius, 0.0, TAU, 36, Color("181210"), 2.0, true)
	var font := ThemeDB.fallback_font
	var fs := 28
	var label_text := Cast.label_for(actor_id)
	var ts := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	node.draw_string(font, Vector2(center.x - ts.x / 2.0, center.y + fs / 3.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("181210"))

func _on_dropdown_changed(idx: int, actor_id: String, field: String, dropdown: OptionButton) -> void:
	var value := "" if idx == 0 else dropdown.get_item_text(idx)
	if field == "name":
		GameState.set_actor_guess(actor_id, value)
	else:
		GameState.set_actor_role_guess(actor_id, value)
	# Confirmations may have cascaded across actors — refresh every card.
	for id in Cast.IDS:
		_refresh_card(id)
	_refresh_status()

func _refresh_card(actor_id: String) -> void:
	if _name_dropdowns.has(actor_id):
		_apply_dropdown_state(actor_id, "name", _name_dropdowns[actor_id], Cast.name_for(actor_id))
	if _role_dropdowns.has(actor_id):
		_apply_dropdown_state(actor_id, "role", _role_dropdowns[actor_id], Cast.role_for(actor_id))
	if _cast_marks.has(actor_id):
		_refresh_card_mark(actor_id)

func _apply_dropdown_state(actor_id: String, field: String, dd: OptionButton, truth: String) -> void:
	var confirmed := GameState.is_fact_confirmed(actor_id, field)
	dd.disabled = confirmed or GameState.concluded
	if confirmed:
		var idx := -1
		for i in dd.item_count:
			if dd.get_item_text(i) == truth:
				idx = i
				break
		if idx >= 0:
			dd.select(idx)

func _refresh_card_mark(actor_id: String) -> void:
	var mark: Label = _cast_marks[actor_id]
	var name_confirmed := GameState.is_fact_confirmed(actor_id, "name")
	var role_confirmed := GameState.is_fact_confirmed(actor_id, "role")
	var name_guess: String = GameState.actor_guesses.get(actor_id, "")
	var role_guess: String = GameState.actor_role_guesses.get(actor_id, "")

	if not GameState.concluded:
		if name_confirmed and role_confirmed:
			mark.text = "✓ confirmed"
			mark.add_theme_color_override("font_color", Color(0.55, 0.85, 0.50))
		elif name_confirmed or role_confirmed:
			mark.text = "✓ %s confirmed" % ("name" if name_confirmed else "role")
			mark.add_theme_color_override("font_color", Color(0.55, 0.85, 0.50))
		elif name_guess == "" and role_guess == "":
			mark.text = "— unidentified"
			mark.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42))
		else:
			mark.text = "your guess"
			mark.add_theme_color_override("font_color", Color(0.72, 0.66, 0.52))
		return

	# Concluded: reveal correctness for both fields.
	var name_truth := Cast.name_for(actor_id)
	var role_truth := Cast.role_for(actor_id)
	var lines: Array[String] = []
	lines.append(_concluded_line(name_guess, name_truth))
	lines.append(_concluded_line(role_guess, role_truth))
	mark.text = "\n".join(lines)
	mark.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))

func _concluded_line(guess: String, truth: String) -> String:
	if guess == truth:
		return "✓ %s" % truth
	if guess == "":
		return "— %s" % truth
	return "✗ %s" % truth

# ---------- Memory section ----------

func _build_memory_section() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "Memories"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	v.add_child(header)

	var hint := Label.new()
	hint.text = "What you have witnessed. Use this log to compare voices, places, and details across moments."
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.55, 0.5, 0.42))
	v.add_child(hint)

	var memories := MemoryRegistry.all()
	if memories.is_empty():
		var empty := Label.new()
		empty.text = "(no memories recorded)"
		empty.add_theme_color_override("font_color", Color(0.5, 0.46, 0.4))
		v.add_child(empty)
		return v

	for m in memories:
		v.add_child(_build_memory_entry(m))

	return v

func _build_memory_entry(memory: Memory) -> Control:
	var discovered := GameState.discovered_memories.has(memory.id)

	var card_bg := StyleBoxFlat.new()
	card_bg.bg_color = Color(0.09, 0.07, 0.05) if discovered else Color(0.06, 0.05, 0.04)
	card_bg.border_color = Color(0.30, 0.24, 0.18)
	card_bg.border_width_left = 1
	card_bg.border_width_top = 1
	card_bg.border_width_right = 1
	card_bg.border_width_bottom = 1
	card_bg.content_margin_left = 14
	card_bg.content_margin_right = 14
	card_bg.content_margin_top = 12
	card_bg.content_margin_bottom = 12

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", card_bg)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var header := HBoxContainer.new()
	v.add_child(header)

	var title := Label.new()
	title.text = memory.title if discovered else "?????"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.93, 0.88, 0.76) if discovered else Color(0.4, 0.36, 0.3))
	header.add_child(title)

	var hspacer := Control.new()
	hspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hspacer)

	var status := Label.new()
	status.text = "discovered" if discovered else "locked"
	status.add_theme_font_size_override("font_size", 11)
	status.add_theme_color_override("font_color", Color(0.5, 0.7, 0.4) if discovered else Color(0.5, 0.46, 0.4))
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(status)

	if discovered:
		if memory.subtitle != "":
			var subtitle := Label.new()
			subtitle.text = memory.subtitle
			subtitle.add_theme_font_size_override("font_size", 12)
			subtitle.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
			subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(subtitle)
		if memory.intro != "":
			var intro := Label.new()
			intro.text = memory.intro
			intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			intro.add_theme_font_size_override("font_size", 13)
			intro.add_theme_color_override("font_color", Color(0.85, 0.80, 0.66))
			v.add_child(intro)
		var transcript := _build_transcript(memory)
		if transcript != "":
			var trans := RichTextLabel.new()
			trans.bbcode_enabled = true
			trans.fit_content = true
			trans.scroll_active = false
			trans.text = transcript
			trans.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(trans)
	else:
		var hint := Label.new()
		hint.text = "Walk the manor and find the glow. Step into it to recall the moment."
		hint.add_theme_font_size_override("font_size", 12)
		hint.add_theme_color_override("font_color", Color(0.5, 0.46, 0.4))
		v.add_child(hint)

	return panel

func _build_transcript(memory: Memory) -> String:
	if memory.timeline_id == "":
		return ""
	var script_res := load("res://data/timelines/%s.gd" % memory.timeline_id)
	if script_res == null:
		return ""
	var data: Dictionary = script_res.new().build()
	var lines: Array[String] = []
	for turn in data.turns:
		for ev in turn.events:
			match ev.kind:
				"narration":
					lines.append("[i][color=#a89e88]%s[/color][/i]" % ev.text)
				"dialogue":
					lines.append("[b][color=#e8dcbe]Actor %s[/color][/b]   \"%s\"" % [_label_in_timeline(data, ev.actor_id), ev.text])
				"action":
					lines.append("[color=#9c9686]Actor %s — %s[/color]" % [_label_in_timeline(data, ev.actor_id), ev.text])
	return "\n\n".join(lines)

func _label_in_timeline(data: Dictionary, actor_id: String) -> String:
	for a in data.actors:
		if a.id == actor_id:
			return a.label
	return "?"

# ---------- Conclude / status ----------

func _on_conclude_pressed() -> void:
	GameState.conclude_case()
	for actor_id in Cast.IDS:
		_refresh_card(actor_id)
	_refresh_status()

func _refresh_status() -> void:
	var total_facts := Cast.IDS.size() * 2
	if GameState.concluded:
		var correct := 0
		for actor_id in Cast.IDS:
			if GameState.actor_guesses.get(actor_id, "") == Cast.name_for(actor_id):
				correct += 1
			if GameState.actor_role_guesses.get(actor_id, "") == Cast.role_for(actor_id):
				correct += 1
		_status_label.text = "case concluded — %d / %d facts correct" % [correct, total_facts]
		_conclude_button.disabled = true
	else:
		var confirmed := GameState.confirmed_facts.size()
		_status_label.text = "%d / %d facts confirmed" % [confirmed, total_facts]
		_conclude_button.disabled = false
