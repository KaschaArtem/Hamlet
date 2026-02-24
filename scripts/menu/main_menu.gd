extends Node


@export var new_game_button: Button
@export var continue_button: Button
@export var settings_button: Button
@export var exit_game_button: Button


func _ready() -> void:
	pass
	

func _on_new_game_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/active_scenes/game.tscn")


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()
