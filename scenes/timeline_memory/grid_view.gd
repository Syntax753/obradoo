class_name GridView
extends Control

const CELL_SIZE := 56

const FLOOR_COLOR := Color("e8dcbe")
const GRID_LINE_COLOR := Color("c0a880")
const FURNITURE_COLOR := Color("5a3e2a")
const FURNITURE_LABEL_COLOR := Color("efe3c8")
const PROP_ICON_COLOR := Color("efe3c8")
const PROP_ICON_SHADE := Color("3a2412")
const ACTOR_OUTLINE := Color("181210")
const ACTOR_LABEL_COLOR := Color("181210")
const HIGHLIGHT_COLOR := Color("f5d784")

const TRAIL_COLOR := Color(0.3, 0.22, 0.16, 0.5)
const TARGET_LINE_COLOR := Color(0.3, 0.22, 0.16, 0.55)
const BUBBLE_FILL := Color("f6ecd2")
const BUBBLE_OUTLINE := Color("3a2c1c")
const ICON_DARK := Color("2a1f14")
const ICON_LIGHT := Color("d8c79a")

const HELD_LABELS := {
	"decanter_a": "Decanter A",
	"decanter_b": "Decanter B",
	"wine_glass": "wine glass",
	"coat":       "coat",
}

const GESTURE_CAPTIONS := {
	"pour":    "POURING",
	"drink":   "DRINKING",
	"raise":   "TOAST",
	"lean":    "LEANING",
	"stagger": "FALLING",
	"kneel":   "KNEELING",
	"watch":   "WATCHING",
}

signal actor_clicked(actor_id: String)

var _timeline: Dictionary = {}
var _turn: Dictionary = {}
var _prev_turn: Dictionary = {}
var _highlighted: String = ""
var _hovered: String = ""

var _tooltip_panel: PanelContainer
var _tooltip_label: RichTextLabel

static func held_label(item_id: String) -> String:
	return HELD_LABELS.get(item_id, item_id)

func _ready() -> void:
	_build_tooltip()
	mouse_exited.connect(_on_mouse_exited)

func _build_tooltip() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.03, 0.94)
	sb.border_color = Color(0.55, 0.45, 0.30)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 9.0
	sb.content_margin_top = 6.0
	sb.content_margin_right = 9.0
	sb.content_margin_bottom = 6.0
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.add_theme_stylebox_override("panel", sb)
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.visible = false
	_tooltip_panel.z_index = 50
	add_child(_tooltip_panel)
	_tooltip_label = RichTextLabel.new()
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.scroll_active = false
	_tooltip_label.custom_minimum_size = Vector2(200, 0)
	_tooltip_panel.add_child(_tooltip_label)

func _on_mouse_exited() -> void:
	_hovered = ""
	_tooltip_panel.visible = false

func set_timeline(t: Dictionary) -> void:
	_timeline = t
	custom_minimum_size = Vector2(t.grid_width * CELL_SIZE, t.grid_height * CELL_SIZE)
	queue_redraw()

func show_turn(t: Dictionary, prev: Dictionary = {}) -> void:
	_turn = t
	_prev_turn = prev
	queue_redraw()
	if _hovered != "" and _tooltip_panel.visible:
		_refresh_tooltip_text()

func set_highlight(actor_id: String) -> void:
	_highlighted = actor_id
	queue_redraw()

