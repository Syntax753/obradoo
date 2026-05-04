extends Node

# Scans res://data/memories for Memory resources at startup and exposes
# them sorted by `order`. Folder scanning works in the editor and from
# `godot --path .` runs; for exported builds, replace with an index .tres
# (Godot cannot enumerate res:// directories in exports).

const MEMORIES_DIR := "res://data/memories"

var _memories: Array[Memory] = []

func _ready() -> void:
	_scan()

func _scan() -> void:
	_memories.clear()
	var dir := DirAccess.open(MEMORIES_DIR)
	if dir == null:
		push_error("Memory directory not found: %s" % MEMORIES_DIR)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and (fname.ends_with(".tres") or fname.ends_with(".res")):
			var path := MEMORIES_DIR + "/" + fname
			var res := load(path)
			if res is Memory:
				_memories.append(res)
			else:
				push_warning("Non-Memory resource in memories dir: %s" % path)
		fname = dir.get_next()
	dir.list_dir_end()
	_memories.sort_custom(func(a, b): return a.order < b.order)

func count() -> int:
	return _memories.size()

func get_by_index(idx: int) -> Memory:
	if idx < 0 or idx >= _memories.size():
		return null
	return _memories[idx]

func all() -> Array[Memory]:
	return _memories
