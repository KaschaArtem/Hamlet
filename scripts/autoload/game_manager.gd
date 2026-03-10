extends Node


var is_build_allowed: bool

var building_action = -999


func _ready():
	get_tree().scene_changed.connect(_on_scene_changed)


func _on_scene_changed():
	building_action = -999