func _draw() -> void:
	if _timeline.is_empty():
		return
	var w: int = _timeline.grid_width
	var h: int = _timeline.grid_height

	# Floor
	draw_rect(Rect2(0, 0, w * CELL_SIZE, h * CELL_SIZE), FLOOR_COLOR, true)
	for x in range(w + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, h * CELL_SIZE), GRID_LINE_COLOR, 1.0)
	for y in range(h + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(w * CELL_SIZE, y * CELL_SIZE), GRID_LINE_COLOR, 1.0)

	# Furniture
	for p in _timeline.props:
		_draw_prop(p)

	if _turn.is_empty():
		return

	var states: Dictionary = _turn.actor_states
	var prev_states: Dictionary = _prev_turn.get("actor_states", {})

	# Motion trails (drawn under actors)
	for actor in _timeline.actors:
		var st = states.get(actor.id, null)
		if st == null:
			continue
		var prev = prev_states.get(actor.id, null)
		if prev != null and prev.pos != st.pos:
			_draw_motion_trail(_cell_center(prev.pos), _cell_center(st.pos))

	# Gesture target lines (under actors)
	for actor in _timeline.actors:
		var st = states.get(actor.id, null)
		if st == null:
			continue
		var target: Vector2i = st.get("gesture_target", Vector2i(-9999, -9999))
		if target.x > -9000 and st.get("gesture", "") != "":
			_draw_target_line(_cell_center(st.pos), _cell_center(target), st.gesture)

	# Actors
	for actor in _timeline.actors:
		var st = states.get(actor.id, null)
		if st == null:
			continue
		_draw_actor(actor, st)

	# Speech bubbles (on top)
	var speakers := _speakers_this_turn()
	for actor in _timeline.actors:
		var st = states.get(actor.id, null)
		if st != null and speakers.has(actor.id):
			_draw_speech_bubble(_cell_center(st.pos))

	# Action captions below actors
	for actor in _timeline.actors:
		var st = states.get(actor.id, null)
		if st == null:
			continue
		var caption := GESTURE_CAPTIONS.get(st.get("gesture", ""), "") as String
		if caption == "" and speakers.has(actor.id):
			caption = "SPEAKING"
		if caption != "":
			_draw_caption(_cell_center(st.pos), caption)

