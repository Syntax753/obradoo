extends SceneTree

func _init() -> void:
	var fails: Array[String] = []
	print("=== Obradoo validation ===")

	if load("res://data/memory.gd") == null:
		fails.append("Memory script failed to load")

	var memories: Array = []
	var dir := DirAccess.open("res://data/memories")
	if dir == null:
		fails.append("Cannot open data/memories dir")
	else:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.ends_with(".tres"):
				var res = load("res://data/memories/" + fname)
				if res == null:
					fails.append("Failed to load %s" % fname)
				else:
					memories.append(res)
					print("  memory: %s (order %d) -> scene %s | timeline %s | pos (%d,%d)" % [
						res.id, res.order, res.scene_path, res.timeline_id, res.world_position.x, res.world_position.y
					])
			fname = dir.get_next()

	for m in memories:
		if m.timeline_id == "":
			continue
		var path := "res://data/timelines/%s.gd" % m.timeline_id
		var script = load(path)
		if script == null:
			fails.append("Missing timeline script %s" % path)
			continue
		var data: Dictionary = script.new().build()
		if not data.has("turns") or (data.turns as Array).size() == 0:
			fails.append("Timeline %s has no turns" % m.timeline_id)
			continue
		# Check every actor_state has the expected keys
		for i in (data.turns as Array).size():
			var turn: Dictionary = data.turns[i]
			for actor_id in turn.actor_states.keys():
				var st: Dictionary = turn.actor_states[actor_id]
				for key in ["pos", "facing", "action", "holding", "gesture", "gesture_target"]:
					if not st.has(key):
						fails.append("%s turn %d actor %s missing key '%s'" % [m.timeline_id, i, actor_id, key])
		print("  timeline %s: %d turns, %dx%d, %d actors" % [
			m.timeline_id, (data.turns as Array).size(), data.grid_width, data.grid_height, (data.actors as Array).size()
		])

	var scenes := [
		"res://scenes/main_menu/main_menu.tscn",
		"res://scenes/intro_card/intro_card.tscn",
		"res://scenes/timeline_memory/timeline_memory.tscn",
		"res://scenes/end_screen/end_screen.tscn",
		"res://scenes/world/manor_3d.tscn",
		"res://scenes/casebook/casebook.tscn",
	]
	for path in scenes:
		var packed := load(path) as PackedScene
		if packed == null:
			fails.append("Cannot load scene %s" % path)
		else:
			# Try instantiating to catch script-attach errors / missing nodes
			var inst := packed.instantiate()
			if inst == null:
				fails.append("Cannot instantiate %s" % path)
			else:
				print("  scene OK: %s" % path)
				inst.queue_free()

	if fails.is_empty():
		print("\n=== PASS ===")
		quit(0)
	else:
		print("\n=== FAIL (%d) ===" % fails.size())
		for f in fails:
			print("  ! " + f)
		quit(1)
