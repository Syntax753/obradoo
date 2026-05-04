class_name Cast
extends RefCounted

# Canonical cast — actor ids (a1..a5) refer to the same person across every
# timeline. The diorama only ever shows the anonymous `label` ("1".."5"); real
# names appear here, in the casebook, and in the dialogue text the player hears.

const ROSTER := {
	"a1": {"label": "1", "name": "Lord Edmund Ashby",     "role": "Host of Ravensreach Manor",    "color": Color("b04848")},
	"a2": {"label": "2", "name": "Captain Reginald Pike", "role": "Soldier, old comrade-in-arms", "color": Color("4a6a8c")},
	"a3": {"label": "3", "name": "Miss Eliza Vance",      "role": "Scholar of antiquities",       "color": Color("5a7a4a")},
	"a4": {"label": "4", "name": "Sister Augusta",        "role": "Of the chapel at Ravensreach", "color": Color("3a3a3a")},
	"a5": {"label": "5", "name": "Tobias",                "role": "House servant",                "color": Color("8a6a3a")},
}

const IDS := ["a1", "a2", "a3", "a4", "a5"]

static func name_for(id: String) -> String:
	return ROSTER.get(id, {}).get("name", "?")

static func label_for(id: String) -> String:
	return ROSTER.get(id, {}).get("label", "?")

static func role_for(id: String) -> String:
	return ROSTER.get(id, {}).get("role", "")

static func color_for(id: String) -> Color:
	return ROSTER.get(id, {}).get("color", Color.WHITE)

static func all_names() -> Array[String]:
	var names: Array[String] = []
	for id in IDS:
		names.append(name_for(id))
	return names

static func all_roles() -> Array[String]:
	var roles: Array[String] = []
	for id in IDS:
		roles.append(role_for(id))
	return roles
