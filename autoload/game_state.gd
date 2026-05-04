extends Node

const SAVE_PATH := "user://obradoo_save.cfg"
const WORLD_SCENE := "res://scenes/world/manor_3d.tscn"
const INTRO_SCENE := "res://scenes/intro_card/intro_card.tscn"
const MENU_SCENE  := "res://scenes/main_menu/main_menu.tscn"

const CONFIRM_THRESHOLD := 3

var discovered_memories: Array[String] = []
var actor_guesses: Dictionary = {}        # actor_id -> guessed name (string)
var actor_role_guesses: Dictionary = {}   # actor_id -> guessed role (string)
var confirmed_facts: Array[String] = []   # entries like "a1:name", "a3:role"
var concluded: bool = false

var _active_memory_id: String = ""

func _ready() -> void:
	_load_progress()

func has_save() -> bool:
	return discovered_memories.size() > 0

func start_new_game() -> void:
	discovered_memories.clear()
	actor_guesses.clear()
	actor_role_guesses.clear()
	confirmed_facts.clear()
	concluded = false
	_save_progress()
	enter_world()

func set_actor_guess(actor_id: String, guess: String) -> void:
	if is_fact_confirmed(actor_id, "name"):
		return
	if guess == "":
		actor_guesses.erase(actor_id)
	else:
		actor_guesses[actor_id] = guess
	_check_confirmations()
	_save_progress()

func set_actor_role_guess(actor_id: String, guess: String) -> void:
	if is_fact_confirmed(actor_id, "role"):
		return
	if guess == "":
		actor_role_guesses.erase(actor_id)
	else:
		actor_role_guesses[actor_id] = guess
	_check_confirmations()
	_save_progress()

func is_fact_confirmed(actor_id: String, field: String) -> bool:
	return confirmed_facts.has("%s:%s" % [actor_id, field])

func _check_confirmations() -> void:
	# Obra-Dinn-style lock-in: once the player accumulates >= 3 correct facts
	# anywhere in the casebook, every currently-correct fact gets confirmed and
	# locked. Confirmations are sticky — they never un-confirm.
	var correct: Array[String] = []
	for id in Cast.IDS:
		if actor_guesses.get(id, "") == Cast.name_for(id):
			correct.append("%s:name" % id)
		if actor_role_guesses.get(id, "") == Cast.role_for(id):
			correct.append("%s:role" % id)
	if correct.size() < CONFIRM_THRESHOLD:
		return
	for k in correct:
		if not confirmed_facts.has(k):
			confirmed_facts.append(k)

func conclude_case() -> void:
	concluded = true
	_save_progress()

func continue_game() -> void:
	enter_world()

func enter_world() -> void:
	_active_memory_id = ""
	get_tree().change_scene_to_file(WORLD_SCENE)

func enter_memory(memory: Memory) -> void:
	if memory == null:
		return
	_active_memory_id = memory.id
	if not discovered_memories.has(memory.id):
		discovered_memories.append(memory.id)
		_save_progress()
	get_tree().change_scene_to_file(INTRO_SCENE)

func active_memory() -> Memory:
	if _active_memory_id == "":
		return null
	for m in MemoryRegistry.all():
		if m.id == _active_memory_id:
			return m
	return null

func enter_active_memory_scene() -> void:
	var m := active_memory()
	if m == null or m.scene_path == "":
		enter_world()
		return
	get_tree().change_scene_to_file(m.scene_path)

func return_to_world() -> void:
	enter_world()

func return_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "discovered", discovered_memories)
	cfg.set_value("progress", "guesses", actor_guesses)
	cfg.set_value("progress", "role_guesses", actor_role_guesses)
	cfg.set_value("progress", "confirmed_facts", confirmed_facts)
	cfg.set_value("progress", "concluded", concluded)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Failed to save progress: %s" % err)

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var raw = cfg.get_value("progress", "discovered", [])
	discovered_memories.clear()
	for v in raw:
		discovered_memories.append(str(v))
	actor_guesses = cfg.get_value("progress", "guesses", {})
	actor_role_guesses = cfg.get_value("progress", "role_guesses", {})
	confirmed_facts.clear()
	for v in cfg.get_value("progress", "confirmed_facts", []):
		confirmed_facts.append(str(v))
	concluded = bool(cfg.get_value("progress", "concluded", false))
