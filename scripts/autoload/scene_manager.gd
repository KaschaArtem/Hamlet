extends Node


func change_scene(scene: String) -> void:
	get_tree().change_scene_to_file(scene)
