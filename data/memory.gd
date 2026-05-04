class_name Memory
extends Resource

@export var id: String = ""
@export var order: int = 0
@export var title: String = ""
@export var subtitle: String = ""
@export_multiline var intro: String = ""
@export_file("*.tscn") var scene_path: String = ""
@export var timeline_id: String = ""
