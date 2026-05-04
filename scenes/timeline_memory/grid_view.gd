class_name GridView
extends Control

const CELL_SIZE := 56
const FLOOR_COLOR := Color("e8dcbe")
const GRID_LINE_COLOR := Color("c0a880")
const FURNITURE_COLOR := Color("5a3e2a")
const FURNITURE_LABEL_COLOR := Color("efe3c8")
const ACTOR_OUTLINE := Color("181210")
const ACTOR_LABEL_COLOR := Color("181210")
const HIGHLIGHT_COLOR := Color("f5d784")

signal actor_clicked(actor_id: String)

var _timeline: Dictionary = {}
var _turn: Dictionary = {}
var _highlighted: String = ""

func set_timeline(t: Dictionary) -> void:
	_timeline = t
	custom_minimum_size = Vector2(t.grid_width * CELL_SIZE, t.grid_height * CELL_SIZE)
	queue_redraw()

func show_turn(t: Dictionary) -> void:
	_turn = t
	queue_redraw()

func set_highlight(actor_id: String) -> void:
	_highlighted = actor_id
	queue_redraw()

func _draw() -> void:
	if _timeline.is_empty():
		return
	var w: int = _timeline.grid_width
	var h: int = _timeline.grid_height

	for x in w:
		for y in h:
			var rect := Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(rect, FLOOR_COLOR, true)
	for x in range(w + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, h * CELL_SIZE), GRID_LINE_COLOR, 1.0)
	for y in range(h + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(w * CELL_SIZE, y * CELL_SIZE), GRID_LINE_COLOR, 1.0)

	var font := ThemeDB.fallback_font
	for p in _timeline.props:
		var r: Rect2i = p.rect
		var pixel_rect := Rect2(
			r.position.x * CELL_SIZE + 4,
			r.position.y * CELL_SIZE + 4,
			r.size.x * CELL_SIZE - 8,
			r.size.y * CELL_SIZE - 8
		)
		draw_rect(pixel_rect, FURNITURE_COLOR, true)
		var label: String = p.label
		var fs := 13
		var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var center := pixel_rect.get_center()
		draw_string(font, Vector2(center.x - ts.x / 2.0, center.y + fs / 3.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, FURNITURE_LABEL_COLOR)

	if _turn.is_empty():
		return
	var states: Dictionary = _turn.actor_states
	for actor in _timeline.actors:
		var st = states.get(actor.id, null)
		if st == null:
			continue
		var pos: Vector2i = st.pos
		var center := Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2.0, pos.y * CELL_SIZE + CELL_SIZE / 2.0)
		var radius: float = CELL_SIZE * 0.36
		if actor.id == _highlighted:
			draw_circle(center, radius + 5.0, HIGHLIGHT_COLOR)
		draw_circle(center, radius, actor.color)
		draw_arc(center, radius, 0, TAU, 36, ACTOR_OUTLINE, 2.0, true)
		if st.has("facing"):
			var dir := _facing_vec(st.facing)
			if dir != Vector2.ZERO:
				draw_line(center, center + dir * (radius - 4.0), ACTOR_OUTLINE, 3.0)
		var fs := 18
		var label: String = actor.label
		var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(font, Vector2(center.x - ts.x / 2.0, center.y + fs / 3.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ACTOR_LABEL_COLOR)

func _facing_vec(facing: String) -> Vector2:
	match facing:
		"N": return Vector2(0, -1)
		"S": return Vector2(0, 1)
		"E": return Vector2(1, 0)
		"W": return Vector2(-1, 0)
	return Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos := Vector2i(int(event.position.x / CELL_SIZE), int(event.position.y / CELL_SIZE))
		if _turn.is_empty():
			return
		var states: Dictionary = _turn.actor_states
		for actor in _timeline.actors:
			var st = states.get(actor.id, null)
			if st != null and st.pos == grid_pos:
				actor_clicked.emit(actor.id)
				return
