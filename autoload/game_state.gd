extends Node

const SAVE_PATH := "user://obradoo_save.cfg"

var current_memory_index: int = -1
var max_unlocked_index: int = -1

func _ready() -> void:
	_load_progress()

func has_save() -> bool:
	return max_unlocked_index >= 0

func start_new_game() -> void:
	current_memory_index = 0
	if max_unlocked_index < 0:
		max_unlocked_index = 0
		_save_progress()
	enter_current_memory()

func continue_game() -> void:
	if not has_save():
		start_new_game()
		return
	current_memory_index = max_unlocked_index
	enter_current_memory()

func enter_current_memory() -> void:
	if current_memory_index < 0 or current_memory_index >= MemoryRegistry.count():
		get_tree().change_scene_to_file("res://scenes/end_screen/end_screen.tscn")
		return
	get_tree().change_scene_to_file("res://scenes/intro_card/intro_card.tscn")

func current_memory() -> Memory:
	return MemoryRegistry.get_by_index(current_memory_index)

func enter_current_memory_scene() -> void:
	var m := current_memory()
	if m == null or m.scene_path == "":
		conclude_current_memory()
		return
	get_tree().change_scene_to_file(m.scene_path)

func conclude_current_memory() -> void:
	current_memory_index += 1
	if current_memory_index > max_unlocked_index:
		max_unlocked_index = current_memory_index
		_save_progress()
	enter_current_memory()

func return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "max_unlocked_index", max_unlocked_index)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Failed to save progress: %s" % err)

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		max_unlocked_index = cfg.get_value("progress", "max_unlocked_index", -1)