func _draw_actor(actor: Dictionary, st: Dictionary) -> void:
	var center := _cell_center(st.pos)
	var radius: float = CELL_SIZE * 0.34
	if actor.id == _highlighted:
		draw_circle(center, radius + 5.0, HIGHLIGHT_COLOR)
	# Lean displaces the silhouette toward target by ~30% cell
	var draw_center := center
	if st.get("gesture", "") == "lean":
		var target: Vector2i = st.get("gesture_target", Vector2i(-9999, -9999))
		if target.x > -9000:
			draw_center = center.lerp(_cell_center(target), 0.35)
	# Kneel renders smaller
	if st.get("gesture", "") == "kneel":
		radius *= 0.7
	draw_circle(draw_center, radius, actor.color)
	draw_arc(draw_center, radius, 0, TAU, 36, ACTOR_OUTLINE, 2.0, true)
	# Facing tick
	var dir := _facing_vec(st.get("facing", ""))
	if dir != Vector2.ZERO:
		draw_line(draw_center, draw_center + dir * (radius - 4.0), ACTOR_OUTLINE, 3.0)
	# Held item icon
	var holding: String = st.get("holding", "")
	if holding != "":
		_draw_held_icon(draw_center + Vector2(radius * 1.05, -radius * 0.4), holding)
	# Stagger overlay (wavy lines around actor)
	if st.get("gesture", "") == "stagger":
		_draw_stagger_overlay(draw_center, radius)
	# Drink overlay (glass at face)
	if st.get("gesture", "") == "drink":
		_draw_drink_overlay(draw_center, radius)
	# Raise overlay (upward arrow)
	if st.get("gesture", "") == "raise":
		_draw_raise_overlay(draw_center, radius)
	# Watch overlay (eye dot in front)
	if st.get("gesture", "") == "watch":
		_draw_watch_overlay(draw_center, radius, dir)
	# Label
	var font := ThemeDB.fallback_font
	var fs := 18
	var ts := font.get_string_size(actor.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(font, Vector2(draw_center.x - ts.x / 2.0, draw_center.y + fs / 3.0), actor.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ACTOR_LABEL_COLOR)

func _draw_prop(prop: Dictionary) -> void:
	var r: Rect2i = prop.rect
	var pixel_rect := Rect2(
		r.position.x * CELL_SIZE + 4,
		r.position.y * CELL_SIZE + 4,
		r.size.x * CELL_SIZE - 8,
		r.size.y * CELL_SIZE - 8
	)
	draw_rect(pixel_rect, FURNITURE_COLOR, true)
	var pid := String(prop.get("id", ""))
	var label := String(prop.get("label", ""))
	match pid:
		"coat_rack": _icon_coat_rack(pixel_rect)
		"stairs":    _icon_stairs(pixel_rect)
		"door":
			if "front" in label.to_lower():
				_icon_front_door(pixel_rect)
			else:
				_icon_doorway(pixel_rect, Vector2.RIGHT)
		"library_dr": _icon_doorway(pixel_rect, Vector2.RIGHT)
		"to_dining":  _icon_doorway(pixel_rect, Vector2.RIGHT)
		"desk":       _icon_desk(pixel_rect)
		"armchair":   _icon_armchair(pixel_rect)
		"shelf_n":    _icon_bookshelf(pixel_rect, true)
		"shelf_w":    _icon_bookshelf(pixel_rect, false)
		"table", "table_edge": _icon_table(pixel_rect)
		_:
			var font := ThemeDB.fallback_font
			var fs := 11
			var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var c := pixel_rect.get_center()
			draw_string(font, Vector2(c.x - ts.x / 2.0, c.y + fs / 3.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, FURNITURE_LABEL_COLOR)

func _icon_coat_rack(rect: Rect2) -> void:
	var c := rect.get_center()
	var col := PROP_ICON_COLOR
	# Base
	draw_rect(Rect2(c.x - 9, rect.end.y - 8, 18, 4), col, true)
	# Pole
	var pole_top := rect.position.y + 10
	draw_rect(Rect2(c.x - 2, pole_top, 4, rect.end.y - 8 - pole_top), col, true)
	# Crossbar
	draw_rect(Rect2(c.x - 12, pole_top, 24, 3), col, true)
	# Hooks (small downturned tips)
	draw_rect(Rect2(c.x - 14, pole_top + 3, 3, 5), col, true)
	draw_rect(Rect2(c.x + 11, pole_top + 3, 3, 5), col, true)

func _icon_stairs(rect: Rect2) -> void:
	# Top-down staircase: shaded step bands + central up-arrow.
	var step_h := 8.0
	var n: int = maxi(2, int(floor(rect.size.y / step_h)))
	step_h = rect.size.y / float(n)
	for i in n:
		var y: float = rect.position.y + i * step_h
		draw_rect(Rect2(rect.position.x, y, rect.size.x, 2), PROP_ICON_SHADE, true)
	# Up arrow centered
	var c := rect.get_center()
	var col := PROP_ICON_COLOR
	var ax := c.x
	var ay := c.y - 8
	draw_rect(Rect2(ax - 2, ay, 4, 16), col, true)          # shaft
	draw_rect(Rect2(ax - 6, ay + 4, 4, 4), col, true)       # left wing
	draw_rect(Rect2(ax + 2, ay + 4, 4, 4), col, true)       # right wing
	draw_rect(Rect2(ax - 8, ay + 6, 4, 4), col, true)       # outer left
	draw_rect(Rect2(ax + 4, ay + 6, 4, 4), col, true)       # outer right

func _icon_front_door(rect: Rect2) -> void:
	var c := rect.get_center()
	var col := PROP_ICON_COLOR
	var dw := minf(rect.size.x - 12, 26)
	var dh := minf(rect.size.y - 8, 38)
	var dx := c.x - dw / 2.0
	var dy := c.y - dh / 2.0
	# Door panel outline (chunky)
	draw_rect(Rect2(dx, dy, dw, 3), col, true)
	draw_rect(Rect2(dx, dy + dh - 3, dw, 3), col, true)
	draw_rect(Rect2(dx, dy, 3, dh), col, true)
	draw_rect(Rect2(dx + dw - 3, dy, 3, dh), col, true)
	# Inset panel lines
	draw_rect(Rect2(dx + 6, dy + 7, dw - 12, 2), col, true)
	draw_rect(Rect2(dx + 6, dy + dh / 2.0, dw - 12, 2), col, true)
	# Knob
	draw_rect(Rect2(dx + dw - 8, dy + dh / 2.0 + 6, 3, 3), col, true)

func _icon_doorway(rect: Rect2, dir: Vector2) -> void:
	# Open passage: two jambs framing an arrow in `dir`.
	var c := rect.get_center()
	var col := PROP_ICON_COLOR
	var jamb_h := minf(rect.size.y - 10, 30)
	var jy := c.y - jamb_h / 2.0
	# Jambs
	draw_rect(Rect2(rect.position.x + 4, jy, 3, jamb_h), col, true)
	draw_rect(Rect2(rect.end.x - 7, jy, 3, jamb_h), col, true)
	# Lintel
	draw_rect(Rect2(rect.position.x + 4, jy, rect.size.x - 8, 3), col, true)
	# Direction arrow centered between jambs
	if dir == Vector2.RIGHT:
		var ax := c.x - 6
		var ay := c.y - 2
		draw_rect(Rect2(ax, ay, 12, 4), col, true)            # shaft
		draw_rect(Rect2(ax + 8, ay - 4, 4, 4), col, true)
		draw_rect(Rect2(ax + 8, ay + 4, 4, 4), col, true)
		draw_rect(Rect2(ax + 12, ay - 2, 4, 4), col, true)
		draw_rect(Rect2(ax + 12, ay + 2, 4, 4), col, true)

func _icon_desk(rect: Rect2) -> void:
	# Top-down desk: rectangle with a drawer line and ink pot.
	var col := PROP_ICON_COLOR
	var inset := Vector2(8, 6)
	var top := Rect2(rect.position + inset, rect.size - inset * 2.0)
	draw_rect(top, col, false)
	draw_rect(Rect2(top.position.x + 1, top.position.y + 1, top.size.x - 2, top.size.y - 2), col.darkened(0.3), false)
	# Drawer line (front edge — bottom of rect)
	draw_rect(Rect2(top.position.x + 4, top.end.y - 8, top.size.x - 8, 2), col, true)
	# Ink pot
	var c := rect.get_center()
	draw_rect(Rect2(c.x - 3, c.y - 3, 6, 6), col, true)
	draw_rect(Rect2(c.x - 1, c.y - 6, 2, 3), col, true)

func _icon_armchair(rect: Rect2) -> void:
	var col := PROP_ICON_COLOR
	var c := rect.get_center()
	var w := minf(rect.size.x - 10, 28)
	var h := minf(rect.size.y - 10, 28)
	var x := c.x - w / 2.0
	var y := c.y - h / 2.0
	# Backrest (top thick band)
	draw_rect(Rect2(x, y, w, 6), col, true)
	# Arms
	draw_rect(Rect2(x, y, 5, h), col, true)
	draw_rect(Rect2(x + w - 5, y, 5, h), col, true)
	# Seat cushion
	draw_rect(Rect2(x + 6, y + 9, w - 12, h - 12), col.darkened(0.25), true)

func _icon_bookshelf(rect: Rect2, horizontal: bool) -> void:
	var col := PROP_ICON_COLOR
	var dark := PROP_ICON_SHADE
	if horizontal:
		# Row of book spines spanning the rect.
		var book_w := 6.0
		var gap := 2.0
		var stride := book_w + gap
		var y := rect.get_center().y - 9
		var x := rect.position.x + 4
		var i := 0
		while x + book_w <= rect.end.x - 4:
			var h: float = 18.0 if i % 3 == 1 else 14.0
			var bc: Color = col.darkened(0.25) if i % 2 == 1 else col
			draw_rect(Rect2(x, y + (18.0 - h), book_w, h), bc, true)
			draw_rect(Rect2(x, y + (18.0 - h), book_w, 2), dark, true)
			x += stride
			i += 1
	else:
		var book_h := 6.0
		var gap := 2.0
		var stride := book_h + gap
		var x := rect.get_center().x - 9
		var y := rect.position.y + 4
		var i := 0
		while y + book_h <= rect.end.y - 4:
			var w: float = 18.0 if i % 3 == 1 else 14.0
			var bc: Color = col.darkened(0.25) if i % 2 == 1 else col
			draw_rect(Rect2(x + (18.0 - w), y, w, book_h), bc, true)
			draw_rect(Rect2(x + (18.0 - w), y, 2, book_h), dark, true)
			y += stride
			i += 1

func _icon_table(rect: Rect2) -> void:
	var col := PROP_ICON_COLOR
	# Tabletop edge highlight along all sides.
	draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, rect.size.x - 4, 2), col, true)
	draw_rect(Rect2(rect.position.x + 2, rect.end.y - 4, rect.size.x - 4, 2), col, true)
	draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, 2, rect.size.y - 4), col, true)
	draw_rect(Rect2(rect.end.x - 4, rect.position.y + 2, 2, rect.size.y - 4), col, true)
	# Wood grain — a few horizontal streaks
	var streaks: int = maxi(1, int(rect.size.y / 22.0))
	for i in streaks:
		var sy: float = rect.position.y + 8 + i * 18
		if sy > rect.end.y - 8:
			break
		draw_rect(Rect2(rect.position.x + 8, sy, rect.size.x - 16, 1), col.darkened(0.15), true)

