extends RefCounted

const NO_TARGET := Vector2i(-9999, -9999)

func build() -> Dictionary:
	var actors := [
		{"id": "a1", "label": "1", "color": Color("b04848")},
		{"id": "a2", "label": "2", "color": Color("4a6a8c")},
		{"id": "a3", "label": "3", "color": Color("5a7a4a")},
		{"id": "a4", "label": "4", "color": Color("3a3a3a")},
		{"id": "a5", "label": "5", "color": Color("8a6a3a")},
	]
	var props := [
		{"id": "shelf_n", "label": "bookshelves",  "rect": Rect2i(1, 1, 8, 1)},
		{"id": "shelf_w", "label": "bookshelves",  "rect": Rect2i(1, 2, 1, 4)},
		{"id": "desk",    "label": "writing desk", "rect": Rect2i(3, 3, 3, 2)},
		{"id": "armchair","label": "armchair",     "rect": Rect2i(6, 4, 1, 1)},
		{"id": "door",    "label": "doorway",      "rect": Rect2i(9, 3, 1, 1)},
	]

	var turns: Array = []

	turns.append({
		"actor_states": {
			"a2": _state(Vector2i(3, 5), "N", "standing by the desk", "", "", NO_TARGET),
			"a4": _state(Vector2i(6, 5), "W", "seated in the armchair, hands folded", "", "", NO_TARGET),
		},
		"events": [{"kind": "narration", "text": "After dinner. Low gaslight. Two voices, low and clipped."}],
	})

	turns.append({
		"actor_states": {
			"a2": _state(Vector2i(3, 5), "E", "leaning over the desk", "", "lean", Vector2i(6, 5)),
			"a4": _state(Vector2i(6, 5), "W", "hands folded", "", "", NO_TARGET),
		},
		"events": [{"kind": "dialogue", "actor_id": "a2", "text": "You knew. You sat through the meal and did nothing."}],
	})

	turns.append({
		"actor_states": {
			"a2": _state(Vector2i(3, 5), "E", "waiting", "", "", NO_TARGET),
			"a4": _state(Vector2i(6, 5), "W", "looking up", "", "", Vector2i(3, 5)),
		},
		"events": [{"kind": "dialogue", "actor_id": "a4", "text": "I cannot break what was given in confidence. Not even tonight."}],
	})

	turns.append({
		"actor_states": {
			"a2": _state(Vector2i(3, 5), "E", "still", "", "", NO_TARGET),
			"a3": _state(Vector2i(9, 3), "W", "pausing in the doorway", "", "watch", Vector2i(4, 5)),
			"a4": _state(Vector2i(6, 5), "W", "still", "", "", NO_TARGET),
		},
		"events": [{"kind": "action", "actor_id": "a3", "text": "passes the doorway, pauses, listens"}],
	})

	turns.append({
		"actor_states": {
			"a2": _state(Vector2i(3, 5), "N", "turning toward the door", "", "", Vector2i(9, 3)),
			"a3": _state(Vector2i(9, 3), "E", "moving on", "", "", NO_TARGET),
			"a4": _state(Vector2i(6, 5), "W", "still", "", "", NO_TARGET),
		},
		"events": [{"kind": "action", "actor_id": "a2", "text": "glances toward the door; the hallway is empty"}],
	})

	turns.append({
		"actor_states": {
			"a2": _state(Vector2i(3, 5), "E", "lowering his voice", "", "", Vector2i(6, 5)),
			"a4": _state(Vector2i(6, 5), "W", "head bowed", "", "", NO_TARGET),
		},
		"events": [{"kind": "dialogue", "actor_id": "a2", "text": "Then we are both damned, Sister. Together."}],
	})

	return {
		"title": "The Library",
		"grid_width": 11,
		"grid_height": 7,
		"actors": actors,
		"props": props,
		"turns": turns,
	}

func _state(pos: Vector2i, facing: String, action: String, holding: String, gesture: String, target: Vector2i) -> Dictionary:
	return {"pos": pos, "facing": facing, "action": action, "holding": holding, "gesture": gesture, "gesture_target": target}
