extends Node

# First-person 3D manor. Geometry is generated procedurally from ROOMS/WALLS
# (mirrored from the original 2D version) so layout edits stay in one place.
# The whole scene is rendered into a low-res SubViewport and run through the
# 1-bit dither shader on the SubViewportContainer for the Obra Dinn look.

const TILE := 2.0                   # 1 layout tile = 2 metres
const WALL_HEIGHT := 3.0
const PLAYER_SPEED := 4.5
const MOUSE_SENS := 0.0025
const PITCH_LIMIT := 1.4

# Press 1..5 to swap palette/scale at runtime.
const DITHER_PRESETS := [
	{"ink": Color(0.10, 0.08, 0.06), "parchment": Color(0.91, 0.86, 0.74), "scale": 2.0}, # Parchment
	{"ink": Color(0.10, 0.10, 0.08), "parchment": Color(0.85, 0.83, 0.75), "scale": 2.0}, # Bone
	{"ink": Color(0.16, 0.08, 0.05), "parchment": Color(0.94, 0.85, 0.66), "scale": 2.0}, # Sepia
	{"ink": Color(0.04, 0.10, 0.18), "parchment": Color(0.77, 0.85, 0.91), "scale": 2.0}, # Blueprint
	{"ink": Color(0.0,  0.0,  0.0),  "parchment": Color(1.0,  1.0,  1.0),  "scale": 3.0}, # Carbon
]

const ROOMS := [
	{"name": "Drawing Room", "rect": Rect2i(1, 1, 6, 6)},
	{"name": "Foyer",        "rect": Rect2i(7, 1, 7, 6)},
	{"name": "Dining Room",  "rect": Rect2i(14, 1, 7, 6)},
	{"name": "Library",      "rect": Rect2i(1, 8, 20, 5)},
]

# 1-tile-thick wall rects in tile coords. Doors are the gaps.
const WALLS := [
	Rect2i(0, 0, 22, 1),     # outer top
	Rect2i(0, 13, 22, 1),    # outer bottom
	Rect2i(0, 0, 1, 14),     # outer left
	Rect2i(21, 0, 1, 14),    # outer right
	Rect2i(7, 1, 1, 3),      # drawing/foyer top (door at row 4)
	Rect2i(7, 5, 1, 2),      # drawing/foyer bottom
	Rect2i(14, 1, 1, 3),     # foyer/dining top (door at row 4)
	Rect2i(14, 5, 1, 2),     # foyer/dining bottom
	Rect2i(1, 7, 9, 1),      # upper/library divider west (door at col 10)
	Rect2i(11, 7, 10, 1),    # upper/library divider east
]

var _player: CharacterBody3D
var _camera: Camera3D
var _yaw: float = 0.0
var _pitch: float = 0.0
var _trigger_for_memory: Dictionary = {}
var _current_trigger: Memory = null

@onready var _prompt_label: Label = $UI/PromptLabel
@onready var _menu_button: Button = $UI/MenuButton
@onready var _location_label: Label = $UI/LocationLabel
@onready var _world: Node3D = $ViewportLayer/Viewport/SubViewport/World
@onready var _viewport_container: SubViewportContainer = $ViewportLayer/Viewport

func _ready() -> void:
	_menu_button.pressed.connect(_on_menu_pressed)
	_build_environment()
	_build_floor_and_ceiling()
	_build_walls()
	_build_props()
	_build_player()
	_build_triggers()
	_update_prompt()
	_update_location()
	_capture_mouse(true)

func _exit_tree() -> void:
	_capture_mouse(false)