func _draw_held_icon(pos: Vector2, item_id: String) -> void:
	match item_id:
		"decanter_a", "decanter_b":
			var body_w := 8.0
			var body_h := 16.0
			var neck_w := 4.0
			var neck_h := 4.0
			var color := Color("6a3030") if item_id == "decanter_a" else Color("3a2050")
			draw_rect(Rect2(pos.x - neck_w / 2.0, pos.y - body_h / 2.0 - neck_h, neck_w, neck_h), color, true)
			draw_rect(Rect2(pos.x - body_w / 2.0, pos.y - body_h / 2.0, body_w, body_h), color, true)
			draw_rect(Rect2(pos.x - body_w / 2.0, pos.y - body_h / 2.0, body_w, body_h), ICON_DARK, false)
		"wine_glass":
			var pts := PackedVector2Array([
				Vector2(pos.x - 6, pos.y - 8),
				Vector2(pos.x + 6, pos.y - 8),
				Vector2(pos.x + 2, pos.y),
				Vector2(pos.x - 2, pos.y),
			])
			draw_colored_polygon(pts, Color("8a3030"))
			draw_polyline(pts + PackedVector2Array([pts[0]]), ICON_DARK, 1.0)
			draw_line(Vector2(pos.x, pos.y), Vector2(pos.x, pos.y + 6), ICON_DARK, 1.5)
			draw_line(Vector2(pos.x - 4, pos.y + 6), Vector2(pos.x + 4, pos.y + 6), ICON_DARK, 1.5)
		"coat":
			draw_rect(Rect2(pos.x - 6, pos.y - 6, 12, 12), Color("3a2c1c"), true)
			draw_rect(Rect2(pos.x - 6, pos.y - 6, 12, 12), ICON_DARK, false)

