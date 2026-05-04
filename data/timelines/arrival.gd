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
		{"id": "door",      "label": "front door",   "rect": Rect2i(1, 3, 1, 1)},
		{"id": "coat_rack", "label": "coat rack",    "rect": Rect2i(3, 1, 1, 1)},
		{"id": "stairs",    "label": "stairs up",    "rect": Rect2i(8, 1, 2, 2)},
		{"id": "to_dining", "label": "to dining",    "rect": Rect2i(11, 3, 1, 1)},
	]

	var turns: Array = []

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 3), "W", "standing in the foyer", "", "", NO_TARGET),
			"a5": _state(Vector2i(3, 2), "S", "waiting at the coat rack", "", "", NO_TARGET),
		},
		"events": [{"kind": "narration", "text": "Rain begins. Wax on the candlesticks. The first knock at the door."}],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 3), "W", "greeting his guest", "", "", NO_TARGET),
			"a2": _state(Vector2i(2, 3), "E", "stepping inside, shaking off rain", "coat", "", NO_TARGET),
			"a5": _state(Vector2i(3, 3), "W", "holding the door", "", "", NO_TARGET),
		},
		"events": [{"kind": "dialogue", "actor_id": "a1", "text": "Captain Pike. On a night like this — you've earned your conversation."}],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 3), "W", "exchanging a handshake", "", "", NO_TARGET),
			"a2": _state(Vector2i(4, 3), "E", "removing his coat", "", "", NO_TARGET),
			"a5": _state(Vector2i(3, 2), "E", "taking a coat to the rack", "coat", "", NO_TARGET),
		},
		"events": [
			{"kind": "dialogue", "actor_id": "a2", "text": "Lord Ashby. The road was filthy but the welcome makes up for it."},
			{"kind": "action",   "actor_id": "a5", "text": "carries the first coat to the rack"},
		],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 3), "W", "turning to greet again", "", "", Vector2i(2, 3)),
			"a2": _state(Vector2i(7, 3), "S", "moving aside", "", "", NO_TARGET),
			"a3": _state(Vector2i(2, 3), "E", "stepping inside", "coat", "", NO_TARGET),
			"a5": _state(Vector2i(3, 1), "S", "hanging a coat", "", "", NO_TARGET),
		},
		"events": [{"kind": "dialogue", "actor_id": "a1", "text": "Miss Vance. The carriage was prompt, I trust?"}],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 3), "W", "smiling politely", "", "", NO_TARGET),
			"a2": _state(Vector2i(7, 3), "S", "watching the door", "", "watch", Vector2i(2, 3)),
			"a3": _state(Vector2i(4, 3), "E", "handing over her coat", "", "", NO_TARGET),
			"a5": _state(Vector2i(3, 2), "W", "taking another coat", "coat", "", NO_TARGET),
		},
		"events": [{"kind": "dialogue", "actor_id": "a3", "text": "Quite. Your driver knows every pothole by name, I think."}],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 3), "W", "extending a hand", "", "", Vector2i(2, 3)),
			"a2": _state(Vector2i(7, 3), "S", "standing aside", "", "", NO_TARGET),
			"a3": _state(Vector2i(5, 3), "S", "moving toward the dining room", "", "", NO_TARGET),
			"a4": _state(Vector2i(2, 3), "E", "stepping inside, hood raised", "coat", "", NO_TARGET),
			"a5": _state(Vector2i(3, 1), "S", "hanging coats", "", "", NO_TARGET),
		},
		"events": [
			{"kind": "dialogue", "actor_id": "a1", "text": "Sister Augusta. May the storm not delay your return."},
			{"kind": "dialogue", "actor_id": "a4", "text": "Lord Ashby."},
		],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(8, 3), "E", "leading the way", "", "", Vector2i(11, 3)),
			"a2": _state(Vector2i(7, 3), "E", "following", "", "", NO_TARGET),
			"a3": _state(Vector2i(7, 3), "E", "following", "", "", NO_TARGET),
			"a4": _state(Vector2i(4, 3), "E", "moving in", "", "", NO_TARGET),
			"a5": _state(Vector2i(3, 2), "S", "watching them go", "", "watch", Vector2i(8, 3)),
		},
		"events": [
			{"kind": "narration", "text": "He gestures east, toward the dining room. They follow."},
		],
	})

	return {
		"title": "The Arrival",
		"grid_width": 13,
		"grid_height": 7,
		"actors": actors,
		"props": props,
		"turns": turns,
	}

func _state(pos: Vector2i, facing: String, action: String, holding: String, gesture: String, target: Vector2i) -> Dictionary:
	return {"pos": pos, "facing": facing, "action": action, "holding": holding, "gesture": gesture, "gesture_target": target}