func _capture_mouse(capture: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE

func _on_menu_pressed() -> void:
	_capture_mouse(false)
	GameState.return_to_menu()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * MOUSE_SENS
		_pitch = clamp(_pitch - event.relative.y * MOUSE_SENS, -PITCH_LIMIT, PITCH_LIMIT)
		if _player:
			_player.rotation.y = _yaw
		if _camera:
			_camera.rotation.x = _pitch
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_capture_mouse(false)
		elif event.keycode == KEY_F1:
			_capture_mouse(true)
		elif event.keycode == KEY_TAB:
			_open_casebook()
			get_viewport().set_input_as_handled()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			_apply_dither_preset(event.keycode - KEY_1)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Click into the viewport to recapture (but not when clicking the menu button).
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not _menu_button.get_global_rect().has_point(event.position):
			_capture_mouse(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _current_trigger != null:
		get_viewport().set_input_as_handled()
		var trigger := _current_trigger
		_current_trigger = null
		_capture_mouse(false)
		GameState.enter_memory(trigger)

func _physics_process(_delta: float) -> void:
	if _player == null:
		return
	var input_vec := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    input_vec.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  input_vec.z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_vec.x += 1.0
	if input_vec.length() > 0.0:
		input_vec = input_vec.normalized()
	var forward_basis := Basis(Vector3.UP, _yaw)
	var world_vec: Vector3 = forward_basis * input_vec * PLAYER_SPEED
	_player.velocity = Vector3(world_vec.x, 0.0, world_vec.z)
	_player.move_and_slide()
	_update_location()

# ---------- World construction ----------

func _build_environment() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -35, 0)
	key.light_energy = 1.4
	_world.add_child(key)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.04, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.55, 0.5)
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	_world.add_child(we)

func _build_floor_and_ceiling() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.42, 0.36, 0.30)
	var ceil_mat := StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.18, 0.15, 0.12)

	for room in ROOMS:
		var r: Rect2i = room.rect
		var center := Vector3(
			(float(r.position.x) + float(r.size.x) * 0.5) * TILE,
			0.0,
			(float(r.position.y) + float(r.size.y) * 0.5) * TILE
		)
		var size := Vector2(float(r.size.x) * TILE, float(r.size.y) * TILE)

		var floor_mesh := PlaneMesh.new()
		floor_mesh.size = size
		floor_mesh.material = floor_mat
		var floor_inst := MeshInstance3D.new()
		floor_inst.mesh = floor_mesh
		floor_inst.position = center
		_world.add_child(floor_inst)

		var ceil_mesh := PlaneMesh.new()
		ceil_mesh.size = size
		ceil_mesh.material = ceil_mat
		var ceil_inst := MeshInstance3D.new()
		ceil_inst.mesh = ceil_mesh
		ceil_inst.rotation_degrees = Vector3(180.0, 0.0, 0.0)
		ceil_inst.position = center + Vector3(0.0, WALL_HEIGHT, 0.0)
		_world.add_child(ceil_inst)

func _build_walls() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.78, 0.72, 0.62)

	for r in WALLS:
		var center := Vector3(
			(float(r.position.x) + float(r.size.x) * 0.5) * TILE,
			WALL_HEIGHT * 0.5,
			(float(r.position.y) + float(r.size.y) * 0.5) * TILE
		)
		var size := Vector3(float(r.size.x) * TILE, WALL_HEIGHT, float(r.size.y) * TILE)

		var body := StaticBody3D.new()
		body.position = center
		var shape := BoxShape3D.new()
		shape.size = size
		var cs := CollisionShape3D.new()
		cs.shape = shape
		body.add_child(cs)
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = wall_mat
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		body.add_child(mi)
		_world.add_child(body)

func _build_props() -> void:
	# A few placeholder furnishings so the rooms aren't empty boxes.
	# Each is {room_tile_center: Vector2, size: Vector3, height_offset: float, color: Color}
	var props := [
		# Drawing room — sofa-ish block + side table
		{"pos": Vector2(3.5, 4.0), "size": Vector3(2.0, 0.7, 0.8), "color": Color(0.45, 0.30, 0.22)},
		{"pos": Vector2(5.5, 2.0), "size": Vector3(0.7, 0.6, 0.7), "color": Color(0.50, 0.36, 0.24)},
		# Dining table fills the dining room
		{"pos": Vector2(17.5, 4.0), "size": Vector3(4.0, 0.85, 1.6), "color": Color(0.40, 0.25, 0.15)},
		# Library shelves along the far wall
		{"pos": Vector2(3.0, 12.0), "size": Vector3(3.5, 2.4, 0.5), "color": Color(0.30, 0.20, 0.12)},
		{"pos": Vector2(7.0, 12.0), "size": Vector3(3.5, 2.4, 0.5), "color": Color(0.30, 0.20, 0.12)},
		{"pos": Vector2(15.0, 12.0), "size": Vector3(3.5, 2.4, 0.5), "color": Color(0.30, 0.20, 0.12)},
		{"pos": Vector2(19.0, 12.0), "size": Vector3(3.5, 2.4, 0.5), "color": Color(0.30, 0.20, 0.12)},
		# Reading desk centre-library
		{"pos": Vector2(11.0, 10.0), "size": Vector3(1.8, 0.85, 1.0), "color": Color(0.42, 0.28, 0.18)},
	]

	for p in props:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = p.color
		var pos: Vector2 = p.pos
		var size: Vector3 = p.size
		var center := Vector3(pos.x * TILE, size.y * 0.5, pos.y * TILE)

		var body := StaticBody3D.new()
		body.position = center
		var shape := BoxShape3D.new()
		shape.size = size
		var cs := CollisionShape3D.new()
		cs.shape = shape
		body.add_child(cs)
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		body.add_child(mi)
		_world.add_child(body)