func _draw_stagger_overlay(center: Vector2, radius: float) -> void:
	for i in 3:
		var off := Vector2(cos(i * 2.1) * (radius + 6 + i * 2), sin(i * 2.1) * (radius + 6 + i * 2))
		draw_arc(center + off, 4, 0, PI, 8, ICON_DARK, 1.5)
		draw_arc(center + off + Vector2(8, 0), 4, PI, TAU, 8, ICON_DARK, 1.5)

func _draw_drink_overlay(center: Vector2, radius: float) -> void:
	var cup_top := center + Vector2(0, -radius - 4)
	var pts := PackedVector2Array([
		cup_top + Vector2(-7, 0),
		cup_top + Vector2(7, 0),
		cup_top + Vector2(3, 8),
		cup_top + Vector2(-3, 8),
	])
	draw_colored_polygon(pts, Color("8a3030"))
	draw_polyline(pts + PackedVector2Array([pts[0]]), ICON_DARK, 1.5)

func _draw_raise_overlay(center: Vector2, radius: float) -> void:
	var top := center + Vector2(0, -radius - 14)
	draw_line(center + Vector2(0, -radius), top, ICON_DARK, 2.0)
	draw_line(top, top + Vector2(-4, 4), ICON_DARK, 2.0)
	draw_line(top, top + Vector2(4, 4), ICON_DARK, 2.0)

