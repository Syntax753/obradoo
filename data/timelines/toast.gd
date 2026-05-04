extends RefCounted

# Convention: actor labels are anonymous tags (1-5). Names appear ONLY in
# dialogue text. Held items are item IDs (see HELD_LABELS in grid_view.gd).
# Gestures: "" | "pour" | "drink" | "raise" | "lean" | "stagger" | "kneel" | "watch"

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
		{"id": "table", "label": "dining table", "rect": Rect2i(4, 4, 6, 2)},
		{"id": "sideboard", "label": "sideboard", "rect": Rect2i(1, 3, 2, 3)},
	]

	var seated := {
		"a1": _state(Vector2i(10, 4), "W", "seated at the head", "", "", NO_TARGET),
		"a2": _state(Vector2i(5, 3),  "S", "seated", "", "", NO_TARGET),
		"a3": _state(Vector2i(8, 3),  "S", "seated", "", "", NO_TARGET),
		"a4": _state(Vector2i(5, 6),  "N", "seated, hands folded", "", "", NO_TARGET),
		"a5": _state(Vector2i(2, 4),  "E", "standing at the sideboard", "", "", NO_TARGET),
	}

	var turns: Array = []

	turns.append({
		"actor_states": _clone(seated),
		"events": [{"kind": "narration", "text": "A crystal chandelier. Five places set. The storm has not yet broken."}],
	})

	turns.append({
		"actor_states": _clone(seated),
		"events": [{"kind": "dialogue", "actor_id": "a1", "text": "Captain, I trust the storm did not delay you."}],
	})

	var s3 := _clone(seated)
	s3["a5"] = _state(Vector2i(3, 4), "E", "carrying a decanter to the table", "decanter_a", "", NO_TARGET)
	turns.append({
		"actor_states": s3,
		"events": [
			{"kind": "dialogue", "actor_id": "a2", "text": "Hardly, Ashby. A debt this old won't keep me from the road."},
			{"kind": "action",   "actor_id": "a5", "text": "lifts a decanter from the sideboard"},
		],
	})

	var s4 := _clone(seated)
	s4["a5"] = _state(Vector2i(4, 4), "E", "pouring", "decanter_a", "pour", Vector2i(5, 4))
	turns.append({
		"actor_states": s4,
		"events": [
			{"kind": "dialogue", "actor_id": "a1", "text": "Sister, I'm honoured by your visit. The chapel rarely loans you out."},
			{"kind": "action",   "actor_id": "a5", "text": "fills glasses 1, 2 and 3 from Decanter A"},
		],
	})

	turns.append({
		"actor_states": _clone(s4),
		"events": [{"kind": "dialogue", "actor_id": "a4", "text": "None for me, Lord Ashby. My orders, you understand."}],
	})

	var s6 := _clone(seated)
	s6["a5"] = _state(Vector2i(2, 4), "W", "exchanging decanters at the sideboard", "decanter_b", "", NO_TARGET)
	turns.append({
		"actor_states": s6,
		"events": [
			{"kind": "dialogue", "actor_id": "a3", "text": "Your library catalogue mentions a 1606 atlas. Might I impose upon you later?"},
			{"kind": "action",   "actor_id": "a5", "text": "sets down Decanter A and lifts Decanter B"},
		],
	})

	var s7 := _clone(seated)
	s7["a5"] = _state(Vector2i(3, 4), "E", "approaching the table", "decanter_b", "", NO_TARGET)
	turns.append({
		"actor_states": s7,
		"events": [{"kind": "dialogue", "actor_id": "a1", "text": "Of course, Miss Vance. Tobias will show you up after."}],
	})

	var s8 := _clone(seated)
	s8["a5"] = _state(Vector2i(5, 4), "N", "pouring", "decanter_b", "pour", Vector2i(5, 3))
	s8["a2"] = _state(Vector2i(5, 3), "S", "leaning across the table", "", "lean", Vector2i(10, 4))
	turns.append({
		"actor_states": s8,
		"events": [
			{"kind": "action", "actor_id": "a5", "text": "fills glass 2 from Decanter B and tops up glass 1"},
			{"kind": "action", "actor_id": "a2", "text": "leans forward; a hand passes briefly over glass 1"},
		],
	})

	var s9 := _clone(seated)
	s9["a1"] = _state(Vector2i(10, 4), "W", "raising glass", "wine_glass", "raise", NO_TARGET)
	s9["a2"] = _state(Vector2i(5, 3),  "S", "raising glass", "wine_glass", "raise", NO_TARGET)
	s9["a3"] = _state(Vector2i(8, 3),  "S", "raising glass", "wine_glass", "raise", NO_TARGET)
	s9["a4"] = _state(Vector2i(5, 6),  "N", "seated, hands folded", "", "", NO_TARGET)
	turns.append({
		"actor_states": s9,
		"events": [{"kind": "dialogue", "actor_id": "a1", "text": "To old debts — settled tonight."}],
	})

	var s10 := _clone(s9)
	s10["a1"] = _state(Vector2i(10, 4), "W", "setting glass down, swaying", "", "stagger", NO_TARGET)
	s10["a2"] = _state(Vector2i(5, 3),  "S", "watching", "", "watch", Vector2i(10, 4))
	s10["a3"] = _state(Vector2i(8, 3),  "S", "drinking", "wine_glass", "drink", NO_TARGET)
	turns.append({
		"actor_states": s10,
		"events": [
			{"kind": "action",   "actor_id": "a1", "text": "sips, then sets the glass down with a tremor"},
			{"kind": "dialogue", "actor_id": "a1", "text": "...a moment."},
		],
	})

	return {
		"title": "The Toast",
		"grid_width": 14,
		"grid_height": 9,
		"actors": actors,
		"props": props,
		"turns": turns,
	}

func _state(pos: Vector2i, facing: String, action: String, holding: String, gesture: String, target: Vector2i) -> Dictionary:
	return {"pos": pos, "facing": facing, "action": action, "holding": holding, "gesture": gesture, "gesture_target": target}

func _clone(state: Dictionary) -> Dictionary:
	var out := {}
	for k in state.keys():
		out[k] = (state[k] as Dictionary).duplicate(true)
	return out
