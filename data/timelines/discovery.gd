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
		{"id": "stairs",     "label": "stairs up",     "rect": Rect2i(1, 1, 2, 4)},
		{"id": "table_edge", "label": "dining doorway","rect": Rect2i(11, 4, 1, 2)},
		{"id": "library_dr", "label": "library door",  "rect": Rect2i(13, 4, 1, 1)},
	]

	var turns: Array = []

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(10, 5), "W", "staggering out of the dining room", "", "stagger", NO_TARGET),
			"a5": _state(Vector2i(11, 5), "W", "behind him, half-turning", "", "", Vector2i(10, 5)),
		},
		"events": [{"kind": "narration", "text": "A few minutes before midnight. The dining room behind him."}],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(8, 5), "W", "clutching his chest", "", "stagger", NO_TARGET),
			"a5": _state(Vector2i(10, 5), "W", "hurrying after", "", "", Vector2i(8, 5)),
		},
		"events": [{"kind": "action", "actor_id": "a1", "text": "presses a hand to his chest, eyes unfocused"}],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 5), "W", "fallen", "", "kneel", NO_TARGET),
			"a3": _state(Vector2i(13, 4), "W", "appearing at the library door", "", "watch", Vector2i(6, 5)),
			"a5": _state(Vector2i(8, 5), "W", "running", "", "", Vector2i(6, 5)),
		},
		"events": [
			{"kind": "action", "actor_id": "a1", "text": "collapses onto the floorboards"},
			{"kind": "action", "actor_id": "a3", "text": "stops in the doorway, hand to her mouth"},
		],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 5), "W", "fallen", "", "kneel", NO_TARGET),
			"a2": _state(Vector2i(11, 5), "W", "stepping out of the dining room", "", "watch", Vector2i(6, 5)),
			"a3": _state(Vector2i(13, 4), "W", "frozen", "", "", NO_TARGET),
			"a4": _state(Vector2i(2, 1), "S", "appearing at the top of the stairs", "", "watch", Vector2i(6, 5)),
			"a5": _state(Vector2i(7, 5), "W", "kneeling beside him", "", "kneel", Vector2i(6, 5)),
		},
		"events": [{"kind": "action", "actor_id": "a5", "text": "drops to one knee at the host's side"}],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 5), "W", "still", "", "kneel", NO_TARGET),
			"a2": _state(Vector2i(10, 5), "W", "stops, watching", "", "watch", Vector2i(6, 5)),
			"a3": _state(Vector2i(13, 4), "W", "frozen", "", "", NO_TARGET),
			"a4": _state(Vector2i(2, 1), "S", "head bowed", "", "", NO_TARGET),
			"a5": _state(Vector2i(7, 5), "W", "checking for breath", "", "kneel", Vector2i(6, 5)),
		},
		"events": [{"kind": "dialogue", "actor_id": "a5", "text": "He's gone."}],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 5), "W", "still", "", "kneel", NO_TARGET),
			"a2": _state(Vector2i(11, 5), "E", "turning back", "", "", Vector2i(13, 5)),
			"a3": _state(Vector2i(12, 4), "W", "stepping closer, slowly", "", "", NO_TARGET),
			"a4": _state(Vector2i(2, 1), "S", "still", "", "", NO_TARGET),
			"a5": _state(Vector2i(7, 5), "W", "rising", "", "", NO_TARGET),
		},
		"events": [{"kind": "action", "actor_id": "a2", "text": "turns and walks calmly back into the dining room"}],
	})

	turns.append({
		"actor_states": {
			"a1": _state(Vector2i(6, 5), "W", "still", "", "kneel", NO_TARGET),
			"a3": _state(Vector2i(11, 5), "W", "kneeling at his other side", "", "kneel", NO_TARGET),
			"a4": _state(Vector2i(2, 1), "S", "still", "", "", NO_TARGET),
			"a5": _state(Vector2i(7, 5), "N", "looking toward the stairs", "", "watch", Vector2i(2, 1)),
		},
		"events": [{"kind": "narration", "text": "The storm finds the windows. Outside, the rain is louder."}],
	})

	return {
		"title": "Discovery",
		"grid_width": 14,
		"grid_height": 7,
		"actors": actors,
		"props": props,
		"turns": turns,
	}

func _state(pos: Vector2i, facing: String, action: String, holding: String, gesture: String, target: Vector2i) -> Dictionary:
	return {"pos": pos, "facing": facing, "action": action, "holding": holding, "gesture": gesture, "gesture_target": target}