func _build_player() -> void:
	_player = CharacterBody3D.new()
	_player.name = "Player"
	# Spawn in foyer (matches old 2D spawn at tile 10.5, 4.5)
	_player.position = Vector3(10.5 * TILE, 0.85, 4.5 * TILE)

	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.7
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_player.add_child(cs)

	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, 0.7, 0.0)
	_camera.current = true
	_player.add_child(_camera)

	_world.add_child(_player)

func _build_triggers() -> void:
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.95, 0.78, 0.40)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.85, 0.45)
	glow_mat.emission_energy_multiplier = 3.0
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for memory in MemoryRegistry.all():
		var area := Area3D.new()
		area.name = "Trigger_" + memory.id
		area.position = Vector3(
			(float(memory.world_position.x) + 0.5) * TILE,
			0.0,
			(float(memory.world_position.y) + 0.5) * TILE
		)
		var shape := CylinderShape3D.new()
		shape.radius = 0.9
		shape.height = 2.2
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.position = Vector3(0.0, 1.1, 0.0)
		area.add_child(cs)

		# Visible pillar of light
		var pillar := MeshInstance3D.new()
		var pmesh := CylinderMesh.new()
		pmesh.top_radius = 0.05
		pmesh.bottom_radius = 0.45
		pmesh.height = 1.8
		pmesh.material = glow_mat
		pillar.mesh = pmesh
		pillar.position = Vector3(0.0, 0.9, 0.0)
		area.add_child(pillar)

		area.body_entered.connect(func(body): _on_trigger_entered(memory, body))
		area.body_exited.connect(func(body): _on_trigger_exited(memory, body))
		_world.add_child(area)
		_trigger_for_memory[memory.id] = area

func _on_trigger_entered(memory: Memory, body: Node) -> void:
	if body == _player:
		_current_trigger = memory
		_update_prompt()

func _on_trigger_exited(memory: Memory, body: Node) -> void:
	if body == _player and _current_trigger == memory:
		_current_trigger = null
		_update_prompt()

func _update_prompt() -> void:
	if _current_trigger == null:
		_prompt_label.text = ""
		_prompt_label.visible = false
		return
	var visited := GameState.discovered_memories.has(_current_trigger.id)
	var verb := "Recall" if visited else "Glimpse"
	_prompt_label.text = "%s — “%s”\n[Space]" % [verb, _current_trigger.title]
	_prompt_label.visible = true

func _open_casebook() -> void:
	if has_node("Casebook"):
		return
	_capture_mouse(false)
	var scene := load("res://scenes/casebook/casebook.tscn") as PackedScene
	if scene == null:
		return
	var inst := scene.instantiate()
	inst.name = "Casebook"
	add_child(inst)

func _apply_dither_preset(idx: int) -> void:
	if idx < 0 or idx >= DITHER_PRESETS.size():
		return
	var mat := _viewport_container.material as ShaderMaterial
	if mat == null:
		return
	var preset: Dictionary = DITHER_PRESETS[idx]
	mat.set_shader_parameter("ink_color", preset.ink)
	mat.set_shader_parameter("parchment_color", preset.parchment)
	mat.set_shader_parameter("pixel_scale", preset.scale)

func _update_location() -> void:
	if _player == null:
		return
	var tile_pos := Vector2i(int(_player.position.x / TILE), int(_player.position.z / TILE))
	var room_name := "—"
	for room in ROOMS:
		if (room.rect as Rect2i).has_point(tile_pos):
			room_name = room.name
			break
	_location_label.text = "Ravensreach Manor — %s" % room_name