func _draw_watch_overlay(center: Vector2, radius: float, facing: Vector2) -> void:
	var dir := facing if facing != Vector2.ZERO else Vector2(0, -1)
	var eye_pos := center + dir * (radius + 8)
	draw_circle(eye_pos, 2.5, ICON_DARK)
	draw_arc(eye_pos, 5, -0.6, 0.6, 8, ICON_DARK, 1.0)

func _draw_motion_trail(from_px: Vector2, to_px: Vector2) -> void:
	# Faded ghost circle at start
	draw_arc(from_px, CELL_SIZE * 0.28, 0, TAU, 24, TRAIL_COLOR, 1.5)
	# Dashed segments
	var dist := from_px.distance_to(to_px)
	var dir := (to_px - from_px).normalized()
	var step := 8.0
	var p := from_px + dir * 6.0
	while p.distance_to(from_px) < dist - 6.0:
		var p2: Vector2 = p + dir * 5.0
		draw_line(p, p2, TRAIL_COLOR, 2.0)
		p = p + dir * step
	# Arrow head
	var head := to_px - dir * (CELL_SIZE * 0.30)
	var perp := Vector2(-dir.y, dir.x) * 5.0
	draw_line(head, head - dir * 6.0 + perp, TRAIL_COLOR, 2.0)
	draw_line(head, head - dir * 6.0 - perp, TRAIL_COLOR, 2.0)

func _draw_target_line(from_px: Vector2, to_px: Vector2, gesture: String) -> void:
	var col := TARGET_LINE_COLOR
	if gesture == "watch":
		col = Color(0.4, 0.32, 0.16, 0.30)
	# Dashed line
	var dist := from_px.distance_to(to_px)
	if dist < 4.0:
		return
	var dir := (to_px - from_px).normalized()
	var step := 8.0
	var p := from_px + dir * (CELL_SIZE * 0.32)
	while p.distance_to(from_px) < dist - CELL_SIZE * 0.32:
		var p2: Vector2 = p + dir * 4.0
		draw_line(p, p2, col, 1.5)
		p = p + dir * step

func _draw_speech_bubble(actor_center: Vector2) -> void:
	var bubble_center := actor_center + Vector2(CELL_SIZE * 0.35, -CELL_SIZE * 0.55)
	var size := Vector2(20, 14)
	var rect := Rect2(bubble_center - size / 2.0, size)
	draw_rect(rect, BUBBLE_FILL, true)
	draw_rect(rect, BUBBLE_OUTLINE, false)
	# Tail
	var tail_top := Vector2(rect.position.x + 4, rect.position.y + size.y)
	var tail_tip := Vector2(rect.position.x + 1, rect.position.y + size.y + 5)
	var tail_bot := Vector2(rect.position.x + 9, rect.position.y + size.y)
	draw_colored_polygon(PackedVector2Array([tail_top, tail_tip, tail_bot]), BUBBLE_FILL)
	draw_line(tail_top, tail_tip, BUBBLE_OUTLINE, 1.0)
	draw_line(tail_tip, tail_bot, BUBBLE_OUTLINE, 1.0)
	# Three dots
	for i in 3:
		draw_circle(rect.position + Vector2(5 + i * 5, 7), 1.2, BUBBLE_OUTLINE)

