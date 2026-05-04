extends RefCounted

# Builds the "Toast" timeline data.
#
# Conventions (see project memory):
# - actors[].label is what the player sees (anonymous tag)
# - actor names ARE NOT put on actors directly; they only appear inside
#   dialogue lines spoken by other characters
# - positions are grid cells (Vector2i)
# - events have kind: "narration" | "dialogue" | "action"

func build() -> Dictionary:
	var actors := [
		{"id": "a1", "label": "1", "color": Color("b04848")}, # host
		{"id": "a2", "label": "2", "color": Color("4a6a8c")}, # ex-military
		{"id": "a3", "label": "3", "color": Color("5a7a4a")}, # scholar
		{"id": "a4", "label": "4", "color": Color("3a3a3a")}, # clergy
		{"id": "a5", "label": "5", "color": Color("8a6a3a")}, # manservant
	]
	var props := [
		{"id": "table", "label": "dining table", "rect": Rect2i(4, 4, 6, 2)},
		{"id": "sideboard", "label": "sideboard", "rect": Rect2i(1, 3, 2, 3)},
	]

	var seated := {
		"a1": {"pos": Vector2i(10, 4), "facing": "W", "action": "seated at the head", "holding": ""},
		"a2": {"pos": Vector2i(5, 3),  "facing": "S", "action": "seated", "holding": ""},
		"a3": {"pos": Vector2i(8, 3),  "facing": "S", "action": "seated", "holding": ""},
		"a4": {"pos": Vector2i(5, 6),  "facing": "N", "action": "seated, hands folded", "holding": ""},
		"a5": {"pos": Vector2i(2, 4),  "facing": "E", "action": "standing at the sideboard", "holding": ""},
	}

	var turns: Array = []

	turns.append({
		"actor_states": _clone(seated),
		"events": [
			{"kind": "narration", "text": "A crystal chandelier. Five places set. The storm has not yet broken."},
		],
	})

	turns.append({
		"actor_states": _clone(seated),
		"events": [
			{"kind": "dialogue", "actor_id": "a1", "text": "Captain, I trust the storm did not delay you."},
		],
	})

	var s3 := _clone(seated)
	s3["a5"] = {"pos": Vector2i(3, 4), "facing": "E", "action": "carrying a decanter to the table", "holding": "Decanter A"}
	turns.append({
		"actor_states": s3,
		"events": [
			{"kind": "dialogue", "actor_id": "a2", "text": "Hardly, Ashby. A debt this old won't keep me from the road."},
			{"kind": "action",   "actor_id": "a5", "text": "lifts a decanter from the sideboard"},
		],
	})

	var s4 := _clone(seated)
	s4["a5"] = {"pos": Vector2i(4, 4), "facing": "E", "action": "pouring", "holding": "Decanter A"}
	turns.append({
		"actor_states": s4,
		"events": [
			{"kind": "dialogue", "actor_id": "a1", "text": "Sister, I'm honoured by your visit. The chapel rarely loans you out."},
			{"kind": "action",   "actor_id": "a5", "text": "fills glasses 1, 2 and 3 from Decanter A"},
		],
	})

	turns.append({
		"actor_states": _clone(s4),
		"events": [
			{"kind": "dialogue", "actor_id": "a4", "text": "None for me, Lord Ashby. My orders, you understand."},
		],
	})

	var s6 := _clone(seated)
	s6["a5"] = {"pos": Vector2i(2, 4), "facing": "W", "action": "exchanging decanters at the sideboard", "holding": "Decanter B"}
	turns.append({
		"actor_states": s6,
		"events": [
			{"kind": "dialogue", "actor_id": "a3", "text": "Your library catalogue mentions a 1606 atlas. Might I impose upon you later?"},
			{"kind": "action",   "actor_id": "a5", "text": "sets down Decanter A and lifts Decanter B"},
		],
	})

	var s7 := _clone(seated)
	s7["a5"] = {"pos": Vector2i(3, 4), "facing": "E", "action": "approaching the table", "holding": "Decanter B"}
	turns.append({
		"actor_states": s7,
		"events": [
			{"kind": "dialogue", "actor_id": "a1", "text": "Of course, Miss Vance. Tobias will show you up after."},
		],
	})

	var s8 := _clone(seated)
	s8["a5"] = {"pos": Vector2i(5, 4), "facing": "N", "action": "pouring", "holding": "Decanter B"}
	s8["a2"] = {"pos": Vector2i(5, 3), "facing": "S", "action": "leaning across the table", "holding": ""}
	turns.append({
		"actor_states": s8,
		"events": [
			{"kind": "action", "actor_id": "a5", "text": "fills glass 2 from Decanter B and tops up glass 1"},
			{"kind": "action", "actor_id": "a2", "text": "leans forward; a hand passes briefly over glass 1"},
		],
	})

	var s9 := _clone(seated)
	s9["a1"] = {"pos": Vector2i(10, 4), "facing": "W", "action": "raising glass", "holding": "wine glass"}
	s9["a2"] = {"pos": Vector2i(5, 3),  "facing": "S", "action": "raising glass", "holding": "wine glass"}
	s9["a3"] = {"pos": Vector2i(8, 3),  "facing": "S", "action": "raising glass", "holding": "wine glass"}
	s9["a4"] = {"pos": Vector2i(5, 6),  "facing": "N", "action": "seated, hands folded", "holding": ""}
	turns.append({
		"actor_states": s9,
		"events": [
			{"kind": "dialogue", "actor_id": "a1", "text": "To old debts — settled tonight."},
		],
	})

	var s10 := _clone(s9)
	s10["a1"] = {"pos": Vector2i(10, 4), "facing": "W", "action": "setting glass down, swaying", "holding": ""}
	s10["a2"] = {"pos": Vector2i(5, 3),  "facing": "S", "action": "watching", "holding": ""}
	s10["a3"] = {"pos": Vector2i(8, 3),  "facing": "S", "action": "drinking", "holding": "wine glass"}
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

func _clone(state: Dictionary) -> Dictionary:
	var out := {}
	for k in state.keys():
		var v: Dictionary = state[k]
		out[k] = v.duplicate(true)
	return out