func _draw_caption(actor_center: Vector2, caption: String) -> void:
	var font := ThemeDB.fallback_font
	var fs := 9
	var ts := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pos := actor_center + Vector2(-ts.x / 2.0, CELL_SIZE * 0.40 + fs)
	# Faint background plate for legibility
	var pad := Vector2(4, 1)
	draw_rect(Rect2(pos - Vector2(pad.x, fs), ts + pad * 2.0), Color(0.05, 0.04, 0.03, 0.55), true)
	draw_string(font, pos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ICON_LIGHT)

func _speakers_this_turn() -> Dictionary:
	var s := {}
	if _turn.is_empty():
		return s
	for ev in _turn.events:
		if ev.kind == "dialogue" and ev.has("actor_id"):
			s[ev.actor_id] = true
	return s

func _cell_center(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2.0, pos.y * CELL_SIZE + CELL_SIZE / 2.0)

func _facing_vec(facing: String) -> Vector2:
	match facing:
		"N": return Vector2(0, -1)
		"S": return Vector2(0, 1)
		"E": return Vector2(1, 0)
		"W": return Vector2(-1, 0)
	return Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_tooltip(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var actor_id := _actor_at_pixel(event.position)
		if actor_id != "":
			actor_clicked.emit(actor_id)

func _update_tooltip(local_pos: Vector2) -> void:
	var actor_id := _actor_at_pixel(local_pos)
	var key := ""
	if actor_id != "":
		key = "actor:" + actor_id
	else:
		var prop_label := _prop_at_pixel(local_pos)
		if prop_label != "":
			key = "prop:" + prop_label
	if key == "":
		_hovered = ""
		_tooltip_panel.visible = false
		return
	if key != _hovered:
		_hovered = key
		_refresh_tooltip_text()
	_tooltip_panel.position = local_pos + Vector2(18, 18)
	_tooltip_panel.visible = true

func _refresh_tooltip_text() -> void:
	if _hovered == "":
		return
	if _hovered.begins_with("prop:"):
		var label := _hovered.substr(5)
		_tooltip_label.text = "[b][color=#f0e2bc]%s[/color][/b]" % label
		return
	if _turn.is_empty():
		return
	var actor_id := _hovered.substr(6)
	var st = _turn.actor_states.get(actor_id, null)
	var lines: Array[String] = []
	lines.append("[b][color=#f0e2bc]Actor %s[/color][/b]" % _label_for(actor_id))
	if st != null:
		if st.has("action") and st.action != "":
			lines.append("[color=#bcb29c]%s[/color]" % st.action)
		if st.has("holding") and st.holding != "":
			lines.append("[color=#bcb29c]holding[/color]   %s" % held_label(st.holding))
		if st.has("gesture") and st.gesture != "":
			lines.append("[color=#bcb29c]gesture[/color]   %s" % st.gesture)
	else:
		lines.append("[i][color=#8a8472]not present this turn[/color][/i]")
	_tooltip_label.text = "\n".join(lines)

func _actor_at_pixel(local_pos: Vector2) -> String:
	if _turn.is_empty():
		return ""
	var grid_pos := Vector2i(int(local_pos.x / CELL_SIZE), int(local_pos.y / CELL_SIZE))
	var states: Dictionary = _turn.actor_states
	for actor in _timeline.actors:
		var st = states.get(actor.id, null)
		if st != null and st.pos == grid_pos:
			return actor.id
	return ""

func _label_for(actor_id: String) -> String:
	for a in _timeline.actors:
		if a.id == actor_id:
			return a.label
	return "?"

func _prop_at_pixel(local_pos: Vector2) -> String:
	if _timeline.is_empty():
		return ""
	var grid_pos := Vector2i(int(local_pos.x / CELL_SIZE), int(local_pos.y / CELL_SIZE))
	for p in _timeline.props:
		var r: Rect2i = p.rect
		if Rect2i(r.position, r.size).has_point(grid_pos):
			return String(p.get("label", ""))
	return ""
